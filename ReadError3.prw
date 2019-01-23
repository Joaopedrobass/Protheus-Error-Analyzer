#Include 'Protheus.ch'
#Include 'Totvs.ch'

//-------------------------------------------------------------------
/*/{Protheus.doc} U_ExportData
Função que exporta os dados para Excel e TXT
@author  João Pedro
@since   16/01/2018
@version 1.0
/*/
//-------------------------------------------------------------------
User Function ExportData()

    Processa({||MontaWork()},"Aguarde...","Montado arquivos temporários...",.F.) //Chama função para montar os temporários

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} MontaWork
Função que monta arquivos temporários
@author  João Pedro
@since   16/01/2018
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function MontaWork()

    Local x, y
    Local aEstrutura := {} //Array que guarda a estrutura do temporário

    SX3->(DbSetOrder(2)) //Seta a ordem na SX3

    For x := 1 To Len(LOG->(DbStruct()))
        AADD(aEstrutura, {LOG->(DbStruct())[x][1],LOG->(DbStruct())[x][2],LOG->(DbStruct())[x][3],LOG->(DbStruct())[x][4]}) //Adiciona na estrutura do temporário os campos da tabela LOG
    Next x

    cFileTxt := E_CriaTrab(,aEstrutura,"WorkTxt") //Cria área de trabalho

    /* Caso não consiga criar */
    If !USED()
        MsgInfo("Não foi possível criar arquivo temporário","Atenção")
        Return .F.
    Endif

    IndRegua("WorkTxt",cFileTxt+TEOrdBagExt(),"LOG_ERRO+LOG_FUNC+LOG_FONTE") //Cria indices

    LOG->(DbGoTop()) //Posiciona no primeiro registro da tabela LOG
    WorkTxt->(DbGoTop()) //Posiciona no primeiro registro da Work
    ProcRegua(LOG->(LastRec())) //Incrementa regua de progresso

    While LOG->(!Eof())

        IncProc("Processando erro: " + LOG->LOG_ERRO)

        /*Popula arquivo temporário */
        WorkTxt->(DbAppend())
        WorkTxt->LOG_FILIAL := LOG->LOG_FILIAL
        WorkTxt->LOG_ERRO := LOG->LOG_ERRO
        WorkTxt->LOG_FUNC := LOG->LOG_FUNC
        WorkTxt->LOG_FONTE := LOG->LOG_FONTE
        WorkTxt->LOG_DT_FT := LOG->LOG_DT_FT
        WorkTxt->LOG_TP_BC := LOG->LOG_TP_BC
        WorkTxt->LOG_LINGUA := LOG->LOG_LINGUA
        WorkTxt->LOG_EXT := LOG->LOG_EXT
        WorkTxt->LOG_SYSTEM := LOG->LOG_SYSTEM
        WorkTxt->LOG_LIB := LOG->LOG_LIB
        WorkTxt->LOG_SERVER := LOG->LOG_SERVER
        WorkTxt->LOG_BANC := LOG->LOG_BANC
        WorkTxt->LOG_DBACES := LOG->LOG_DBACES
        WorkTxt->LOG_REL := LOG->LOG_REL
        WorkTxt->LOG_LIC := LOG->LOG_LIC
        WorkTxt->LOG_SOL := LOG->LOG_SOL
        WorkTxt->LOG_PILHA := LOG->LOG_PILHA

        LOG->(DbSkip())

    Enddo

    WorkTxt->(DbGoTop())
    Processa({||MontaTela()},'Aguarde...','Montando Tela...',.F.) 

    WorkTxt->(E_EraseArq(cFileTxt)) //Exclui arquivo temporário gerado

    LOG->(DbGoTop())

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} MontaTela
Função que monta a tela para selecionar entre TXT e Excel
@author  João Pedro
@since   16/01/2018
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function MontaTela()

    Local oDlg
    Local cApp := "" //Variavel que guardara o tipo do arquivo (TXT ou Excel)
    Local cFile := Space(07) //Variavel que guardara o nome do arquivo
    Local cDir := Space(30) //Variavel que guardara o diretorio onde sera gravado o arquivo
    Local aApp := {"TXT","Excel"} //Vetor para o combobox
    Local nOpc := 0 //Variavel que guardara a opção escolhida pelo usuario (OK, Cancelar)
    Local cDirStart:=Upper(GetSrvProfString("STARTPATH","")) //Variavel que guardara caminho onde será salvo o arquivo
    Local bArqValid := {||IF(TR350VALID(2,cFile).AND.TR350VALID(3,cDir),MsgYesNo("Confirma a geração do arquivo ?","Atenção"),.F.)} //Validação do arquivo
    Local aDeletados := {}
    Local cWork := "WorkTxt" //Nome da area de trabalho
    Local cTit := "Análise de Erros" //Titulo da tela
    Local aTitulos := Nil
    Local nI

    Private lValExcel := .F.

    IF(Right(cDirStart,1) != "\", cDirStart += "\",)

    /* Monta tela */
    DEFINE MSDIALOG oDlg TITLE "Exporta Dados" From 9,0 To 20,50 OF oMainWnd
    oPanel := TPanel():New(0,0,"",oDlg,,.F.,.F.,,,90,165)
    oPanel:Align := CONTROL_ALIGN_ALLCLIENT

    @ 10,03 SAY "Tipo do arquivo" OF oPanel PIXEL
    @ 23,03 SAY "Nome Arquivo" OF oPanel PIXEL
    @ 36,03 SAY "Diretório" OF oPanel PIXEL
    @ 10,45 COMBOBOX cApp ITEMS aApp SIZE 35,10 OF oPanel PIXEL
    @ 23,45 MSGET cFile SIZE 30,7 When cApp <> "EXCEL" VALID TR350VALID(2,cFile) OF oPanel PIXEL
    @ 36,45 MSGET cDir  SIZE 95,8 PICTURE '@!' VALID TR350VALID(3,cDir) OF oPanel PIXEL WHEN .F.
    @ 35,150 BUTTON "Alterar" SIZE 38,12 When cApp <> "EXCEL" ACTION If(!Empty(cNewDir := ChooseFile()), cDir := cNewDir, ) OF oPanel Pixel

     ACTIVATE MSDIALOG oDlg ON INIT ;
            EnchoiceBar(oDlg,{||nOpc:=1,IF(EVAL(bArqValid),oDlg:End(),nOpc:=0)},;
                             {||oDlg:End()}) CENTERED

    If nOpc == 0
        Return .F.
    Endif

    If Empty(cFile) .And. cApp <> "EXCEL"
        cFile:= CriaTrab(, .F.)
    EndIf

    xFile := cFile

    lConfirma := .T.

    cFileAux := Alltrim(cDirStart)+AllTrim(cFile)

    If cApp == "TXT" .AND. Left(cDir,1) == "\"
        cDir := GetTempPath()
    Endif

    cFile := Alltrim(cDir)+If(Right(Alltrim(cDir),1)="\","","\")+AllTrim(cFile)

    IF FILE(cFile+"."+cApp)
        lConfirma:=MsgYesNo("Arquvio já existe, deseja sobrepor ?","Atenção")
    Endif

    If lConfirma

        IF FILE(cFileAux+"."+cApp)
            ERASE(cFileAux+"."+cApp)
        ENDIF

        ERASE(cFile+"."+cApp)

        If cApp == "TXT"
            COPY TO (cFileAux+"."+cApp) SDF
            If cFileAux <> cFile
                If !AvCpyFile(cFileAux+"."+cApp,cFile+"."+cApp,.T.)
                    MsgInfo("Problema ao copiar arquivo " + cFile+"."+cApp,"Atenção")
                Else
                    ERASE(cFileAux+"."+cApp)
                Endif
            Endif
            ShellExecute("open", Alltrim(cFile)+"."+cApp,"","",1)
        Elseif cApp == "Excel"
            AADD(aDeletados, "DBDELETE")
            AADD(aDeletados, "DELETE")
            aCols := GeraDados(cWork,aDeletados)

            If aTitulos = Nil
                aTitulos := (cWork)->(DbStruct())
                For nI := 1 To Len(aDeletados)
                    If (nPos := aScan(aTitulos, {|x| Alltrim(x[1]) == aDeletados[nI]})) > 0
                        aDel(aTitulos,nPos)
                        aSize(aTitulos,Len(aTitulos)-1)
                    Endif
                Next nI
            Endif

            Processa({||toExcel({{"GETDADOS",cTit, aTitulos,aCols}})},'Aguarde...','Extraindo Dados...')
        Endif
    Endif

Return

Static Function toExcel(aSheets)

    Local cTableTit
    Local aHeads
    Local aRows
    Local oExcel := FWMsExcel():New()
    Local cFileName := "excelfile.xml"
    Local i
    FErase(cFileName)
    For i := 1 To Len(aSheets)
        cTableTit := aSheets[i][2]
        aHeads := aSheets[i][3]
        aRows := aSheets[i][4]
        oExcel:AddWorkSheet(cTableTit)
        oExcel:AddTable(cTableTit,cTableTit)
        fillHeads(oExcel,cTableTit,aHeads)
        fillData(oExcel,cTableTit,aRows)
    Next i
    oExcel:Activate()
    oExcel:GetXMLFile(cFileName)
    oExcel:DeActivate()
    FreeObj(oExcel)
    openExcel(cFileName)

Return

Static Function openExcel(cFileName)

    Local oExcelApp := MsExcel():New()
    Local cFileTMP := GetTempPath() + cFileName
    __CopyFile(cFileName,cFileTMP)
    oExcelApp:WorkBooks:Open(cFileTMP)
    oExcelApp:SetVisible(.T.)
    oExcelApp:Destroy()

Return

Static Function fillHeads(oExcel,cTableTit,aHeads)

    Local cHeadTitle
    Local i
    For i := 1 To Len(aHeads)
        cHeadTitle := aHeads[i][1]
        oExcel:AddColumn(cTableTit,cTableTit,cHeadTitle)
    Next i

Return

Static Function fillData(oExcel,cTableTit,aRows)

    Local i
    For i := 1 To Len(aRows)
        oExcel:AddRow(cTableTit,cTableTit,aRows[i])
    Next i

Return

Static Function ChooseFile()

    Local cTitle:= "Selecione o diretório para gravação do arquivo."
    Local nDefaultMask := 0
    Local cDefaultDir  := "C:\"
    Local nOptions:= GETF_OVERWRITEPROMPT+GETF_LOCALHARD+GETF_NETWORKDRIVE+GETF_RETDIRECTORY
    Local cFile := cGetFile(,cTitle,nDefaultMask,cDefaultDir,,nOptions)

Return cFile  