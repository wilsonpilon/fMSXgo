;
; ------------------------------------------------------------
;  Ferramenta de linha de comando para testar o pipeline nativo
;  (Dignified -> ASCII -> tokenizado) sem precisar abrir o editor.
;
;  Usada como suite de regressao do projeto. O arquivo de referencia
;  principal e teste.dmx (raiz do projeto - "Change Graph Kit" de
;  Fred Rique, ~900 linhas de codigo Dignified real), mas aceita
;  qualquer .dmx/.amx.
;
;  Uso:
;    DigTestCli.exe <entrada.dmx> <saida> [tok|msxbas2rom]
;      <entrada.dmx>  arquivo Dignified (ou ja ASCII classico) a processar
;      <saida>        prefixo do arquivo de saida (".amx" e opcionalmente ".bmx")
;      tok            se presente, tambem tokeniza o resultado (gera <saida>.bmx)
;      msxbas2rom     roda Dig_Preprocess em modo MSXBAS2ROM (vocabulario
;                     estendido protegido contra encurtamento, FILE/TEXT sem
;                     numero de linha) em vez do modo classico - incompativel
;                     com "tok" (MSXBAS2ROM nunca tokeniza)
;
;  Compilar com:
;    "C:\Basic\Compilers\pbcompiler.exe" editor\tools\DigTestCli.pb /EXE editor\tools\DigTestCli.exe /CONSOLE
; ------------------------------------------------------------
;

EnableExplicit
OpenConsole()

XIncludeFile "..\core\DignifiedPreprocessor.pbi"
XIncludeFile "..\core\MsxTokenizer.pbi"

Define InPath.s = ProgramParameter(0)
Define OutPath.s = ProgramParameter(1)
Define DoTokenize.s = ProgramParameter(2)

If InPath = "" Or OutPath = ""
  PrintN("Uso: DigTestCli.exe <entrada.dmx> <saida> [tok]")
  End 1
EndIf

Define fnum = ReadFile(#PB_Any, InPath, #PB_File_BOM)
If Not fnum
  PrintN("Nao foi possivel abrir: " + InPath)
  End 1
EndIf

Define content.s = ""
While Not Eof(fnum)
  content + ReadString(fnum, #PB_File_IgnoreEOL) + Chr(13) + Chr(10)
Wend
CloseFile(fnum)

Define IsMsxBas2Rom.b = Bool(DoTokenize = "msxbas2rom")
Define ascii.s = Dig_Preprocess(content, GetPathPart(InPath), IsMsxBas2Rom)

If Dig_HasError
  PrintN("DIGERROR linha " + Str(Dig_ErrorLine) + ": " + Dig_ErrorMsg)
  End 1
EndIf

Define outnum = CreateFile(#PB_Any, OutPath + ".amx")
WriteString(outnum, ascii)
CloseFile(outnum)
PrintN("ASCII OK: " + OutPath + ".amx (" + Str(CountString(ascii, Chr(10))) + " linhas)")

If DoTokenize = "tok"
  Define hexOut.s = Tok_Tokenize(ascii)
  If Tok_HasError
    PrintN("TOKERROR linha " + Str(Tok_ErrorLine) + ": " + Tok_ErrorMsg)
    End 1
  EndIf
  Tok_SaveHexAsBinary(hexOut, OutPath + ".bmx")
  PrintN("TOK OK: " + OutPath + ".bmx (" + Str(Len(hexOut) / 2) + " bytes)")
EndIf
