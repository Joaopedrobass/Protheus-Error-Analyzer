#Include 'Protheus.ch'
#Include 'Totvs.ch'

User Function ReadDue()

    Local aParamBox := {}

    Private aRet := {} //Variavel necess�ria para n�o dar error.log

    /* Montagem da tela de par�metro para sele��o do arquivo de erro */
    AADD(aParamBox,{6,"Arquivo ?",Space(70),"","","",70,.T.,"Todos os arquivos (*.*)|*.*"})

    If ParamBox(aParamBox,"Selecione o arquivo",aRet)
        cFile := aRet[1]
        If ".log" $ cFile .OR. ".txt" $ cFile
            Processa({||ReadArq(cFile)},"Aguarde...","Lendo arquivo de texto...",.F.) //Fun��o que ir� ler linha por linha do error.log
        Else
            MsgInfo("N�o � poss�vel ler arquivos com esta extens�o","Aten��o")
            Return .F.
        Endif
    Endif

Return

Static Function ReadArq()

    Local oFile //Objeto que conter� o FWFileReader
    Local cLinha //Guarda a linha atual do arquivo

    Private aErros := {}

    ProcRegua(1000) //Regua de progresso

    oFile := FWFileReader():New(cFile) //Instancia a classe FWFileReader
    If oFile:Open() //Abre o arquivo para leitura
        Do While oFile:hasLine() //Enquanto houver linha no arquivo
            IncProc() //Incrementa regua de progresso
            cLinha := oFile:GetLine() //Pega a linha atual
            If "[Vers�o:" $ cLinha .AND. "suite" $ cLinha
                AADD(aErros, cLinha)
            Endif
            If "[ERROR]" $ cLinha .AND. !"TrSwCrawler" $ cLinha .OR. "<error>" $ cLinha
                AADD(aErros, cLinha)
            Endif
            If "Java Runtime" $ cLinha
                AADD(aErros, cLinha)
            Endif
            If "URL INFORMADA" $ cLinha
                AADD(aErros, cLinha)
            Endif
        Enddo
        Processa({||VerDados()},"Aguarde...","Separando dados do arquivo...")
        oFile:Close()
    Endif

Return


Static Function VerDados()

    Local x
    Local aVersao := {}
    Local aJava := {}
    Local cJava := ""
    Local cVersao := ""
    Local cUrl := ""
    Local cMsg := ""
    Local cMsgErro := "Mensagens de erro" + CRLF
    Local cMsgJava := ""

    Private cMsgSugestao := ""
    Private lXSD := .F.
    Private lCertificado := .F.
    Private lDeclarante := .F.
    Private lRetifica := .F.

    For x := 1 To Len(aErros)
        If "Java Runtime" $ aErros[x] .AND. Empty(cMsgJava)
            aJava := Strtokarr(aErros[x],"(")
            cJava := Alltrim(Right(aJava[1],14))
            If "1.8.0_201" $ cJava
                cMsgJava += "Java" + "  --->  " + "Encontra-se atualizado" + CRLF + CRLF
            Else
                cMsgJava += "Java" + "  --->  " + "Arquivo desatualizado" + CRLF + CRLF
            Endif
        Endif
        If "[Vers�o" $ aErros[x]   
            aVersao := Strtokarr2( aErros[x], "suite")
            cVersao := Alltrim(StrTran(Strtokarr2(aVersao[1],"Vers�o:")[2],"("," "))
            If "3.1.0" $ cVersao
                cMsg += "Integrador .JAR" + "  --->  " + "Encontra-se atualizado" + CRLF + CRLF
            Else
                cMsg += "Integrador .JAR" + "  --->  " + "Arquivo desatualizado" + CRLF + CRLF
            Endif
        Endif
        If "URL INFORMADA" $ aErros[x]
            cUrl := Iif("val" $ Alltrim(StrTokArr2(aErros[x],"URL INFORMADA:")[2]), cMsg += "Base DU-E  --->  TESTE" + CRLF + CRLF, cMsg += "Base DU-E  -->  PRODU��O" + CRLF + CRLF)
        Endif
        If "[ERROR]" $ aErros[x]
            cMsgErro += CRLF + Alltrim(StrTokArr2(aErros[x],"->")[2]) + CRLF
            VerErro(aErros[x])
        Endif
    Next x

    cMsg += cMsgJava + cMsgErro

    If Empty(cMsgSugestao)
        cMsgSugestao := "N�o h� sugest�es"
    Endif

    cMsg += CRLF + CRLF + "--------SUGEST�ES---------" + CRLF + CRLF + cMsgSugestao

    EECVIEW(cMsg,"An�lise DU-E")

Return

Static Function VerErro(cErro)

    Local aSug := {}
    Local cTag := ""

    If "definidas no XSD" $ cErro .AND. !lXSD
        aSug := StrTokArr(cErro,"}")
        aSug := StrTokArr(aSug[1],"{")
        aSug := StrTokArr(aSug[2],":")
        cTag := aSug[Len(aSug)]
        cMsgSugestao += "O arquivo XML n�o est� completo ou a tag " + cTag + " est� incorreta." + CRLF
        lXSD := .T.
    Endif

    If "Erro ao realizar autentica��o" $ cErro .AND. !lCertificado
        cMsgSugestao += "N�o foi selecionado nenhum certificado ao transmitir a DU-E, ou o certificado escolhido � inv�lido" + CRLF
        lCertificado := .T.
    Endif

    If "pessoa diferente do declarante" $ cErro .AND. !lDeclarante
        cMsgSugestao += "Modificar o campo EEC_FORN para o de um fornecedor que tenha o mesmo CNPJ que a empresa que emitiu a nota pro Sefaz" + CRLF
        lDeclarante := .T.
    Endif

    If "Falha ao processar a retifica��o" $ cErro .AND. !lRetifica
        cMsgSugestao += "Informar o motivo da retifica��o da DU-E no sistema" + CRLF
        lRetifica := .T.
    Endif

Return