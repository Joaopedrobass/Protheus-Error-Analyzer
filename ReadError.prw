#Include 'Protheus.ch'
#Include 'Totvs.ch'

//-------------------------------------------------------------------
/*/{Protheus.doc} ReadError
Função principal da análise de erros
@author  João Pedro
@since   08/01/2018
@version 1.0
/*/
//-------------------------------------------------------------------
User Function ReadError()

    Local aRet := {} //Necessário para não gerar error.log

    Private aErros := {} //Vetor que irá guardar as linahs do erro quando tivermos lendo o arquivo txt
    Private cRealError := "" //Erro concatenado do arquivo txt
    Private aCutError := {} //Guardara as seções do erro separadas (Erro, hora do LOG_FONTE, nome da maquina)
    Private cLOG_FONTE //Variavel que guardara o nome do LOG_FONTE que deu erro
    Private cLinha //Variavel que guardara a linha que deu erro
    Private cDataFonte //Variavel que guardara a data do LOG_FONTE que deu erro
    Private cFunc //Variavel que guardara o nome da função que deu erro
    Private cErro //Variavel que guardara o erro puro
    Private cPilha := "" //Variavel que irá guardar a pilha de chamadas
    Private cRpo := "" //Guarda o tipo do RPO
    Private cLangRpo //Guarda a LOG_LINGUA do RPO
    Private cExt //Guarda a extensão do ambiente
    Private cSystem //Guarda o sistema operacional que gerou o erro
    Private cLOG_LIB //Guarda a versão da LOG_LIB
    Private cLOG_SERVER //Guarda versão LOG_SERVER
    Private cLOG_BANC //Guarda o LOG_BANC do cliente
    Private cDbversion //Guarda a versão do LOG_BANC do cliente
    Private cLOG_REL //Guarda a LOG_REL do sistema
    Private cLicense //Guarda as informações das licenças
    Private cCadastro := "Análise de Erros" //Título da tela do browse

    DbSelectArea("LOG") //Seleciona a tabela dos erros

    /* Valida se a tabela existe na base de dados */
    If !ValidaTable()
        Return .F.
    Endif

    CriaBrowse() //Cria o browse para abertura

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} ValidaTable
Função que verifica se a tabela de erro existe no LOG_BANC e se não existir cria ela
@author  João Pedro
@since   12/12/2018
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function ValidaTable()

    If TcCanOpen("LOG990")
        Return .T.
    Else
        MsgInfo("Não foi possível localizar a tabela de log em seu ambiente!","Atenção")
        Return .F.
    Endif

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} CriaBrowse
Função que cria o browse para visualização da análise de erro
@author  João Pedro
@since   08/01/2018
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function CriaBrowse()

    Local aCoors := FWGetDialogSize(oMainWnd) //Pega as coordenadas da tela para responsividade
    Local oDlg, oLayer := FWLayer():new() //Cria as camadas para a tela
    Local oPanelUp //Cria o painel onde ficará o browse
    Local oBrowseUp //Objeto que guarda o browse
    Local oTableAtt := TableAttDef() //Variavel necessária para as views e os graphs

    /* Começa a montagem do browse principal */
    DEFINE MSDIALOG oDlg TITLE 'Análise de Erros' FROM aCoors[1], aCoors[2] TO aCoors[3], aCoors[4] PIXEL

    /* Criação do páinel */
    oLayer:Init(oDlg,.F.,.T.) //Cria o painel
    oLayer:AddLine('UP',100,.F.) //Adiciona a linha principal
    oLayer:AddCollumn('ALL',100,.T.,'UP') //Adiciona a coluna principal
    oPanelUp := oLayer:GetColPanel('ALL','UP') //Preenche toda a tela com o painel

    /* Criação do browse */
    oBrowseUp := FWmBrowse():New(oDlg)
    oBrowseUp:SetDataTable() //Seta os dados do browse
    oBrowseUp:SetOwner(oPanelUp) //Seta o owner do browse
    oBrowseUp:SetDescription('Análise de Erros') //Seta a descrição do browse
    oBrowseUp:SetAlias('LOG') //Seta a tabela que será a responsável pelos dados do browse
    oBrowseUp:SetProfileID('1') //Seta a identificação do browse
    oBrowseUp:SetMenuDef('ReadError') //Seta o menu do browse
    oBrowseUp:SetAttach(.T.) //Seta que o browse irá utilizar gráficos e views
    oBrowseUp:SetViewsDefault(oTableAtt:aViews) //Seta as views no browse
    oBrowseUp:SetChartsDefault(oTableAtt:aCharts) //Seta os gráficos no browse
    oBrowseUp:AddLegend("!Empty(LOG->LOG_SOL) .OR. !Empty(LOG->LOG_REFARQ)","Green","Possui Solucao") //Adiciona as legendas ao browse
    oBrowseUp:AddLegend("Empty(LOG->LOG_SOL)","RED","Sem Solucao")
    oBrowseUp:DisableDetails()
    oBrowseUp:ForceQuitButton()
    oBrowseUp:Activate() //Ativa o browse

    oBrowseUp:Refresh()

    ACTIVATE MSDIALOG oDlg CENTERED

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} ManueDef
Função que habilita as opções (Inclusão, Alteração,etc..) no browse
@author  João Pedro
@since   08/01/2018
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function MenuDef()

    Local aRotina := {}

    AADD(aRotina, {'Pesquisar',"AxPesqui",0,1})
    AADD(aRotina, {'Visualizar',"AxVisual",0,2})
    AADD(aRotina, {'Manual',"AxInclui",0,3})
    AADD(aRotina, {'Alterar',"AxAltera",0,4})
    AADD(aRotina, {'Excluir',"AxDeleta",0,5})
    AADD(aRotina, {'Automático',"U_xReadError",0,6})
    AADD(aRotina, {'Legenda',"ErrorLeg",0,7})
    AADD(aRotina, {'Exporta Dados',"U_ExportData",0,8})
    AADD(aRotina, {'Anexos',"U_Anexo",0,9})

