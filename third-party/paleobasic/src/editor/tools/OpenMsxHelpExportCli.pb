;
; ------------------------------------------------------------
;  Ferramenta de linha de comando pra (re)gerar docs/reference/openmsx.md a
;  partir da base de dados de OpenMsxHelpData.pbi - mesmo conteudo da
;  janela Ajuda -> openMSX... do editor (OpenMsxHelpGui.pbi). Rodar de
;  novo sempre que o conteudo em editor\OpenMsxHelpData.pbi for editado, pra
;  manter o .md exportado sincronizado (mesma ideia de
;  NBHelp_ExportMarkdown em NestorBasicHelpData.pbi, so que com uma
;  ferramenta de linha de comando de verdade pra rodar de novo, em vez de
;  ser um export de unica vez feito na mao).
;
;  Uso:
;    OpenMsxHelpExportCli.exe <caminho_saida.md>
;
;  Compilar com:
;    "C:\Basic\Compilers\pbcompiler.exe" editor\tools\OpenMsxHelpExportCli.pb /EXE editor\tools\OpenMsxHelpExportCli.exe /CONSOLE
; ------------------------------------------------------------
;

EnableExplicit
OpenConsole()

XIncludeFile "..\help\OpenMsxHelpData.pbi"

Define OutPath.s = ProgramParameter(0)
If OutPath = ""
  PrintN("Uso: OpenMsxHelpExportCli.exe <caminho_saida.md>")
  End 1
EndIf

If OMSXHelp_ExportMarkdown(OutPath)
  PrintN("OK: " + OutPath)
Else
  PrintN("ERRO: nao foi possivel gravar " + OutPath)
  End 1
EndIf
