;
; ------------------------------------------------------------
;  Ajuda -> Basic Dignified...: base de dados dos guias de usuario ja
;  existentes em docs/*.md (BADIG-USER.md, BATOKEN-USER.md,
;  DIGNIFIER-USER.md) - a documentacao da propria linguagem/ferramenta
;  Dignified, nao do MSX BASIC classico (que ja tem seu proprio Ajuda ->
;  MSX BASIC). Mesma ideia de MsxBasicManualData.pbi: topico livre
;  (Titulo/Modulo/Corpo), renderizado com o mesmo mini-Markdown ja usado
;  em NestorBasicHelpGui.pbi ("## " subtitulo, "**negrito**", `codigo`).
;
;  Cada arquivo .md fonte vira um "Modulo" (grupo na arvore); cada secao
;  "##"/"###" do .md vira um topico (achatado - so um nivel de
;  agrupamento, o Modulo, dentro da arvore). Tabelas do markdown original
;  viram listas "- item" (o mini-Markdown daqui nao tem suporte a
;  tabelas de verdade); blocos de codigo cercados por ``` viram texto
;  simples (sem estilo de "bloco de codigo" dedicado, so paragrafos).
; ------------------------------------------------------------
;

Structure MSXDignifiedTopic
  Titulo.s     ; ex "Rotulos (Labels)"
  Modulo.s     ; ex "Basic Dignified" - vira o grupo na arvore
  Corpo.s      ; texto (mini-markdown: "- " bullets, #CRLF$ paragrafos, `code`, **bold**)
  Fonte.s      ; nome do arquivo .md de origem, so pra referencia
EndStructure

Global NewList MSXDignified_Topics.MSXDignifiedTopic()

Procedure MSXDignified_Add(Titulo.s, Modulo.s, Corpo.s, Fonte.s)
  AddElement(MSXDignified_Topics())
  MSXDignified_Topics()\Titulo = Titulo
  MSXDignified_Topics()\Modulo = Modulo
  MSXDignified_Topics()\Corpo = Corpo
  MSXDignified_Topics()\Fonte = Fonte
EndProcedure

Procedure.s MSXDignified_SearchKey(*Topico.MSXDignifiedTopic)
  ProcedureReturn LCase(*Topico\Titulo + " " + *Topico\Modulo)
EndProcedure

Procedure.s MSXDignified_FullBody(*Topico.MSXDignifiedTopic)
  ProcedureReturn "## " + *Topico\Titulo + #CRLF$ + #CRLF$ +
                  *Topico\Modulo + " (" + *Topico\Fonte + ")" + #CRLF$ + #CRLF$ +
                  *Topico\Corpo
EndProcedure

Declare MSXDignified_BuildBadig()
Declare MSXDignified_BuildBatoken()
Declare MSXDignified_BuildDignifier()

Procedure MSXDignified_BuildData()
  If ListSize(MSXDignified_Topics()) > 0
    ProcedureReturn ; ja construido - so monta uma vez por sessao
  EndIf

  MSXDignified_BuildBadig()
  MSXDignified_BuildBatoken()
  MSXDignified_BuildDignifier()
EndProcedure
