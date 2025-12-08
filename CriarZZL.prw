#Include "Protheus.ch"

User Function ZZLCreate()

	RpcSetEnv ("01"       , "01"      ,           ,            , 'EST'     ,  'RPC'      ,    )


	
      // Substitua ZZTBL pelo nome da sua tabela
    DbSelectArea("ZZC")

    // Apenas para garantir algum uso
    DbGoTop()

    MsgInfo("Tabela ZZL criada / validada com sucesso!")
Return

Return
