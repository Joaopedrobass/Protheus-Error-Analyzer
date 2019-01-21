#Include 'Protheus.ch'
#Include 'Totvs.ch'

/* Constantes */
#DEFINE FASE_LOG_FONTE 1
#DEFINE FASE_PILHA 2
#DEFINE FASE_FRAME 3

//-------------------------------------------------------------------
/*/{Protheus.doc} xReadError
Função de inclusão automática de erros
@author  João Pedro
@since   08/01/2018
@version 1.0
/*/
//-------------------------------------------------------------------
User Function xReadError()
    Local aParamBox := {}
    Private aRet := {} //Variavel necessária para não dar error.log
    Private nNovo := 0
    Private lCustomizado := .F.
    Private lErro := .F.
    /* Montagem da tela de parâmetro para seleção do arquivo de erro */
    AADD(aParamBox,{6,"Arquivo ?",Space(70),"","","",70,.T.,"Todos os arquivo (*.*)|*.*"})
    If ParamBox(aParamBox,"Selecione o arquivo",aRet)
        cFile := aRet[1]
        If ".log" $ cFile .OR. ".txt" $ cFile
            Processa({||ReadArq(cFile)},"Aguarde...","Lendo arquivo de texto...",.F.) //Função que irá ler linha por linha do error.log
        Else
            MsgInfo("Não é possível ler arquivos com esta extensão","Atenção")
            Return .F.
        Endif
    Endif
    If lCustomizado
        MsgInfo("Há uma customização na pilha de chamada deste erro","Atenção")
    Endif
    If !lErro
        If MsgYesNo("Deseja excluir o arquivo de erro ?","Atenção")
            FErase(cFile)
        Endif
    Endif
