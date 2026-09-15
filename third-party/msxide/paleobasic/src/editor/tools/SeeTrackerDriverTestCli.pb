;
; ------------------------------------------------------------
;  SeeTrackerDriverTestCli.pb - harness headless (sem GUI) do driver de
;  replay Z80 nativo do SEE Tracker (SeeTrackerDriverAsm.pbi), montado via
;  o assembler nativo desta IDE (Z80Asm.pbi). Confirma que a fonte portada
;  assembla sem erro e imprime os enderecos dos vetores/variaveis chave,
;  pra conferencia manual contra o comentario de topo de
;  SeeTrackerDriverAsm.pbi (tabela de vetores) antes de usar em produto.
;
;  Compilar:
;  "C:\Basic\Compilers\pbcompiler.exe" editor\tools\SeeTrackerDriverTestCli.pb /EXE editor\tools\SeeTrackerDriverTestCli.exe /CONSOLE
;
;  Uso: SeeTrackerDriverTestCli.exe [saida.bin]
;       Sem argumento so monta e reporta; com argumento tambem grava o
;       binario cru (util pra inspecionar com o Editor Hexa desta IDE).
; ------------------------------------------------------------
;

EnableExplicit

XIncludeFile "..\assemblers\Z80Asm.pbi"
XIncludeFile "..\visual_editors\SeeTrackerDriverAsm.pbi"

OpenConsole()

Define Source.s = SeeDrv_SourceCode()
Define Dim AsmBytes.a(65535)
Define N = Z80Asm::Assemble(Source, AsmBytes())

If N < 0
  PrintN("FALHA ao montar o driver SEE Tracker:")
  PrintN("  Linha " + Str(Z80Asm::GetAssembleErrorLine()) + ": " + Z80Asm::GetAssembleErrorText())
  ; Imprime a linha com problema pra facilitar o diagnostico (fonte gerado
  ; em memoria, nao existe arquivo .asm em disco pra abrir manualmente)
  Define LineNum = Z80Asm::GetAssembleErrorLine()
  If LineNum > 0
    Define TotalLines = CountString(Source, #CRLF$) + 1
    If LineNum <= TotalLines
      PrintN("  Texto: " + StringField(Source, LineNum, #CRLF$))
    EndIf
  EndIf
  End 1
EndIf

If N = 0
  PrintN("FALHA: nada foi montado (fonte vazio?).")
  End 1
EndIf

PrintN("OK: " + Str(N) + " bytes montados.")
PrintN("StartAddr = #" + Hex(Z80Asm::GetAssembleStartAddr()))
PrintN("EndAddr   = #" + Hex(Z80Asm::GetAssembleEndAddr()))

Define.s Names.s = "SEE_IN,SEE_EX,SETSFX,CUTSFX,SEEINT,BSETFX,SEEADR,SEEMAP,SEETID,SEESTA,SFXPRI,SEEVOL,SEE_ID,PATADR,SFX_NR,PAT_NR,TEMPO,_HALT,LOOPNR,LOOPBF,CLPADR,_HISPT,_HIPTA,_HISFX,_FLELN,PSGREG,OLDVBL,OLDMAP"
Define i, NameCount = CountString(Names, ",") + 1, Nm.s
For i = 1 To NameCount
  Nm = StringField(Names, i, ",")
  If Z80Asm::IsSymbolKnown(Nm)
    PrintN(RSet(Nm, 8) + " = #" + RSet(Hex(Z80Asm::GetSymbolValue(Nm)), 4, "0"))
  Else
    PrintN(RSet(Nm, 8) + " = ??? (simbolo nao encontrado)")
  EndIf
Next

If CountProgramParameters() >= 1
  Define OutPath.s = ProgramParameter(0)
  Define FileNum = CreateFile(#PB_Any, OutPath)
  If FileNum
    WriteData(FileNum, @AsmBytes(), N)
    CloseFile(FileNum)
    PrintN("Gravado: " + OutPath)
  Else
    PrintN("FALHA ao gravar " + OutPath)
    End 1
  EndIf
EndIf

End 0
