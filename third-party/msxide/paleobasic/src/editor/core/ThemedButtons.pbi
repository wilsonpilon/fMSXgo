;
; ------------------------------------------------------------
;  Botoes tematizados - ButtonGadget nativo do Windows ignora Color_* (chrome
;  do SO, nao da pra recolorir), entao qualquer janela que queira seguir o
;  tema (ver ApplyTheme() em BadigEditor.pb) desenha seus botoes na hora
;  (retangulo + borda + texto ou icone) e mostra via ButtonImageGadget, em
;  vez de ButtonGadget puro. Nasceu no Editor Hexa (HexEditorGui.pbi,
;  v7.31.3) e foi generalizado pra este arquivo pra qualquer outra janela
;  reusar - ver Macro ThemedButton() mais abaixo.
;
;  Custo aceito: sem feedback nativo de hover/pressionado (mesma troca ja
;  usada nos botoes de icone de CharsetEditorGui.pbi).
;
;  Icones sao opcionais e so aparecem se EditorCfg\IconFontName estiver
;  configurado (Configurar -> Editor... -> "Fonte de icones") com uma Nerd
;  Font de verdade - glifos de icone vivem em codepoints da Private Use Area
;  do Unicode, uma fonte comum nao tem esses desenhos "remendados". Sem fonte
;  de icones escolhida (padrao), todo ThemedButton cai pro texto normal,
;  nada quebra.
; ------------------------------------------------------------
;