Return aRotina

//-------------------------------------------------------------------
/*/{Protheus.doc} ErrorLeg
Função que monta a legenda do browse
@author  João Pedro
@since   08/01/2018
@version 1.0
/*/
//-------------------------------------------------------------------
Function ErrorLeg()

    Local aLegenda := {}

    AADD(aLegenda, {"BR_VERDE", "Possui Solução"})
    AADD(aLegenda, {"BR_VERMELHO", "Sem Solução"})

    BrwLegenda(cCadastro, "Legenda", aLegenda)

Return aLegenda

//-------------------------------------------------------------------
/*/{Protheus.doc} TableAttDef
Função que monta as views e gráficos do browse
@author  João Pedro
@since   08/01/2018
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function TableAttDef()

    Local oFrame := Nil
    Local oEIC := Nil
    Local oEEC := Nil
    Local oEFF := Nil
    Local oEDC := Nil
    Local oESS := Nil
    Local oFIN := Nil
    Local oCOM := Nil
    Local oGen := Nil
    Local oPorFrame := Nil
    Local oTableAtt := FWTableAtt():New()

    oTableAtt:SetAlias("LOG") //Seta a tabela responsável pelos dados

    /* Views */

    oFrame := FWDSView():New()
    oFrame:SetName("Framework") //Nome da view
    oFrame:SetID("Frame") //Identificação da view
    oFrame:SetOrder(1)
    oFrame:SetCollumns({"LOG_ERRO","LOG_FUNC","LOG_FONTE","LOG_SOL"}) //Colunas da view
    oFrame:SetPublic(.T.) //View Publica
    oFrame:AddFilter("Framework","'LIB' $ LOG_FONTE .OR. 'BROWSE' $ LOG_FONTE .OR. 'CFG' $ LOG_FONTE") //Filtro da view
    oTableAtt:AddView(oFrame) //Adiciona view ao browse

    oEIC := FWDSView():New()
    oEIC:SetName("Import")
    oEIC:SetID("Import")
    oEIC:SetOrder(1)
    oEIC:SetCollumns({"LOG_ERRO","LOG_FUNC","LOG_FONTE","LOG_SOL"})
    oEIC:SetPublic(.T.)
    oEIC:AddFilter("Import","'EIC' $ LOG_FONTE")
    oTableAtt:AddView(oEIC)

    oEEC := FWDSView():New()
    oEEC:SetName("Export")
    oEEC:SetID("Export")
    oEEC:SetOrder(1)
    oEEC:SetCollumns({"LOG_ERRO","LOG_FUNC","LOG_FONTE","LOG_SOL"})
    oEEC:SetPublic(.T.)
    oEEC:AddFilter("Export","'EEC' $ LOG_FONTE")
    oTableAtt:AddView(oEEC)

    oEFF := FWDSView():New()
    oEFF:SetName("Financing")
    oEFF:SetID("Financing")
    oEFF:SetOrder(1)
    oEFF:SetCollumns({"LOG_ERRO","LOG_FUNC","LOG_FONTE","LOG_SOL"})
    oEFF:SetPublic(.T.)
    oEFF:AddFilter("Financing","'EFF' $ LOG_FONTE")
    oTableAtt:AddView(oEFF)

    oEDC := FWDSView():New()
    oEDC:SetName("Drawback")
    oEDC:SetID("Drawback")
    oEDC:SetOrder(1)
    oEDC:SetCollumns({"LOG_ERRO","LOG_FUNC","LOG_FONTE","LOG_SOL"})
    oEDC:SetPublic(.T.)
    oEDC:AddFilter("Drawback","'EDC' $ LOG_FONTE")
    oTableAtt:AddView(oEDC)

    oESS := FWDSView():New()
    oESS:SetName("Siscoserv")
    oESS:SetID("Siscoserv")
    oESS:SetOrder(1)
    oESS:SetCollumns({"LOG_ERRO","LOG_FUNC","LOG_FONTE","LOG_SOL"})
    oESS:SetPublic(.T.)
    oESS:AddFilter("Siscoserv","'ESS' $ LOG_FONTE")
    oTableAtt:AddView(oESS)

    oFIN := FWDSView():New()
    oFIN:SetName("Financeiro")
    oFIN:SetID("Financeiro")
    oFIN:SetOrder(1)
    oFIN:SetCollumns({"LOG_ERRO","LOG_FUNC","LOG_FONTE","LOG_SOL"})
    oFIN:SetPublic(.T.)
    oFIN:AddFilter("Financeiro","'FINA' $ LOG_FONTE")
    oTableAtt:AddView(oFIN)

    oCOM := FWDSView():New()
    oCOM:SetName("Compras")
    oCOM:SetID("Compras")
    oCOM:SetOrder(1)
    oCOM:SetCollumns({"LOG_ERRO","LOG_FUNC","LOG_FONTE","LOG_SOL"})
    oCOM:SetPublic(.T.)
    oCOM:AddFilter("Compras","'MATA' $ LOG_FONTE")
    oTableAtt:AddView(oCOM)
    
    oGen := FWDSView():New()
    oGen:SetName("Genéricos")
    oGen:SetID("Genérico")
    oGen:SetOrder(1)
    oGen:SetCollumns({"LOG_ERRO","LOG_FUNC","LOG_FONTE","LOG_SOL"})
    oGen:SetPublic(.T.)
    oGen:AddFilter("Compras","!'MATA' $ LOG_FONTE .AND. !'FINA' $ LOG_FONTE .AND. !'ESS' $ LOG_FONTE .AND. !'EDC' $ LOG_FONTE .AND. !'EFF' $ LOG_FONTE .AND. !'EEC' $ LOG_FONTE .AND. !'EIC' $ LOG_FONTE .AND. !'LIB' $ LOG_FONTE")
    oTableAtt:AddView(oGen)

    /* Gráficos */

    oPorFrame := FWDSChart():New()
    oPorFrame:SetName("Fontes") //Nome da gráfico
    oPorFrame:SetTitle("Fontes") //Titulo do gráfico
    oPorFrame:SetID("PorFrame") //Identificação do gráfico
    oPorFrame:SetType("BARCOMPCHART") //Tipo do gráfico
    oPorFrame:SetSeries({{"LOG","LOG_FONTE","COUNT"}})
    oPorFrame:SetCategory({{"LOG","LOG_FONTE"}})
    oPorFrame:SetPublic( .T. ) //Gráfico público
    oPorFrame:SetLegend( CONTROL_ALIGN_BOTTOM ) //Inferior
    oPorFrame:SetTitleAlign( CONTROL_ALIGN_CENTER ) 
    oTableAtt:AddChart(oPorFrame) //Adiciona gráfico ao browse

Return (oTableAtt)