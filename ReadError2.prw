#Include 'Protheus.ch'
#Include 'Totvs.ch'

/* Constantes */
#DEFINE FASE_LOG_FONTE 1
#DEFINE FASE_PILHA 2
#DEFINE FASE_FRAME 3

//-------------------------------------------------------------------
/*/{Protheus.doc} xReadError
Fun��o de inclus�o autom�tica de erros
@author  Jo�o Pedro
@since   08/01/2018
@version 1.0
/*/
//-------------------------------------------------------------------
User Function xReadError()

    Local aParamBox := {}

    Private aRet := {} //Variavel necess�ria para n�o dar error.log
    Private nNovo := 0
    Private lCustomizado := .F.
    Private lErro := .F.

    /* Montagem da tela de par�metro para sele��o do arquivo de erro */
    AADD(aParamBox,{6,"Arquivo ?",Space(70),"","","",70,.T.,"Todos os arquivo (*.*)|*.*"})

    If ParamBox(aParamBox,"Selecione o arquivo",aRet)
        cFile := aRet[1]
        If ".log" $ cFile .OR. ".txt" $ cFile
            Processa({||ReadArq(cFile)},"Aguarde...","Lendo arquivo de texto...",.F.) //Fun��o que ir� ler linha por linha do error.log
        Else
            MsgInfo("N�o � poss�vel ler arquivos com esta extens�o","Aten��o")
            Return .F.
        Endif
    Endif

    If lCustomizado
        MsgInfo("H� uma customiza��o na pilha de chamada deste erro","Aten��o")
    Endif

    If !lErro
        If MsgYesNo("Deseja excluir o arquivo de erro ?","Aten��o")
            FErase(cFile)
        Endif
    Endif

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} ReadArq
Fun��o respons�vel por ler o arquivo txt
@author  Jo�o Pedro
@since   12/12/2018
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function ReadArq(cFile)

    Local oFile //Objeto que conter� o FWFileReader
    Local cLinha //Guarda a linha atual do arquivo
    Local nVez //Variavel necess�ria para que n�o assimile varias linhas ao vetor do erro
    Local lChamou := .F.

    aErros := {}

    ProcRegua(1000) //Regua de progresso

    oFile := FWFileReader():New(cFile) //Instancia a classe FWFileReader
    If oFile:Open() //Abre o arquivo para leitura
        Do While oFile:hasLine() //Enquanto houver linha no arquivo
            IncProc() //Incrementa regua de progresso
            cLinha := oFile:GetLine() //Pega a linha atual
            If "��" $ cLinha
                MsgInfo("Ocorreu algum problema com este error.log, Inclua o mesmo manualmente","Aten��o")
                lErro := .T.
                Return .F.
            Endif
            nVez := 0
            If "THREAD ERROR" $ cLinha //Se for encontrado "THREAD ERROR" adiciona ao vetor aErros
                AADD(aErros, cLinha)
                nVez := 1
            Endif
            If " on " $ cLinha .AND. !" on (" $ cLinha //Quando for encontrado " on " na linha, quer dizer que chegamos no final do erro puro
                If aScan(aErros, "THREAD ERROR") > 0 .OR. aScan(aErros, "﻿THREAD ERROR") > 0 .AND. nVez == 0
                    AADD(aErros, cLinha)
                    nVez := 1
                Endif
                If !lChamou
                    Processa({||CutLines(1)},"Aguarde...","Separando dados do arquivo...") //Chama a fun��o para separar os dados do erro dos dados do 
                    lChamou := .T.
                Endif
            Endif
            If nVez == 0 .AND. aScan(aErros, "THREAD ERROR") > 0 //Adiciona no vetor at� encontrar a palavra " on "
                AADD(aErros, cLinha)
            Endif
            If nVez == 0 .AND. aScan(aErros, "﻿THREAD ERROR") > 0
                AADD(aErros, cLinha)
            Endif
        Enddo
        Processa({||CutLines(2)},"Aguarde...","Separando dados do arquivo...")
        Processa({||CutLines(3)},"Aguarde...","Separando dados do arquivo...")
        Processa({||GrvTable()},"Aguarde...","Gravando dados na tabela...")
        oFile:Close()
    Endif

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} CutLines
Fun��o respons�vel por separar as informa��es do LOG_FONTE das informa��es do erro
@author  Jo�o Pedro
@since   12/12/2018
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function CutLines(nOpc)

    Local aAux := {} //Vetor auxiliar na quebra de linha
    Local cAux //String auxiliar para ajudar a guardar as informa��es
    Local aCutError2 := {}
    Local x, y, z
    Local cGen := ""

    ProcRegua(Len(aErros)) //Regua de progresso

    cRealError := "" //Limpa a variavel
    For x := 2 To len(aErros)
        cRealError += aErros[x] + " " //Concatena a string do erro
    Next x

    If " on (" $ cRealError
        cRealError := StrTran(Alltrim(cRealError)," on ("," in (")
    Endif

    If " on *" $ cRealError
        cRealError := StrTran(Alltrim(cRealError)," on *"," in *")
    Endif

    If " on +" $ cRealError
        cRealError := StrTran(Alltrim(cRealError)," on +"," in +")
    Endif

    If " on -" $ cRealError
        cRealError := StrTran(Alltrim(cRealError)," on -"," in -")
    Endif

    If " on /" $ cRealError
        cRealError := StrTran(Alltrim(cRealError)," on /"," in /")
    Endif
    
    aCutError := StrTokArr2(cRealError, " on ") //Separa o erro das informa��es do LOG_FONTE
    If "{||" $ aCutError[2] .AND. nNovo == 0
        aCutError2 := StrTokArr(aCutError[2],"}")
    Endif

    /* Trata as informa��es dos Fontes */
    If nOpc == FASE_LOG_FONTE
        IncProc() //Incrementa regua de progresso
        If Empty(aCutError2)
            aAux := StrTokArr(aCutError[2],"(") //Separa a fun��o que deu o erro
            aAux := StrTokArr(aAux[1],")") //Separa a fun��o que deu o erro
            cFunc := Iif(".PRW" $ Upper(aCutError[2]),aAux[1],"Sem Fun��o") //Nome da fun��o que deu o erro
            If ".PRX" $ Upper(aCutError[2]) .OR. ".PRW" $ Upper(aCutError[2]) .OR. ".PRG" $ Upper(aCutError[2])
                cFunc := aAux[1]
            Endif
            cAux := aCutError[2] //Guarda a string que n�o foi separada na string auxiliar
            aAux := StrTokArr(cAux,")")
            If Len(aAux) >= 2
                cGen := aAux[2]
                aAux := StrTokArr(aAux[1],"(")
                If ".PRX" $ Upper(aAux[2]) .OR. ".PRW" $ Upper(aAux[2]) .OR. ".PRG" $ Upper(aAux[2])
                    cLOG_FONTE := StrTokArr(Alltrim(aAux[2]),"(")[1] //Retorna o nome do LOG_FONTE que deu erro
                Else
                    cLOG_FONTE := "Sem Fonte"
                Endif
            Endif
            If Len(aAux) < 2
                cLOG_FONTE := "Sem Fonte"
            Endif
            If !Empty(cGen)
                cDataFonte := StrTran(Alltrim(Substr(cGen,1,11)),"/","-") //Retorna a data do LOG_FONTE que deu erro
            Else
                cDataFonte := "Sem data"
            Endif
            cErro := Substr(StrTran(aCutError[1],"'"," "),0,100) //Grava o erro
        Else
            aAux := StrTokArr(aCutError2[2],"(") //Separa a fun��o que deu o erro
            aAux := StrTokArr(aAux[1],")") //Separa a fun��o que deu o erro
            cFunc := "Sem fun��o"
            cGen := aAux[2]
            cLOG_FONTE := aAux[1] //Retorna o nome do LOG_FONTE que deu erro
            cDataFonte := StrTran(Alltrim(Substr(aAux[2],1,11)),"/","-") //Retorna a data do LOG_FONTE que deu erro
            cErro := Substr(StrTran(aCutError[1],"'"," "),0,100) //Grava o erro
        Endif
        /* Valida��o necess�ria para bancos Oracle - Sugest�o Werllen */
        If "THREAD ID" $ Upper(cErro)
            aErro := StrTokArr2(Upper(cErro),"THREAD ID")
            cErro := aErro[1]
        Endif
        nNovo := 1
    Elseif nOpc == FASE_PILHA
        IncProc()
        For y := 1 To Len(aErros)
            IncProc()
            If "Called" $ aErros[y]
                If "U_" $ aErros[y]
                    lCustomizado := .T.
                Endif
                cPilha += StrTran(aErros[y],"'", " ") + CRLF //Substitui qualquer caracter ' na pilha de chamada por um espa�o, para que n�ao ocorra erro no sql
            Endif
        Next y
    Elseif nOpc == FASE_FRAME //Adiciona as informa��es de LOG_LIB, LOG_DBACES e LOG_SERVER as variaveis
        For z := 1 To Len(aErros)
            IncProc()
            If "RPODB" $ aErros[z]
                cRpo := Alltrim(Left(Right(Alltrim(aErros[z]),5),4))
            Endif
            If "RPOLanguage" $ aErros[z] //Linguagem do RPO
                If "NENHUM" $ Upper(aErros[z])
                    cLangRpo := ""
                Else
                    cLangRpo := Alltrim(Left(Right(Alltrim(aErros[z]),11),10))
                    If "portuguese" $ cLangRpo
                        cLangRpo := "Portugu�s"
                    Elseif "english" $ cLangRpo
                        cLangRpo := "Ingl�s"
                    Elseif "spanish" $ cLangRpo
                        cLangRpo := "Espanhol"
                    Endif
                Endif
            Endif
            If "LocalDBExtension" $ aErros[z] //Extens�o dos arquivos dd dicion�rio
                If "NENHUM" $ Upper(aErros[z])
                    cExt := ""
                Else
                    cExt := Alltrim(Left(Right(Alltrim(aErros[z]),5),4))
                Endif
            Endif
            If "Remote type" $ aErros[z] //Sistema operacional
                cSystem := Alltrim(Left(Right(Alltrim(aErros[z]),21),20))
                If "Windows" $ cSystem
                    cSystem := "Microsoft Windows"
                Elseif "Linux" $ cSystem
                    cSystem := "GNU/Linux"
                Endif
            Endif
            If "Remote Build" $ aErros[z] //Lib
                cLOG_LIB := Alltrim(Left(Right(Alltrim(aErros[z]),22),21))
            Endif
            If "Server Build" $ aErros[z] //AppServer
                cLOG_SERVER := Alltrim(Left(Right(Alltrim(aErros[z]),25),24))
            Endif
            If "DBAccess DB" $ aErros[z] //DbAccess
                cLOG_BANC := Alltrim(Left(Right(Alltrim(aErros[z]),7),6))
            Endif
            If "DBAccess API Build" $ aErros[z]
                cDbVersion := Alltrim(Left(Right(Alltrim(aErros[z]),18),17))
            Endif
            If "RPO Release" $ aErros[z] //Release
                cLOG_REL := Alltrim(Left(Right(Alltrim(aErros[z]),9),8))
            Endif
            If "License Server Version" $ aErros[z] //Licen�as
                cLicense := Alltrim(Left(Right(Alltrim(aErros[z]),18),17))
                If "LOCK" $ Upper(cLicense)
                    cLicense := "Licen�as por Hardlock"
                Elseif "License" $ cLicense
                    cLicense := "License Server Virtual " + Right(cLicense,4)
                Endif
            Endif
        Next z
    Endif
    IncProc()
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} GrvTable
Fun��o respons�vel por verificar se j� existe ou gravar a tabela de log dos erros
@author  Jo�o Pedro
@since   12/12/2018
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function GrvTable()

    Local cQuery := "" //Variavel que conter� a query de execu��o do LOG_BANC
    Local lOk := .F.

    ProcRegua(RecCount())
    LOG->(DbGoTop())
    LOG->(DbSetOrder(2))

    While LOG->(!Eof())
        IncProc()
        If LOG->(DbSeek(xFilial()+Substr(cErro,0,200)+cFunc)) //Verifica se o erro j� existe na base de dados
            lOk := .T.
            If !Empty(LOG->LOG_SOL) .OR. !Empty(LOG->LOG_REFARQ) //Se j� existir uma solu�ao
                Iif(!Empty(LOG->LOG_SOL),EECVIEW(LOG->LOG_SOL,"Solucao"),EECVIEW(LOG->LOG_SOL,"Referencia Arquivo")) //Se existir solu��o. apresenta ela na tela
                If MsgYesNo("Deseja adicionar uma nova solu��o para este erro ?", "Aten��o")
                    CriaSolucao()
                    Return .T.
                Else
                    Return .F.
                Endif
            Else
                If MsgYesNo("Deseja adicionar solu��o para este erro ?","Tem Solucao")
                    CriaSolucao()
                    Return .T.
                Else
                    Return .F.
                Endif
            Endif
        Endif
        LOG->(DbSkip())
    End

    If !lOk
        If MsgYesNo("Erro desconhecido, deseja adicionar a base de dados ?")
            If RecLock("LOG",.T.) //Grava o erro na tabela LOG
                LOG->LOG_FILIAL := xFilial()
                LOG->LOG_ERRO := Iif(Len(cErro) > 200,Substr(cErro,0,200),cErro)
                LOG->LOG_FUNC := cFunc
                LOG->LOG_FONTE := cLOG_FONTE
                LOG->LOG_DT_FT := cDataFonte
                LOG->LOG_TP_BC := cRpo
                LOG->LOG_LINGUA := cLangRpo
                LOG->LOG_EXT := cExt
                LOG->LOG_SYSTEM := cSystem
                LOG->LOG_LIB := cLOG_LIB
                LOG->LOG_SERVER := cLOG_SERVER
                LOG->LOG_BANC := cLOG_BANC
                LOG->LOG_DBACES := cDbVersion
                LOG->LOG_REL := cLOG_REL
                LOG->LOG_LIC := cLicense
                LOG->LOG_PILHA := cPilha
                LOG->(MsUnlock())
            Endif
        Else
            Return .F.
        Endif
    Endif


