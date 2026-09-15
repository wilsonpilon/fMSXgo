# Editor do msxIDE

Referência rápida dos comandos e atalhos do editor de texto do msxIDE - movimentação, seleção,
área de transferência, desfazer/refazer, localizar/substituir, janelas e ajuda contextual. Os atalhos
de edição (seleção, copiar/recortar/colar, desfazer/refazer, localizar/substituir e a navegação por
palavra/parágrafo/tela) seguem a mesma lógica de teclado do Microsoft Edit/VS Code - se você já usa um
desses, já sabe usar o editor de textos do msxIDE.

## Teclas de função

- `F1` - abre o menu Ajuda.
- `Shift+F1` - Dicionário MSX BASIC: abre o verbete do comando sob o cursor (ou o índice, se o cursor
  não estiver sobre uma palavra reconhecida). Pressionar de novo enquanto o verbete está aberto volta
  para o documento anterior.
- `F2` - Salvar o documento ativo.
- `F3` - Abrir arquivo...
- `F4` - Novo (Basic Dignified).
- `F5` - Fechar o documento ativo.
- `F6` - Janela: alterna para a próxima janela aberta.
- `F7` - (documentos `.md`) alterna o modo de visualização: Edição simples -> Dividido -> Somente
  leitura -> Edição simples...
- `F8` - abre o menu Compilar.
- `F9` - abre o menu Configurar.
- `F10` - abre o menu Arquivo.
- `Ctrl+L` - abre direto o log de compilação, sem passar pelo menu.
- `Esc` - fecha um menu ou diálogo aberto; se nada estiver aberto, sai do msxIDE.

## Movimentação do cursor

- Setas - move o cursor uma célula/linha por vez.
- `Ctrl+Seta esquerda` / `Ctrl+Seta direita` - anda uma palavra por vez.
- `Ctrl+Seta cima` / `Ctrl+Seta baixo` - anda um parágrafo por vez (pula pro próximo bloco separado
  por linha em branco).
- `Home` / `End` - vai para o início/fim da linha atual.
- `Ctrl+Home` / `Ctrl+End` - vai para o início/fim do documento inteiro.
- `PgUp` / `PgDn` - rola uma tela inteira para cima/baixo (mantém a coluna quando possível).
- `Ctrl+PgUp` / `Ctrl+PgDn` - rola meia tela para cima/baixo.
- Roda do mouse - rola o texto verticalmente, tanto na tela de edição quanto nas telas de ajuda.

## Indentação

- `Tab` - insere a quantidade de espaços configurada em `Configurar -> Editor -> Indent Size`
  (padrão: 4). Com uma seleção ativa, substitui o texto selecionado, igual a digitar qualquer
  outro caractere.

## Caracteres especiais MSX

`Inserir -> Caracteres Especiais MSX` (`Alt+I`, depois `C`) abre uma grade com os caracteres
especiais do conjunto MSX, o mesmo conjunto que o "Translate" do Basic Dignified Suite reconhece
(`badig_msx.py`, `Parser.trans_char`):

- **Acentos e gráficos (códigos 128-255)** - o byte escolhido é inserido direto no cursor e sai
  idêntico no `.amx` gerado, sem nenhuma tradução no compilador (o pipeline inteiro é byte a byte,
  nunca passa por UTF-8) - imprime certo com um `PRINT` normal no MSX de verdade.
