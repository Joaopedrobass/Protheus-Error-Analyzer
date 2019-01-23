# Protheus-Error-Analyzer
Projeto para criação de um banco de dados com os error.log gerados pelo Protheus, assim como suas devidas soluções

<h2>Arquivos de Dicionário</h2>

<p>Estou enviando o SX2 (Dados da tabela), SX3 (Dados do Campo) e SIX (Indíces da tabela) filtrados pela tabela LOG, peço para que realize o Append dos mesmos em suas respectivas APSDU.</p>

<h2>Patch</h2>

<p>Realize a aplicação do mesmo através do Developer Studio (TDS) ou pelo DevStudio (Antigo)</p>

<h2>Fontes</h2>

<p>Qualquer dúvida referente ao código ou ao funcionamento da rotina, consulte os mesmos.</p>

<p>P.S: Será necessário incluir o primeiro erro manualmente, visto que o Protheus não deixa incluir o mesmo automaticamente na primeira tentativa (Isso é uma limitação do Framework e não da rotina em si)</p>


<h2>ALGUMAS FUNCIONALIDADES DA FERRAMENTA:</h2>

<p>Incluir, alterar, visualizar e excluir erros</p>
<p>Separação automática dos dados do error.log (Outras ações -> Automático), onde é possível selecionar qualquer arquivo de erro com extensão .txt ou .log</p>
<p>Visualização de Erros x Fontes através de gráficos em formas de Funil, Pizza ou Torres (Posicionar o mouse no lado direito do browse e clicar na flechinha que irá aparecer)</p>
<p>Visualização de views de erros por produtos (Clicar na opção “Exibir Todos” no topo do browse), onde será possível selecionar os produtos (EIC, EEC, Compras, etc..). OBS.: Qualquer fonte que não se enquadre a produtos ou que sejam disponíveis para vários produtos serão englobadas na view “Genéricos”</p>
<p>Exportação dos dados do erro para Excel e TXT</p>
<p>Anexar dados como solução para os erros (Neste caso o arquivo será gravado na pasta System do servidor (Em nosso caso na pasta System local do seu ambiente), gravando o caminho em um campo para guardar a referencia)</p>
<p>Analisar logs gerados pela rotina de transmissão da DU-E e verificar se o java e o .jar de integração estão atualizados</p>
