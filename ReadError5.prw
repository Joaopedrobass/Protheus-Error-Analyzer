#Include 'Protheus.ch'
#Include 'Totvs.ch'

User Function ReadDue()

    Local aParamBox := {}

    Private aRet := {} //Variavel necessária para não dar error.log

    /* Montagem da tela de parâmetro para seleção do arquivo de erro */
    AADD(aParamBox,{6,"Arquivo ?",Space(70),"","","",70,.T.,"Todos os arquivos (*.*)|*.*"})

    If ParamBox(aParamBox,"Selecione o arquivo",aRet)
        cFile := aRet[1]
        If ".log" $ cFile .OR. ".txt" $ cFile
            Processa({||ReadArq(cFile)},"Aguarde...","Lendo arquivo de texto...",.F.) //Função que irá ler linha por linha do error.log
        Else
            MsgInfo("Não é possível ler arquivos com esta extensão","Atenção")
            Return .F.
        Endif
    Endif

Return

Static Function ReadArq()

    Local oFile //Objeto que conterá o FWFileReader
    Local cLinha //Guarda a linha atual do arquivo

    Private aErros := {}

    ProcRegua(1000) //Regua de progresso

    oFile := FWFileReader():New(cFile) //Instancia a classe FWFileReader
    If oFile:Open() //Abre o arquivo para leitura
        Do While oFile:hasLine() //Enquanto houver linha no arquivo
            IncProc() //Incrementa regua de progresso
            cLinha := oFile:GetLine() //Pega a linha atual
            If "[Versão:" $ cLinha .AND. "suite" $ cLinha
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
        If "[Versão" $ aErros[x]   
            aVersao := Strtokarr2( aErros[x], "suite")
            cVersao := Alltrim(StrTran(Strtokarr2(aVersao[1],"Versão:")[2],"("," "))
            If "3.1.0" $ cVersao
                cMsg += "Integrador .JAR" + "  --->  " + "Encontra-se atualizado" + CRLF + CRLF
            Else
                cMsg += "Integrador .JAR" + "  --->  " + "Arquivo desatualizado" + CRLF + CRLF
            Endif
        Endif
        If "URL INFORMADA" $ aErros[x]
            cUrl := Iif("val" $ Alltrim(StrTokArr2(aErros[x],"URL INFORMADA:")[2]), cMsg += "Base DU-E  --->  TESTE" + CRLF + CRLF, cMsg += "Base DU-E  -->  PRODUÇÃO" + CRLF + CRLF)
        Endif
        If "[ERROR]" $ aErros[x]
            cMsgErro += CRLF + Alltrim(StrTokArr2(aErros[x],"->")[2]) + CRLF
            VerErro(aErros[x])
        Endif
    Next x

    cMsg += cMsgJava + cMsgErro

    If Empty(cMsgSugestao)
        cMsgSugestao := "Não há sugestões"
    Endif

    cMsg += CRLF + CRLF + "--------SUGESTÕES---------" + CRLF + CRLF + cMsgSugestao

    EECVIEW(cMsg,"Análise DU-E")

Return

Static Function VerErro(cErro)

    Local aSug := {}
    Local cTag := ""

    If "definidas no XSD" $ cErro .AND. !lXSD
        aSug := StrTokArr(cErro,"}")
        aSug := StrTokArr(aSug[1],"{")
        aSug := StrTokArr(aSug[2],":")
        cTag := aSug[Len(aSug)]
        cMsgSugestao += "O arquivo XML não está completo ou a tag " + cTag + " está incorreta." + CRLF
        lXSD := .T.
    Endif

    If "Erro ao realizar autenticação" $ cErro .AND. !lCertificado
        cMsgSugestao += "Não foi selecionado nenhum certificado ao transmitir a DU-E, ou o certificado escolhido é inválido" + CRLF
        lCertificado := .T.
    Endif

    If "pessoa diferente do declarante" $ cErro .AND. !lDeclarante
        cMsgSugestao += "Modificar o campo EEC_FORN para o de um fornecedor que tenha o mesmo CNPJ que a empresa que emitiu a nota pro Sefaz" + CRLF
        lDeclarante := .T.
    Endif

    If "Falha ao processar a retificação" $ cErro .AND. !lRetifica
        cMsgSugestao += "Informar o motivo da retificação da DU-E no sistema" + CRLF
        lRetifica := .T.
    Endif

Return