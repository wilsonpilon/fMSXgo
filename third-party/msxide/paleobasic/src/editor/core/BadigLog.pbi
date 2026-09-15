;
; ------------------------------------------------------------
;  BadigLog.pbi - log de verbosidade compartilhado entre o pre-processador
;  nativo (DignifiedPreprocessor.pbi) e o tokenizador nativo
;  (MsxTokenizer.pbi). Precisa ser incluido (XIncludeFile em BadigEditor.pb)
;  ANTES desses dois arquivos, mesma regra de ordem de declaracao do projeto
;  (ver CLAUDE.md "EnableExplicit + textual inclusion").
;
;  Escala de verbosidade (BadigCfg\VerboseLevel, ver BadigSettings.pbi):
;    0 = silencio, 1 = erros, 2 = alertas, 3 = cabecalhos, 4 = informacao,
;    5 = detalhes. Cada nivel inclui os anteriores (limiar, nao categoria
;    isolada) - mesma logica do Infolog do toolchain Python de referencia
;    (basic-dignified/support/helper.py).
; ------------------------------------------------------------
;

EnableExplicit

#BadigLog_Error   = 1
#BadigLog_Warning = 2
#BadigLog_Header  = 3
#BadigLog_Info    = 4
#BadigLog_Detail  = 5

Structure BadigLogEntry
  Level.i
  LineNum.i   ; 0 = sem linha de origem associada
  Msg.s
EndStructure

Global NewList BadigLog_Entries.BadigLogEntry()

Procedure BadigLog_Reset()
  ClearList(BadigLog_Entries())
EndProcedure

Procedure BadigLog_Add(Level.i, LineNum.i, Msg.s)
  AddElement(BadigLog_Entries())
  BadigLog_Entries()\Level = Level
  BadigLog_Entries()\LineNum = LineNum
  BadigLog_Entries()\Msg = Msg
EndProcedure

; Monta o texto exibido na janela de saida (BadigOutputGui.pbi) a partir das
; entradas acumuladas (pre-processador + tokenizador, na ordem em que
; aconteceram). MaxLevel = nivel configurado (0-5, filtro por limiar).
; ForceShowErrors = mesmo com MaxLevel < 1 (silencio), garante que o erro
; fatal ainda apareca - nunca deixar o usuario numa janela vazia depois de
; uma compilacao que falhou (ver plano/adaptacao: o Python original suprime
; ate o erro no nivel 0, aceitavel numa CLI, nao num IDE interativo).
Procedure.s BadigLog_Render(MaxLevel.i, ForceShowErrors.b = #False)
  Protected Dim Bullets.s(5)
  Bullets(1) = "*** "   ; erro
  Bullets(2) = "  * "   ; alerta
  Bullets(3) = "--- "   ; cabecalho
  Bullets(4) = "  - "   ; informacao
  Bullets(5) = "    "   ; detalhe

  Protected Result.s = ""
  ForEach BadigLog_Entries()
    Protected Show.b = Bool(BadigLog_Entries()\Level <= MaxLevel)
    If Not Show And ForceShowErrors And BadigLog_Entries()\Level = #BadigLog_Error
      Show = #True
    EndIf
    If Show
      If Result <> "" : Result + Chr(13) + Chr(10) : EndIf
      Protected Pos.s = ""
      If BadigLog_Entries()\LineNum > 0
        Pos = "Linha " + Str(BadigLog_Entries()\LineNum) + ": "
      EndIf
      Result + Bullets(BadigLog_Entries()\Level) + Pos + BadigLog_Entries()\Msg
    EndIf
  Next
  ProcedureReturn Result
EndProcedure
