#Include "TOTVS.ch"
#Include "FWMVCDEF.ch"

User Function ImportaTitulos()

	Local cAliasQry     := ""
	Local nTotalReg     := 0
	Local nSucesso      := 0
	Local nErros        := 0


	cAliasQry := BuscaTitulos()

	If (cAliasQry)->(EOF())
		MsgAlert("Nenhum título encontrado para importação!", "Aviso")
		(cAliasQry)->(DbCloseArea())
		Return
	EndIf

	(cAliasQry)->(DbGoTop())
	While !(cAliasQry)->(EOF())
		nTotalReg++
		(cAliasQry)->(DbSkip())
	End

	(cAliasQry)->(DbGoTop())


	While !(cAliasQry)->(EOF())

		If ProcessaTitulo(cAliasQry)
			nSucesso++
		Else
			nErros++
		EndIf


		(cAliasQry)->(DbSkip())

		End

	(cAliasQry)->(DbCloseArea())


	MsgInfo("Importação concluída!" + CRLF + ;
		"Total processados: " + cValToChar(nTotalReg) + CRLF + ;
		"Sucessos: " + cValToChar(nSucesso) + CRLF + ;
		"Erros: " + cValToChar(nErros), "Resultado da Importação")

Return


Static Function BuscaTitulos()

	Local cQuery    := ""
	Local cAlias    := GetNextAlias()
	RpcSetEnv ("01"       , "01"      ,           ,            , 'EST'     ,  'RPC'      ,    )

	cQuery := "EXEC sp_ListarTitulosSemFlag "


	DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

Return cAlias



Static Function ProcessaTitulo(cAliasQry)

	Local aVetor        := {}
	Local cNumTit       := ""
	Local cCliente      := ""
	Local cLoja         := ""
	Local nValor        := 0
	Local dVencto       := CToD("")
	Local cPedido       := ""
	Local lMsErroAuto   := .F.
	Local cErroMsg      := ""
	Local lRet          := .T.
	Local nId           := 0

	nId         := (cAliasQry)->ID
	cCliente    := AllTrim((cAliasQry)->CLIENTE)
	nValor      := (cAliasQry)->VALOR

	Local cDataVenc := AllTrim((cAliasQry)->VENCIMENTO)
	If "/" $ cDataVenc
		dVencto := CToD(StrTran(cDataVenc, "/", ""))
	ElseIf "-" $ cDataVenc .And. Len(cDataVenc) > 8
		dVencto := CToD(StrTran(cDataVenc, "-", ""))
	ElseIf Len(cDataVenc) == 8
		dVencto := SToD(cDataVenc)
	Else

		dVencto := dDataBase
	EndIf

	cPedido     := AllTrim((cAliasQry)->PEDIDO)


	If At("-", cCliente) > 0
		cLoja    := SubStr(cCliente, At("-", cCliente) + 1)
		cCliente := SubStr(cCliente, 1, At("-", cCliente) - 1)
	Else
		cLoja := "01"
	EndIf


	cNumTit := GetSxeNum("SE1", "E1_NUM")


	ConfirmSX8()


	aVetor := {}
	aAdd(aVetor, {"E1_PREFIXO",  "INT",      Nil})
	aAdd(aVetor, {"E1_NUM",      cNumTit,    Nil})
	aAdd(aVetor, {"E1_PARCELA",  "",         Nil})
	aAdd(aVetor, {"E1_TIPO",     "NF",       Nil})
	aAdd(aVetor, {"E1_NATUREZ",  "10101",    Nil})
	aAdd(aVetor, {"E1_CLIENTE",  cCliente,   Nil})
	aAdd(aVetor, {"E1_LOJA",     cLoja,      Nil})
	aAdd(aVetor, {"E1_EMISSAO",  dDataBase,  Nil})
	aAdd(aVetor, {"E1_VENCTO",   dVencto,    Nil})
	aAdd(aVetor, {"E1_VENCREA",  dVencto,    Nil})
	aAdd(aVetor, {"E1_VALOR",    nValor,     Nil})
	aAdd(aVetor, {"E1_HIST",     "Titulo importado - Pedido: " + cPedido, Nil})


	MSExecAuto({|x,y| FINA040(x,y)}, aVetor, 3)

	If lMsErroAuto
		lRet := .F.
		cErroMsg := "Erro na inclusão do título " + cNumTit

		If __lSX8
			RollBackSX8() 
		EndIf


		AtualizaFlag(nId, 2)

		GravaLog(cCliente, cNumTit, "ERRO", cErroMsg)

	Else

		AtualizaFlag(nId, 1)

		GravaLog(cCliente, cNumTit, "OK", "Título incluído com sucesso")

	EndIf

Return lRet


Static Function AtualizaFlag(nId, nFlag)

	Local cUpdate := ""


	cUpdate := " UPDATE titulos_receber "
	cUpdate += " SET FLAG = " + cValToChar(nFlag)
	cUpdate += " WHERE ID = " + cValToChar(nId)

	If TCSqlExec(cUpdate) < 0
		MsgAlert("Erro ao atualizar FLAG - ID: " + cValToChar(nId))
		MsgAlert("Erro: " + TCSQLError())
	EndIf

Return

Static Function GravaLog(cCliente, cTitulo, cStatus, cMensagem)

	DbSelectArea("ZZC")
	ZZC->(DbSetOrder(1))


	If RecLock("ZZC", .T.)

		ZZC->ZZC_FILIAL  := xFilial("ZZC")
		ZZC->ZZC_CLIENT := cCliente
		ZZC->ZZC_TITULO  := cTitulo 
		ZZC->ZZC_DATA    := dDataBase
		ZZC->ZZC_STATUS  := cStatus
		ZZC->ZZC_MSG     := Left(cMensagem, TamSX3("ZZC_MSG")[1])
		MsUnlock()

	Else
		ConOut("erro ao gravar log na tabela ZZC")
	EndIf

Return