- **Símbolos especiais (`CHR$(1)` a `CHR$(31)`)** - carinha, naipes, blocos, etc. Esses códigos
  baixos não são imprimíveis de forma confiável dentro de uma string/`PRINT` no MSX BASIC clássico,
  então - exatamente como o Basic Dignified Suite faz - a grade insere a **letra equivalente**
  (`A`-`Z`, `[`, `]`, `\`, `^`, `_`) no lugar do byte cru, como um fallback seguro.

Dentro da grade: setas navegam, `Enter` insere o caractere/letra selecionado no cursor (sem fechar
o diálogo - dá pra inserir vários seguidos), `Esc` fecha.

## Seleção de texto

- `Shift` + qualquer tecla de movimentação acima (setas, `Home`/`End`, `Ctrl+Seta`, `Ctrl+Home`/
  `Ctrl+End`, `PgUp`/`PgDn`) estende a seleção naquela mesma granularidade - célula, palavra,
  linha, parágrafo, tela inteira ou documento inteiro.
- `Ctrl+A` - seleciona o documento inteiro.
- Qualquer tecla de movimentação **sem** `Shift` cancela a seleção atual e move o cursor normalmente.
- Digitar um caractere, `Enter`, `Backspace` ou `Delete` com uma seleção ativa substitui/apaga o texto
  selecionado.
- O texto selecionado aparece destacado com fundo azul.

## Área de transferência (copiar/recortar/colar)

- `Ctrl+C` (ou `Ctrl+Insert`) - copia a seleção atual. Sem seleção, copia a linha inteira onde está
  o cursor.
- `Ctrl+X` (ou `Shift+Delete`) - recorta a seleção atual. Sem seleção, recorta a linha inteira onde
  está o cursor.
- `Ctrl+V` (ou `Shift+Insert`) - cola o conteúdo da área de transferência na posição do cursor
  (substitui a seleção atual, se houver).
- `Ctrl+Insert`/`Shift+Insert`/`Shift+Delete` são o trio clássico de copiar/colar/recortar dos
  editores MS-DOS de antes do `Ctrl+C`/`Ctrl+X`/`Ctrl+V` (QEdit, Norton Editor, Brief...) - funcionam
  exatamente como os atalhos modernos, é só outra forma de chegar no mesmo lugar.
- A área de transferência é a mesma do Windows (`Ctrl+C`/`Ctrl+X` no msxIDE também ficam disponíveis
  pra colar em qualquer outro programa, e `Ctrl+V` no msxIDE cola o que foi copiado em qualquer outro
  programa) - além de, claro, funcionar entre documentos abertos dentro do próprio msxIDE.

## Desfazer/refazer

- `Ctrl+Z` - desfaz a última alteração.
- `Ctrl+Y` - refaz a alteração desfeita.
- Uma sequência de caracteres digitados (ou apagados) em seguida vira um único passo de desfazer -
  não precisa apertar `Ctrl+Z` uma vez por letra.
- O histórico é por documento (guarda até 40 passos) e some quando o documento é fechado.

## Localizar/substituir

- `Ctrl+F` - abre a caixa **Localizar**. Digite o texto e `Enter` confirma; o cursor pula para a
  próxima ocorrência a partir da posição atual (dá a volta pro início do documento se não achar antes
  do fim). Repita `Ctrl+F` (o campo já vem preenchido com a última busca) para achar a próxima.
- `Ctrl+H` - abre **Substituir**: primeiro pede o texto a localizar, depois o texto para substituir.
  A partir daí, cada ocorrência encontrada (varrendo do cursor até o fim do documento, sem dar a
  volta - use `Ctrl+Home` antes para substituir o documento inteiro) pergunta na barra inferior:
  `[S]im` substitui e avança, `[N]ão` pula sem mexer, `[T]odas` substitui essa e todas as próximas
  sem perguntar de novo, `Esc` cancela a sessão. A sessão inteira desfaz de uma vez só com `Ctrl+Z`.
- Busca não diferencia maiúsculas/minúsculas.

## Edição de texto

- Digitar um caractere imprimível insere no cursor (ou substitui a seleção ativa).
- `Enter` - insere uma nova linha (nos documentos de ajuda/dicionário, em vez disso abre o link ou
  verbete sob o cursor).
- `Backspace` - apaga o caractere antes do cursor (ou a seleção ativa).
- `Delete` - apaga o caractere sob o cursor (ou a seleção ativa).

## Janelas (mouse)

Cada documento aberto vive na sua própria janela, ao estilo MDI:

- Clicar e arrastar a barra de título move a janela.
- Clicar o quadradinho `[.]` no canto superior esquerdo da barra de título fecha a janela.
- Clicar a seta no canto superior direito maximiza/restaura a janela.
- Arrastar o "grip" no canto inferior direito redimensiona a janela.
- Clicar ou arrastar as barras de rolagem vertical/horizontal move a posição de leitura.
- `F6` cicla entre as janelas abertas sem precisar do mouse.

## Ajuda contextual

- `Shift+F1` sobre uma palavra do editor abre o verbete correspondente no Dicionário MSX BASIC
  (`Ajuda -> MSX BASIC Dictionary`), se reconhecida.
- Dentro de uma tela de ajuda, clique ou `Enter` sobre uma entrada do índice, um tópico ou um link
  ("Ver também") navega até o alvo.
- `Shift+F1` dentro de uma tela de ajuda volta para o documento de onde a consulta foi aberta.

## Menus

A barra de menu no topo tem sete itens: **Arquivo** (novo/abrir/salvar/projeto), **Configurar**
(Basic Dignified/MSX Basic/Emulador/Mamute (Memória)/Impressora/Editor), **Compilar**, **Referência** (Red Book, manuais MSX, BIOS,
openMSX, etc.), **Mamute** (abre o terminal do Mamute Assembler), **Ajuda** (documentação do msxIDE
e dos dialetos suportados) e **Inserir** (caracteres especiais MSX).

Formas de abrir cada menu:

- Clique no nome do menu na barra do topo.
- Tecla de função: `F10` (Arquivo), `F9` (Configurar), `F8` (Compilar), `F1` (Ajuda).
- Letra de acesso rápido (`Alt+letra`, funciona pra todos os sete, inclusive Referência e Mamute, que
  até então só abriam com o mouse): `Alt+A` Arquivo, `Alt+O` Configurar, `Alt+C` Compilar, `Alt+R`
  Referência, `Alt+M` Mamute, `Alt+J` Ajuda, `Alt+I` Inserir.

Com um menu aberto:

- `Seta esquerda` / `Seta direita` - troca pro menu anterior/seguinte da barra do topo.
- `Seta cima` / `Seta baixo` - move o destaque entre os itens do menu aberto (dá a volta no topo/fim).
- `Enter` - confirma o item em destaque.
- Letra do item (ex.: `N` para "Novo Basic Dignified" no menu Arquivo) - atalho direto, sem precisar
  navegar com as setas.
- `Esc` - fecha o menu aberto (sem nenhum menu aberto, `Esc` sai do msxIDE).
