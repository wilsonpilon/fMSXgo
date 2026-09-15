;
; ------------------------------------------------------------
;  BuildPayloadZip.exe - ferramenta de build (NAO faz parte do produto final).
;  Empacota o conteudo de dist\ (a lista exata de arquivos vem de um manifesto
;  de texto, uma linha por arquivo, caminho relativo a raiz do projeto - ver
;  build-installer.ps1, que gera esse manifesto via "git ls-files dist/" +
;  extras nao rastreados mas necessarios como dist/fossauro.exe) num unico
;  .zip que o instalador (PaleoBasicSetup.pb) embute via IncludeBinary.
;
;  Usa o Packer nativo do PureBasic (UseZipPacker/CreatePack/AddPackFile), nao
;  Compress-Archive do PowerShell nem nenhuma lib externa - mesmo espirito
;  "sem dependencia de runtime externo" do resto do projeto (ver CLAUDE.md),
;  e evita qualquer duvida de compatibilidade de separador de path entre um
;  zip gerado pelo .NET e o mesmo Packer do PureBasic lendo de volta do lado
;  do instalador.
;
;  Uso: BuildPayloadZip.exe <RaizDoProjeto> <ArquivoManifesto> <SaidaZip>
;  Cada linha do manifesto e um caminho relativo a RaizDoProjeto, comecando
;  com "dist/" ou "dist\" (o prefixo "dist" e removido do nome dentro do zip,
;  entao "dist/editor/foo.json" vira a entrada "editor/foo.json" - o
;  instalador extrai direto pra dentro da pasta de instalacao escolhida, sem
;  uma subpasta "dist" no meio).
;
;  Entradas com nome NAO-ASCII sao puladas de proposito (nao entram no zip) -
;  bug real encontrado testando o instalador de ponta a ponta (2026-08-22):
;  um unico arquivo com acento no nome (achado real:
;  "La sereníssima (Loreena McKennitt).mid", dist\editor\tools\msxbas2rom\
;  games\...) corrompe o estado de leitura do Packer/Zip do PureBasic do
;  lado do instalador (CatchPack de memoria + ExaminePack/NextPackEntry) -
;  confirmado com um repro isolado de 3 arquivos (a.txt / <nome acentuado> /
;  z.txt): so o PRIMEIRO (antes do nome acentuado) extrai, os outros DOIS
;  (o acentuado E o que vem depois dele) falham silenciosamente - nao e so
;  aquele arquivo especifico que falha, TUDO que vem depois dele na mesma
;  passada de ExaminePack tambem falha. Nao isolado se o bug e no lado da
;  ESCRITA (AddPackFile deste arquivo) ou da LEITURA (CatchPack/
;  UncompressPackFile do instalador) - excluir na escrita e a correcao mais
;  simples e robusta dos dois lados por igual, sem precisar decidir qual.
;  Escrito num log ao lado do .zip (ver LogLine abaixo) em vez de so PrintN -
;  saida de console de um .exe /CONSOLE nao aparece de forma confiavel neste
;  ambiente de teste (mesmo achado ja documentado em CLAUDE.md pra outros
;  casos), o log em arquivo e verificavel sempre.
UseZipPacker()

Global LogFile

Procedure LogLine(Text.s)
  PrintN(Text)
  If LogFile
    WriteStringN(LogFile, Text)
    FlushFileBuffers(LogFile)
  EndIf
EndProcedure

Procedure.b IsAsciiOnly(S.s)
  Protected I
  For I = 1 To Len(S)
    If Asc(Mid(S, I, 1)) > 127
      ProcedureReturn #False
    EndIf
  Next
  ProcedureReturn #True
EndProcedure

Procedure.s NormalizeSlashes(Path.s)
  ProcedureReturn ReplaceString(Path, "/", "\")
EndProcedure

Procedure.s StripDistPrefix(RelPath.s)
  Protected P.s = ReplaceString(RelPath, "\", "/")
  If Left(P, 5) = "dist/"
    P = Mid(P, 6)
  EndIf
  ProcedureReturn P
EndProcedure

If CountProgramParameters() < 3
  PrintN("Uso: BuildPayloadZip.exe <RaizDoProjeto> <ArquivoManifesto> <SaidaZip>")
  End 1
EndIf

Define RootDir.s = NormalizeSlashes(ProgramParameter(0))
If Right(RootDir, 1) <> "\"
  RootDir + "\"
EndIf
Define ManifestPath.s = ProgramParameter(1)
Define OutputZip.s = ProgramParameter(2)

LogFile = CreateFile(#PB_Any, OutputZip + ".build.log")

Define ManifestFile = ReadFile(#PB_Any, ManifestPath)
If Not ManifestFile
  LogLine("Erro: nao foi possivel abrir o manifesto: " + ManifestPath)
  End 1
EndIf

If FileSize(OutputZip) >= 0
  DeleteFile(OutputZip)
EndIf

Define Pack = CreatePack(#PB_Any, OutputZip)
If Not Pack
  LogLine("Erro: nao foi possivel criar o zip de saida: " + OutputZip)
  End 1
EndIf

Define Line.s, SourcePath.s, ArchiveName.s
Define Total = 0, Falhas = 0, PuladosNaoAscii = 0
While Not Eof(ManifestFile)
  Line = Trim(ReadString(ManifestFile))
  If Line = ""
    Continue
  EndIf

  ArchiveName = StripDistPrefix(Line)
  If ArchiveName = ""
    Continue
  EndIf
  SourcePath = RootDir + NormalizeSlashes(Line)

  ; Checado ANTES do FileSize() de proposito: se o manifesto chegou com
  ; encoding corrompido (achado real, ver build-installer.ps1 - saida do
  ; "git ls-files" capturada com o codepage OEM/legado do console em vez de
  ; UTF-8 vira "seren├¡ssima" em vez de "sereníssima"), o caminho corrompido
  ; nunca bate com um arquivo real no disco e cairia no ramo de "nao
  ; encontrado" (FALHA, aborta o build inteiro) mesmo sendo, na pratica, o
  ; MESMO caso "nome nao-ASCII" que deveria so ser pulado - checar isso
  ; primeiro garante que build-installer.ps1 nunca falha por causa disso,
  ; mesmo se a causa raiz do encoding corrompido nunca tivesse sido
  ; corrigida no PowerShell.
  If Not IsAsciiOnly(ArchiveName)
    LogLine("  PULADO (nome nao-ASCII, ver cabecalho do .pb): " + ArchiveName)
    PuladosNaoAscii + 1
    Continue
  EndIf

  If FileSize(SourcePath) < 0
    LogLine("  AVISO: arquivo nao encontrado, pulando: " + SourcePath)
    Falhas + 1
    Continue
  EndIf

  If AddPackFile(Pack, SourcePath, ArchiveName)
    Total + 1
  Else
    LogLine("  ERRO: falha ao adicionar ao zip: " + SourcePath)
    Falhas + 1
  EndIf
Wend

CloseFile(ManifestFile)
ClosePack(Pack)

LogLine("Payload criado: " + OutputZip + " (" + Str(Total) + " arquivos, " + Str(Falhas) + " falha(s), " + Str(PuladosNaoAscii) + " pulado(s) por nome nao-ASCII)")
If LogFile
  CloseFile(LogFile)
EndIf
If Falhas > 0
  End 1
EndIf
End 0
