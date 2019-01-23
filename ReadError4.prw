#Include 'Protheus.ch'
#Include 'Totvs.ch'

User Function Anexo()

    Local aParamBox := {}

    Private aRet := {}

    If !Empty(LOG->LOG_REFARQ)
        If MsgYesNo("J� existe arquivos para este erro, Deseja visualiza-los ?","Aten��o")
            BuscaArq(LOG->LOG_REFARQ)
            Return .T.
        Endif
    Endif

    /* Montagem da tela de par�metro para sele��o do arquivo de erro */
    AADD(aParamBox,{6,"Arquivo ?",Space(70),"","","",70,.T.,"Todos os arquivo (*.*)|*.*"})

    If ParamBox(aParamBox,"Selecione o arquivo",aRet)
        cFile := aRet[1]
        If !":" $ Upper(cFile)
            MsgInfo("Para anexar o arquivo � necess�rio informar um diret�rio local","Aten��o")
            U_Anexo()
        Endif
        Processa({||VerPasta(cFile)},"Aguarde...","Verificando pasta...",.F.) //Fun��o que ir� ler linha por linha do error.log
    Endif

Return

Static Function VerPasta(cFile)

    Local cDirStart:=GetSrvProfString("STARTPATH","")
    Local lRet
    Local nRet
    Local cPasta := ""
    Local aArq := {}
    Local aFiles := {}
    Local lBreak := .T.
    Local nCount := 1

    ProcRegua(100)

    If !Empty(LOG->LOG_REFARQ)
        cDirStart := Alltrim(LOG->LOG_REFARQ)
    Else
        While lBreak
            If File(cDirStart + cValToChar(nCount))
                nCount ++
            Else
                lBreak := .F.
            Endif
        Enddo
        cPasta := cDirStart + cValToChar(nCount)
        lRet := MakeDir(cPasta)
        If lRet != 0
            MsgInfo("N�o foi poss�vel criar a pasta no servidor. Erro: " + Str(FError()) ,"Aten��o")
            Return .F.
        Endif
    Endif

    aArq := StrTokArr(cFile,"\")

    If !File(Iif(Empty(cPasta),cDirStart,cPasta) + "\" + Alltrim(aArq[Len(aArq)]) )
        If !CpyT2S(cFile,Iif(Empty(cPasta),cDirStart,cPasta + "\"))
            IncProc()
            MsgInfo("N�o foi poss�vel copiar arquivo para o servidor", "Aten��o")
            Return .F.
        Endif
    Endif

    AADD(aFiles, Iif(Empty(cPasta),cDirStart,cPasta) + "\" + Alltrim(aArq[Len(aArq)]))

    If !".zip" $ cFile
        If FZip(Iif(Empty(cPasta),cDirStart,cPasta) + "\"+ cValToChar(nCount) + ".zip", aFiles) != 0
            IncProc()
            MsgInfo("N�o foi poss�vel zipar o arquivo no servidor","Aten��o")
            Return .F.
        Endif
    Endif

    RecLock("LOG",.F.)
    LOG->LOG_REFARQ := Iif(Empty(cPasta),cDirStart,cPasta) + "\"+ Iif(!".zip" $ cFile,cValToChar(nCount) + ".zip",aArq[Len(aArq)])
    LOG->(MsUnlock())

    If !".zip" $ cFile
        nRet := FErase(Iif(Empty(cPasta),cDirStart,cPasta) + "\" + Alltrim(aArq[Len(aArq)]))

        If nRet < 0 
            MsgInfo("N�o foi poss�vel excluir o arquivo " + FError(),"Aten��o")
        Endif
    Endif

    If MsgYesNo("Deseja excluir o arquivo do computador ?", "Aten��o")
        FErase(cFile)
    Endif
    
Return