; Codepoints Nerd Fonts (fa-* = Font Awesome, cod-* = Codicons, ambos
; incluidos em qualquer Nerd Font) conferidos ao vivo contra o
; glyphnames.json oficial (github.com/ryanoasis/nerd-fonts, v3.5.0) antes de
; usar - um codepoint errado mostra o quadradinho de "glifo ausente" ou o
; icone errado, entao nao vale chutar de memoria aqui. So cobre acoes
; universalmente reconheciveis (abrir/salvar/fechar/copiar/tocar/etc.) -
; acoes bem especificas de um modulo (ex.: "Gerar codigo PLAY", "Gravar
; disco MSX") ficam de proposito so com texto, um icone generico ali
; confundiria mais do que ajudaria.
#Icon_Open      = $F07C ; fa-folder_open
#Icon_Save      = $F0C7 ; fa-save (= fa-floppy_disk)
#Icon_SaveAs    = $EB4A ; cod-save_as
#Icon_Gallery   = $F00F ; fa-images
#Icon_Flag      = $F024 ; fa-flag (marcar inicio/area)
#Icon_Bookmark  = $F02E ; fa-bookmark (marcar fim)
#Icon_Clear     = $F12D ; fa-eraser
#Icon_Fill      = $EE3F ; fa-fill_drip
#Icon_Insert    = $F0FE ; fa-plus_square
#Icon_Overwrite = $F040 ; fa-pencil
#Icon_Delete    = $F1F8 ; fa-trash
#Icon_Check     = $F00C ; fa-check (aplicar/ok)
#Icon_Close     = $F00D ; fa-close (= fa-times)
#Icon_Add       = $F067 ; fa-plus
#Icon_Remove    = $F068 ; fa-minus
#Icon_Copy      = $F0C5 ; fa-copy
#Icon_Cut       = $F0C4 ; fa-cut
#Icon_Refresh   = $F021 ; fa-refresh (reset/recarregar/reiniciar)
#Icon_Play      = $F04B ; fa-play
#Icon_Stop      = $F04D ; fa-stop
#Icon_Eject     = $F052 ; fa-eject
#Icon_Code      = $F121 ; fa-code
#Icon_Plug      = $F1E6 ; fa-plug (conectar)
#Icon_Unplug    = $F127 ; fa-unlink (desconectar)
#Icon_Mute      = $F026 ; fa-volume_off
#Icon_Hammer    = $EEFF ; fa-hammer (montar/build)
#Icon_Link      = $F0C1 ; fa-link (linkar)
#Icon_Import    = $EE38 ; fa-file_import
#Icon_Export    = $EE37 ; fa-file_export
#Icon_Eye       = $F06E ; fa-eye (mostrar janela)
#Icon_ArrowUp   = $F062 ; fa-arrow_up
#Icon_ArrowDown = $F063 ; fa-arrow_down
#Icon_ArrowLeft = $F060 ; fa-arrow_left (voltar)
#Icon_Search    = $F002 ; fa-search

Global ThemedUI_ButtonFont.i = 0
Global ThemedUI_IconFont.i = 0
Global ThemedUI_IconFontTried.b = #False

; Clareia (Delta > 0) ou escurece (Delta < 0) uma cor, com clamp em 0..255 -
; usado pra derivar a borda do botao a partir do proprio fundo do tema, sem
; depender de qual variavel Color_* por acaso e mais clara/escura em cada
; uma das 7 paletas.
Procedure.i ThemedUI_ShadeColor(Col, Delta)
  Protected R = Red(Col) + Delta
  Protected G = Green(Col) + Delta
  Protected B = Blue(Col) + Delta
  If R < 0 : R = 0 : ElseIf R > 255 : R = 255 : EndIf
  If G < 0 : G = 0 : ElseIf G > 255 : G = 255 : EndIf
  If B < 0 : B = 0 : ElseIf B > 255 : B = 255 : EndIf
  ProcedureReturn RGB(R, G, B)
EndProcedure

; Tenta carregar a fonte de icones uma unica vez por sessao (cache no Global
; acima) - devolve 0 se IconsEnabled = #False ou se o LoadFont falhar (nome
; invalido/fonte nao encontrada), caso em que o chamador cai pro texto normal.
; EditorCfg\IconFontName vazio = usa #EdFont_BundledIconFontName (a Nerd Font
; empacotada em editor/fonts/, registrada em memoria por
; EditorCfg_LoadCustomFonts() antes desta funcao ser chamada pela primeira
; vez) - so um nome explicito em IconFontName troca pra outra fonte instalada.
Procedure.i ThemedUI_GetIconFont()
  If Not ThemedUI_IconFontTried
    ThemedUI_IconFontTried = #True
    If EditorCfg\IconsEnabled
      Protected IconFontToUse.s = EditorCfg\IconFontName
      If IconFontToUse = ""
        IconFontToUse = #EdFont_BundledIconFontName
      EndIf
      ThemedUI_IconFont = LoadFont(#PB_Any, IconFontToUse, 14)
    EndIf
  EndIf
  ProcedureReturn ThemedUI_IconFont
EndProcedure

; IconChar = um caractere so (ex.: Chr(#Icon_Save)) de um codepoint da tabela
; acima. "" = sem icone mapeado pra esse botao, sempre cai pro texto
; (independente de ter fonte de icones configurada ou nao).
Procedure.i ThemedUI_CreateButtonImage(W.i, H.i, Text.s, IconChar.s = "")
  If Not ThemedUI_ButtonFont
    ThemedUI_ButtonFont = LoadFont(#PB_Any, EditorCfg\FontName, 9)
  EndIf

  Protected Border = ThemedUI_ShadeColor(Color_TabInactive, -40)
  Protected Img = CreateImage(#PB_Any, W, H, 24, Color_TabInactive)
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, W, H, Color_TabInactive)
    Box(0, 0, W, 1, Border)
    Box(0, H - 1, W, 1, Border)
    Box(0, 0, 1, H, Border)
    Box(W - 1, 0, 1, H, Border)

    Protected UseIcon = Bool(IconChar <> "" And ThemedUI_GetIconFont())
    If UseIcon
      DrawingFont(FontID(ThemedUI_IconFont))
      Protected IW = TextWidth(IconChar), IH = TextHeight(IconChar)
      DrawText((W - IW) / 2, (H - IH) / 2, IconChar, Color_TextActive, Color_TabInactive)
    Else
      DrawingFont(FontID(ThemedUI_ButtonFont))
      Protected TW = TextWidth(Text), TH = TextHeight(Text)
      DrawText((W - TW) / 2, (H - TH) / 2, Text, Color_TextActive, Color_TabInactive)
    EndIf
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Uso: Protected G_X = ThemedButton(X, Y, W, H, "Rotulo", Chr(#Icon_Algo))
; Sem icone mapeado, passe "" no ultimo argumento.
Macro ThemedButton(X, Y, W, H, Text, Icon)
  ButtonImageGadget(#PB_Any, X, Y, W, H, ImageID(ThemedUI_CreateButtonImage(W, H, Text, Icon)))
EndMacro
