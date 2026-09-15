;
; ------------------------------------------------------------
;  Buscar / Substituir / Ir para linha - atalhos padrao (Ctrl+F, F3, Ctrl+H,
;  Ctrl+G), sem depender de nenhum mecanismo de teclado proprio: so fala com
;  o Scintilla via ScintillaSendMessage, portavel em qualquer OS.
;
;  Incluido so no fim de BadigEditor.pb (nao junto com os demais XIncludeFile
;  no topo) porque usa ActiveSciGadget(), definido ao longo deste arquivo -
;  ver Declare de Editor_Find/Editor_FindNext/Editor_Replace/Editor_GotoLine
;  perto do topo para as chamadas a partir do menu, que vem antes textualmente.
; ------------------------------------------------------------
;

; Ultimo texto buscado (Ctrl+F), reaproveitado por F3 (buscar proximo).
Global EditorSearch_LastText.s = ""

; Busca (sem diferenciar maiusculas/minusculas) a partir de FromPos, com
; wraparound para o inicio do documento se nao achar dali em diante.
Procedure.b EditorSearch_SearchFrom(Sci, SearchText.s, FromPos)
  Protected TextLen = ScintillaSendMessage(Sci, #SCI_GETTEXTLENGTH)
  ScintillaSendMessage(Sci, #SCI_SETSEARCHFLAGS, 0)

  Protected *Buf = UTF8(SearchText)
  Protected ByteLen = StringByteLength(SearchText, #PB_UTF8)

  ScintillaSendMessage(Sci, #SCI_SETTARGETSTART, FromPos)
  ScintillaSendMessage(Sci, #SCI_SETTARGETEND, TextLen)
  Protected FoundPos = ScintillaSendMessage(Sci, #SCI_SEARCHINTARGET, ByteLen, *Buf)

  If FoundPos < 0
    ScintillaSendMessage(Sci, #SCI_SETTARGETSTART, 0)
    ScintillaSendMessage(Sci, #SCI_SETTARGETEND, FromPos)
    FoundPos = ScintillaSendMessage(Sci, #SCI_SEARCHINTARGET, ByteLen, *Buf)
  EndIf
  FreeMemory(*Buf)

  If FoundPos < 0
    ProcedureReturn #False
  EndIf

  Protected TargetEnd = ScintillaSendMessage(Sci, #SCI_GETTARGETEND)
  ScintillaSendMessage(Sci, #SCI_SETSEL, FoundPos, TargetEnd)
  ScintillaSendMessage(Sci, #SCI_SCROLLCARET)
  ProcedureReturn #True
EndProcedure

Procedure Editor_Find()
  Protected Sci = ActiveSciGadget()
  If Not Sci : ProcedureReturn : EndIf

  Protected Query.s = InputRequester("Buscar (Ctrl+F)", "Texto a buscar:", EditorSearch_LastText, 0, WindowID(#MainWindow))
  If Query = ""
    ProcedureReturn
  EndIf

  EditorSearch_LastText = Query
  If Not EditorSearch_SearchFrom(Sci, Query, ScintillaSendMessage(Sci, #SCI_GETCURRENTPOS))
    MessageRequester("Buscar", "Texto nao encontrado: " + Query, #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
  EndIf
EndProcedure

Procedure Editor_FindNext()
  Protected Sci = ActiveSciGadget()
  If Not Sci Or EditorSearch_LastText = ""
    ProcedureReturn
  EndIf
  If Not EditorSearch_SearchFrom(Sci, EditorSearch_LastText, ScintillaSendMessage(Sci, #SCI_GETCURRENTPOS) + 1)
    MessageRequester("Buscar", "Texto nao encontrado: " + EditorSearch_LastText, #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
  EndIf
EndProcedure

; Busca a partir de FromPos ATE O FIM do documento, sem wraparound - usado por
; substituir (tudo/uma-a-uma), que precisam de uma condicao de parada garantida.
; Em caso de sucesso, o alvo (#SCI_GETTARGETSTART/END) fica apontando pro
; trecho achado.
Procedure.i EditorSearch_SearchForwardNoWrap(Sci, SearchText.s, FromPos)
  Protected TextLen = ScintillaSendMessage(Sci, #SCI_GETTEXTLENGTH)
  If FromPos > TextLen
    ProcedureReturn -1
  EndIf
  ScintillaSendMessage(Sci, #SCI_SETSEARCHFLAGS, 0)
  Protected *Buf = UTF8(SearchText)
  Protected ByteLen = StringByteLength(SearchText, #PB_UTF8)
  ScintillaSendMessage(Sci, #SCI_SETTARGETSTART, FromPos)
  ScintillaSendMessage(Sci, #SCI_SETTARGETEND, TextLen)
  Protected FoundPos = ScintillaSendMessage(Sci, #SCI_SEARCHINTARGET, ByteLen, *Buf)
  FreeMemory(*Buf)
  ProcedureReturn FoundPos
EndProcedure

; Substitui todas as ocorrencias sem perguntar. Pos avanca sempre para
; FoundPos+ReplaceByteLen (mesmo quando ReplaceText = "" e Pos fica parado em
; FoundPos) - nao trava porque o texto encontrado ja foi removido dali, entao
; o documento so encolhe a cada volta, garantindo que o laco termina.
Procedure.i EditorSearch_ReplaceAll(Sci, SearchText.s, ReplaceText.s)
  Protected Count = 0
  Protected *ReplaceBuf = UTF8(ReplaceText)
  Protected ReplaceByteLen = StringByteLength(ReplaceText, #PB_UTF8)
  Protected Pos = 0, FoundPos

  Repeat
    FoundPos = EditorSearch_SearchForwardNoWrap(Sci, SearchText, Pos)
    If FoundPos < 0 : Break : EndIf
    ScintillaSendMessage(Sci, #SCI_REPLACETARGET, ReplaceByteLen, *ReplaceBuf)
    Count + 1
    Pos = FoundPos + ReplaceByteLen
  ForEver

  FreeMemory(*ReplaceBuf)
  ProcedureReturn Count
EndProcedure

; Confirma ocorrencia por ocorrencia (Sim substitui e avanca, Nao pula para a
; proxima, Cancelar para o laco inteiro).
Procedure.i EditorSearch_ReplaceInteractive(Sci, SearchText.s, ReplaceText.s)
  Protected *ReplaceBuf = UTF8(ReplaceText)
  Protected ReplaceByteLen = StringByteLength(ReplaceText, #PB_UTF8)
  Protected SearchByteLen = StringByteLength(SearchText, #PB_UTF8)
  Protected Pos = 0, FoundPos, Count = 0, Answer

  Repeat
    FoundPos = EditorSearch_SearchForwardNoWrap(Sci, SearchText, Pos)
    If FoundPos < 0 : Break : EndIf

    Protected TargetEnd = ScintillaSendMessage(Sci, #SCI_GETTARGETEND)
    ScintillaSendMessage(Sci, #SCI_SETSEL, FoundPos, TargetEnd)
    ScintillaSendMessage(Sci, #SCI_SCROLLCARET)

    Answer = MessageRequester("Substituir (Ctrl+H)", "Substituir esta ocorrencia?",
                               #PB_MessageRequester_YesNoCancel | #PB_MessageRequester_Info)
    If Answer = #PB_MessageRequester_Cancel : Break : EndIf

    If Answer = #PB_MessageRequester_Yes
      ScintillaSendMessage(Sci, #SCI_SETTARGETSTART, FoundPos)
      ScintillaSendMessage(Sci, #SCI_SETTARGETEND, TargetEnd)
      ScintillaSendMessage(Sci, #SCI_REPLACETARGET, ReplaceByteLen, *ReplaceBuf)
      Count + 1
      Pos = FoundPos + ReplaceByteLen
    Else
      Pos = FoundPos + SearchByteLen
    EndIf
  ForEver

  FreeMemory(*ReplaceBuf)
  ProcedureReturn Count
EndProcedure

Procedure Editor_Replace()
  Protected Sci = ActiveSciGadget()
  If Not Sci : ProcedureReturn : EndIf

  Protected SearchText.s = InputRequester("Substituir (Ctrl+H)", "Buscar:", EditorSearch_LastText, 0, WindowID(#MainWindow))
  If SearchText = ""
    ProcedureReturn
  EndIf
  EditorSearch_LastText = SearchText

  ; ReplaceText = "" tanto faz dizer "substituir por nada" quanto "cancelou o
  ; requester" - nao da pra distinguir os dois casos (InputRequester devolve
  ; "" nos dois). Tratado como "substituir por nada"; o passo de confirmacao
  ; logo abaixo (Sim/Nao/Cancelar) da uma chance de desistir se nao era essa
  ; a intencao.
  Protected ReplaceText.s = InputRequester("Substituir (Ctrl+H)", "Substituir por:", "", 0, WindowID(#MainWindow))

  Protected Answer = MessageRequester("Substituir (Ctrl+H)",
    "Substituir TODAS as ocorrencias sem perguntar?" + Chr(10) + "(Nao = confirmar uma por uma)",
    #PB_MessageRequester_YesNoCancel | #PB_MessageRequester_Info)
  If Answer = #PB_MessageRequester_Cancel
    ProcedureReturn
  EndIf

  Protected Count
  If Answer = #PB_MessageRequester_Yes
    Count = EditorSearch_ReplaceAll(Sci, SearchText, ReplaceText)
  Else
    Count = EditorSearch_ReplaceInteractive(Sci, SearchText, ReplaceText)
  EndIf

  MessageRequester("Substituir", Str(Count) + " ocorrencia(s) substituida(s).", #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
EndProcedure

Procedure Editor_GotoLine()
  Protected Sci = ActiveSciGadget()
  If Not Sci : ProcedureReturn : EndIf

  Protected NumLines = ScintillaSendMessage(Sci, #SCI_GETLINECOUNT)
  Protected CurLine = ScintillaSendMessage(Sci, #SCI_LINEFROMPOSITION, ScintillaSendMessage(Sci, #SCI_GETCURRENTPOS)) + 1
  Protected Answer.s = InputRequester("Ir para linha (Ctrl+G)", "Numero da linha (1-" + Str(NumLines) + "):", Str(CurLine), 0, WindowID(#MainWindow))
  If Answer = ""
    ProcedureReturn
  EndIf

  Protected LineNum = Val(Answer)
  If LineNum < 1 : LineNum = 1 : EndIf
  If LineNum > NumLines : LineNum = NumLines : EndIf

  ScintillaSendMessage(Sci, #SCI_GOTOLINE, LineNum - 1)
EndProcedure