Return
//-------------------------------------------------------------------
/*/{Protheus.doc} ReadArq
Função responsável por ler o arquivo txt
@author  João Pedro
@since   12/12/2018
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function ReadArq(cFile)
    Local oFile //Objeto que conterá o FWFileReader
    Local cLinha //Guarda a linha atual do arquivo
    Local nVez //Variavel necessária para que não assimile varias linhas ao vetor do erro
    Local lChamou := .F.
    aErros := {}
    ProcRegua(1000) //Regua de progresso
    oFile := FWFileReader():New(cFile) //Instancia a classe FWFileReader
    If oFile:Open() //Abre o arquivo para leitura
        Do While oFile:hasLine() //Enquanto houver linha no arquivo
            IncProc() //Incrementa regua de progresso
            cLinha := oFile:GetLine() //Pega a linha atual
            If "ÿþ" $ cLinha
                MsgInfo("Ocorreu algum problema com este error.log, Inclua o mesmo manualmente","Atenção")
                lErro := .T.
                Return .F.
            Endif
            nVez := 0
            If "THREAD ERROR" $ cLinha //Se for encontrado "THREAD ERROR" adiciona ao vetor aErros
                AADD(aErros, cLinha)
                nVez := 1
            Endif
            If " on " $ cLinha .AND. !" on (" $ cLinha //Quando for encontrado " on " na linha, quer dizer que chegamos no final do erro puro
                If aScan(aErros, "THREAD ERROR") > 0 .OR. aScan(aErros, "ï»¿THREAD ERROR") > 0 .AND. nVez == 0
                    AADD(aErros, cLinha)
                    nVez := 1
                Endif
                If !lChamou
                    Processa({||CutLines(1)},"Aguarde...","Separando dados do arquivo...") //Chama a função para separar os dados do erro dos dados do 
                    lChamou := .T.
                Endif
            Endif
            If nVez == 0 .AND. aScan(aErros, "THREAD ERROR") > 0 //Adiciona no vetor até encontrar a palavra " on "
                AADD(aErros, cLinha)
            Endif
            If nVez == 0 .AND. aScan(aErros, "ï»¿THREAD ERROR") > 0
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
Função responsável por separar as informações do LOG_FONTE das informações do erro
@author  João Pedro
@since   12/12/2018
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function CutLines(nOpc)
    Local aAux := {} //Vetor auxiliar na quebra de linha
    Local cAux //String auxiliar para ajudar a guardar as informações
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
    
    aCutError := StrTokArr2(cRealError, " on ") //Separa o erro das informações do LOG_FONTE
    If "{||" $ aCutError[2] .AND. nNovo == 0
        aCutError2 := StrTokArr(aCutError[2],"}")
    Endif
    /* Trata as informações dos Fontes */
    If nOpc == FASE_LOG_FONTE
        IncProc() //Incrementa regua de progresso
        If Empty(aCutError2)
            aAux := StrTokArr(aCutError[2],"(") //Separa a função que deu o erro
            aAux := StrTokArr(aAux[1],")") //Separa a função que deu o erro
            cFunc := Iif(".PRW" $ Upper(aCutError[2]),aAux[1],"Sem Função") //Nome da função que deu o erro
            If ".PRX" $ Upper(aCutError[2]) .OR. ".PRW" $ Upper(aCutError[2]) .OR. ".PRG" $ Upper(aCutError[2])
                cFunc := aAux[1]
            Endif
            cAux := aCutError[2] //Guarda a string que não foi separada na string auxiliar
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
            aAux := StrTokArr(aCutError2[2],"(") //Separa a função que deu o erro
            aAux := StrTokArr(aAux[1],")") //Separa a função que deu o erro
            cFunc := "Sem função"
            cGen := aAux[2]
            cLOG_FONTE := aAux[1] //Retorna o nome do LOG_FONTE que deu erro
            cDataFonte := StrTran(Alltrim(Substr(aAux[2],1,11)),"/","-") //Retorna a data do LOG_FONTE que deu erro
            cErro := Substr(StrTran(aCutError[1],"'"," "),0,100) //Grava o erro
        Endif
        /* Validação necessária para bancos Oracle - Sugestão Werllen */
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
                cPilha += StrTran(aErros[y],"'", " ") + CRLF //Substitui qualquer caracter ' na pilha de chamada por um espaço, para que nçao ocorra erro no sql
            Endif
        Next y
    Elseif nOpc == FASE_FRAME //Adiciona as informações de LOG_LIB, LOG_DBACES e LOG_SERVER as variaveis
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
                        cLangRpo := "Português"
                    Elseif "english" $ cLangRpo
                        cLangRpo := "Inglês"
                    Elseif "spanish" $ cLangRpo
                        cLangRpo := "Espanhol"
                    Endif
                Endif
            Endif
            If "LocalDBExtension" $ aErros[z] //Extensão dos arquivos dd dicionário
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
            If "License Server Version" $ aErros[z] //Licenças
                cLicense := Alltrim(Left(Right(Alltrim(aErros[z]),18),17))
                If "LOCK" $ Upper(cLicense)
                    cLicense := "Licenças por Hardlock"
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
Função responsável por verificar se já existe ou gravar a tabela de log dos erros
@author  João Pedro
@since   12/12/2018
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function GrvTable()
    Local cQuery := "" //Variavel que conterá a query de execução do LOG_BANC
    Local lOk := .F.
    ProcRegua(RecCount())
    LOG->(DbGoTop())
    LOG->(DbSetOrder(2))
    While LOG->(!Eof())
        IncProc()
        If LOG->(DbSeek(xFilial()+Substr(cErro,0,200)+cFunc)) //Verifica se o erro já existe na base de dados
            lOk := .T.
            If !Empty(LOG->LOG_SOL) .OR. !Empty(LOG->LOG_REFARQ) //Se já existir uma soluçao
                Iif(!Empty(LOG->LOG_SOL),EECVIEW(LOG->LOG_SOL,"Solucao"),EECVIEW(LOG->LOG_SOL,"Referencia Arquivo")) //Se existir solução. apresenta ela na tela
                If MsgYesNo("Deseja adicionar uma nova solução para este erro ?", "Atenção")
                    CriaSolucao()
                    Return .T.
                Else
                    Return .F.
                Endif
            Else
                If MsgYesNo("Deseja adicionar solução para este erro ?","Tem Solucao")
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
    Local cLOG_SOL := Alltrim(LOG->LOG_SOL) //Variavel que irá guardar a LOG_SOL
    Local cLabel := ""
    Local oMemo
    Local oFont := TFont():New("Courier New",09,15)
    Local bOk      := {|| nOpc := 1,oDlg:End()}
    Local bCancel  := {|| oDlg:End()}
    Local aButtons := {}
    Local nOpc := 0
    AADD(aButtons,{"NOTE",{|| ExecNote(LOG->LOG_SOL,"Solucao.txt")},"Notepad"}) //Exporta a solução para .txt
    AADD(aButtons,{"FILES",{|| BuscaArq(LOG->LOG_REFARQ)},"Patchs"}) //Busca os arquivos gravados para este erro
    /* Criação da tela de solução */
    DEFINE MSDIALOG oDlg TITLE "Inclusão Solução" FROM 9,0 TO 39,85 OF oDlg
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
                LOG->LOG_SOL := Alltrim(cLOG_SOL) //Grava a solução na tabela
            Endif
        Endif
    Else
        If !MsgYesNo("Solucao não informada, deseja prosseguir ?","Atencao")
            CriaSolucao()
        Else
            U_ReadError()
        Endif
    Endif
Return Nil
//-------------------------------------------------------------------
/*/{Protheus.doc} ExecNote
Exporta Solução para txt
@author  João Pedro.
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
        MsgInfo("Não há arquivos listados para este erro","Atenção")
        Return .F.
    Endif
    cRef := Alltrim(cRef)
    aFile := StrTokArr(Alltrim(cRef),"\")
    If !File(GetSrvProfString ("ROOTPATH","") + cRef)
        MsgInfo("Não encontrado o arquivo " + cRef + CRLF + "Ou usuário sem permissão", "Atenção")
        Return .F.
    Endif
    If !CpyS2T(cRef,GetTempPath())
        MsgInfo("Não foi possível copiar o arquivo do servidor", "Atenção")
        Return .F.
    Else
        MsgInfo("Arquivo " + aFile[Len(aFile)] +  "copiado para a pasta temp","Sucesso")
    Endif
Return