Return lOk

//-------------------------------------------------------------------
/*/{Protheus.doc} CriaSolucao
LOG_FUNC responsavel por apresentar tela de LOG_SOL
@author  Joao Pedro
@since   12/12/2018
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function CriaSolucao()

    Local cLOG_SOL := Alltrim(LOG->LOG_SOL) //Variavel que ir� guardar a LOG_SOL
    Local cLabel := ""
    Local oMemo
    Local oFont := TFont():New("Courier New",09,15)
    Local bOk      := {|| nOpc := 1,oDlg:End()}
    Local bCancel  := {|| oDlg:End()}
    Local aButtons := {}
    Local nOpc := 0

    AADD(aButtons,{"NOTE",{|| ExecNote(LOG->LOG_SOL,"Solucao.txt")},"Notepad"}) //Exporta a solu��o para .txt
    AADD(aButtons,{"FILES",{|| BuscaArq(LOG->LOG_REFARQ)},"Patchs"}) //Busca os arquivos gravados para este erro

    /* Cria��o da tela de solu��o */
    DEFINE MSDIALOG oDlg TITLE "Inclus�o Solu��o" FROM 9,0 TO 39,85 OF oDlg

        oPanel := TPanel():New(0,0,"",oDlg,,.F.,.F.,,,90,165)
        oPanel:Align := CONTROL_ALIGN_ALLCLIENT

        @ 05,05 TO 190,330 Label cLabel PIXEL OF oPanel
        @ 15,10 GET oMemo Var cLOG_SOL MEMO HSCROLL FONT oFont SIZE 315,169 OF oPanel PIXEL

        oMemo:lWordWrap := .T.
        oMemo:EnableVScroll(.T.)
        oMemo:EnableHScroll(.T.)

    ACTIVATE MSDIALOG oDlg ON INIT EnchoiceBar(oDlg,bOk,bCancel,,aButtons) CENTERED

    If nOpc == 1
        If !Empty(cLOG_SOL)
            If RecLock("LOG",.F.)
                LOG->LOG_SOL := Alltrim(cLOG_SOL) //Grava a solu��o na tabela
            Endif
        Endif
    Else
        If !MsgYesNo("Solucao n�o informada, deseja prosseguir ?","Atencao")
            CriaSolucao()
        Else
            U_ReadError()
        Endif
    Endif

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} ExecNote
Exporta Solu��o para txt
@author  Jo�o Pedro.
@since   13/12/2018
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function ExecNote(cMsg,cFile)

    Local cDir := GetWinDir()+"\Temp\"
    Local hFile

    Begin Sequence
        hFile := FCreate(cDir+cFile)

        FWrite(hFile,cMsg,Len(cMsg))

        FClose(hFile)

        WinExec("Notepad " + cDir+cFile)
    End Sequence

Return

Function BuscaArq(cRef)

    Local aFile := {}

    Default cRef := ""

    If Empty(cRef)
        MsgInfo("N�o h� arquivos listados para este erro","Aten��o")
        Return .F.
    Endif

    cRef := Alltrim(cRef)

    aFile := StrTokArr(Alltrim(cRef),"\")

    If !File(GetSrvProfString ("ROOTPATH","") + cRef)
        MsgInfo("N�o encontrado o arquivo " + cRef + CRLF + "Ou usu�rio sem permiss�o", "Aten��o")
        Return .F.
    Endif

    If !CpyS2T(cRef,GetTempPath())
        MsgInfo("N�o foi poss�vel copiar o arquivo do servidor", "Aten��o")
        Return .F.
    Else
        MsgInfo("Arquivo " + aFile[Len(aFile)] +  "copiado para a pasta temp","Sucesso")
    Endif

Return