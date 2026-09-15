<#
.SYNOPSIS
    Compila o executavel do MSX BASIC+Z80 IDE (src\editor\BadigEditor.pb) usando o
    PureBasic Compiler (pbcompiler.exe), gerando dist\PaleoBasic.exe.

.DESCRIPTION
    O caminho do pbcompiler.exe e resolvido nesta ordem de prioridade:
      1) Opcao -C / --compiler na linha de comando
      2) Valor "CompilerPath" gravado em build.config.json (ao lado deste script)
      3) Caminho padrao: %PROGRAMFILES%\PureBasic\Compilers\pbcompiler.exe
    Quando o caminho e informado via -C/--compiler, ele e salvo em
    build.config.json para as proximas execucoes.

    Versao e build sao embutidas no executavel em tempo de compilacao via
    /CONSTANT do pbcompiler (constantes #App_Version/#App_Build/#App_BuildDate
    em editor\BadigEditor.pb, exibidas em Ajuda -> Sobre...): a build e a
    data/hora UTC do momento da compilacao, convertida para hexadecimal
    (segundos desde a epoch Unix).

    Todo build compila os DOIS executaveis (dist\PaleoBasic.exe e
    dist\fossauro.exe, via src\fossauro\build.ps1) e atualiza dist\ por
    inteiro (recursos de resource\, docs, ROMs) - pedido explicito do usuario
    (2026-08-20): fossauro e parte do PaleoBasic, um build unico tem que
    deixar o pacote pronto, sem precisar rodar dois scripts nem lembrar de um
    flag extra (a antiga opcao -D/--distribute foi removida - o que ela fazia
    agora sempre acontece).

    Desde 2026-08-25 (pedido explicito do usuario), todo build TAMBEM: copia
    as ROMs de resource\roms\ pra dist\roms\ (ja fazia isso, mas so' se
    resource\roms\ existisse - continua condicional a isso, nunca falha o
    build por ROM ausente), gera um .zip novo do pacote dist\ inteiro
    (paleobasic-v<versao>.zip na raiz do repo, mesma convencao ja usada nos
    releases manuais anteriores - ver .gitignore) e chama build-installer.ps1
    (com -SkipAppBuild, pra nao recompilar tudo de novo) pra deixar
    installer\PaleoBasicSetup.exe atualizado tambem. As duas novas etapas
    podem ser puladas com -SkipZip/-SkipInstaller (compilar rapido durante
    iteracao, sem esperar o zip de ~100+MB ou a compilacao do instalador).

    Todas as opcoes (-H/--help, -C/--compiler, -R/--run, -V/--version,
    -i/--sourcefile, -o/--outputexe) sao lidas manualmente de $args abaixo, em vez de um bloco
    param() do PowerShell: PowerShell 7 faz *binding posicional* de qualquer
    token que nao reconhece (ex.: "--run") para o primeiro parametro
    declarado, mesmo sem "-" na frente - com param(), ".\build.ps1 --run"
    silenciosamente virava $Version = "--run". Sem param(), $args recebe tudo
    e o parsing abaixo decide o que fazer com cada token.

.EXAMPLE
    .\build.ps1
.EXAMPLE
    .\build.ps1 -C "D:\PureBasic\Compilers\pbcompiler.exe"
.EXAMPLE
    .\build.ps1 --compiler "D:\PureBasic\Compilers\pbcompiler.exe" --run
.EXAMPLE
    .\build.ps1 -V "5.2.0" -R
.EXAMPLE
    .\build.ps1 -H
#>

$ErrorActionPreference = "Stop"

function Show-Help {
    @"
Uso: build.ps1 [opcoes]

Compila o MSX BASIC+Z80 IDE (dist\PaleoBasic.exe) e o fossauro
(dist\fossauro.exe, via src\fossauro\build.ps1), depois atualiza dist\ por
inteiro (recursos de resource\, docs, ROMs) - sempre, todo build deixa o
pacote pronto. Em seguida gera paleobasic-v<versao>.zip (pacote dist\
inteiro) e installer\PaleoBasicSetup.exe (via build-installer.ps1).

Opcoes:
  -C, --compiler <caminho>  Caminho para o pbcompiler.exe. Fica salvo em
                             build.config.json para as proximas execucoes.
  -R, --run                 Executa o programa apos compilar com sucesso.
  -H, --help                Mostra esta ajuda e sai.
  -V, --version <versao>    Versao embutida nos dois executaveis (padrao: 8.6.0).
  -i, --sourcefile <arquivo> Arquivo fonte a compilar
                             (padrao: src\editor\BadigEditor.pb).
  -o, --outputexe <arquivo> Caminho do executavel de saida
                             (padrao: dist\PaleoBasic.exe).
  --skipzip                 Nao gera o .zip do pacote dist\ neste build.
  --skipinstaller           Nao gera/atualiza installer\PaleoBasicSetup.exe neste build.

Exemplos:
  .\build.ps1
  .\build.ps1 -C "C:\Basic\Compilers\pbcompiler.exe"
  .\build.ps1 --compiler "C:\Basic\Compilers\pbcompiler.exe" --run
  .\build.ps1 -V "5.2.0" -R
  .\build.ps1 --skipzip --skipinstaller
"@ | Write-Host
}

# Ver nota no bloco de ajuda acima sobre por que isso nao e um param().
$Help = $false
$Compiler = $null
$Run = $false
$Version = "8.7.5"
$SourceFile = Join-Path $PSScriptRoot "src\editor\BadigEditor.pb"
$OutputExe = Join-Path $PSScriptRoot "dist\PaleoBasic.exe"
$SkipZip = $false
$SkipInstaller = $false

# $args e uma variavel automatica por escopo (uma funcao chamada daqui teria
# o SEU PROPRIO $args, nao o deste script) - por isso o parsing e feito inline
# num unico loop, em vez de delegado a uma funcao auxiliar.
$i = 0
while ($i -lt $args.Count) {
    $token = $args[$i]
    switch -Regex ($token) {
        '^(-H|--help)$' { $Help = $true }

        '^(-C|--compiler)$' {
            $i++
            if ($i -ge $args.Count) { Write-Error "Falta o caminho depois de $token."; exit 1 }
            $Compiler = $args[$i]
        }

        '^(-R|--run)$' { $Run = $true }

        '^(-V|--version)$' {
            $i++
            if ($i -ge $args.Count) { Write-Error "Falta a versao depois de $token."; exit 1 }
            $Version = $args[$i]
        }

        '^(-i|--sourcefile)$' {
            $i++
            if ($i -ge $args.Count) { Write-Error "Falta o caminho depois de $token."; exit 1 }
            $SourceFile = $args[$i]
        }

        '^(-o|--outputexe)$' {
            $i++
            if ($i -ge $args.Count) { Write-Error "Falta o caminho depois de $token."; exit 1 }
            $OutputExe = $args[$i]
        }

        '^--skipzip$' { $SkipZip = $true }

        '^--skipinstaller$' { $SkipInstaller = $true }

        default {
            Write-Warning "Parametro desconhecido: $token (use -H ou --help para ver as opcoes)."
        }
    }
    $i++
}

if ($Help) {
    Show-Help
    exit 0
}

$ConfigPath = Join-Path $PSScriptRoot "build.config.json"
$DefaultCompilerPath = Join-Path $env:PROGRAMFILES "PureBasic\Compilers\pbcompiler.exe"

function Get-BuildConfig {
    if (Test-Path $ConfigPath) {
        try {
            return Get-Content $ConfigPath -Raw | ConvertFrom-Json
        } catch {
            Write-Warning "Nao foi possivel ler $ConfigPath ($($_.Exception.Message)). Ignorando arquivo de configuracao."
        }
    }
    return $null
}

function Set-BuildConfig([string]$CompilerPath) {
    [ordered]@{ CompilerPath = $CompilerPath } | ConvertTo-Json | Set-Content -Path $ConfigPath -Encoding UTF8
}

$config = Get-BuildConfig

if ($Compiler) {
    $CompilerPath = $Compiler
    Set-BuildConfig -CompilerPath $CompilerPath
    Write-Host "Caminho do compilador salvo em $ConfigPath"
} elseif ($config -and $config.CompilerPath) {
    $CompilerPath = $config.CompilerPath
} else {
    $CompilerPath = $DefaultCompilerPath
}

if (-not (Test-Path $CompilerPath)) {
    Write-Error "pbcompiler.exe nao encontrado em: $CompilerPath`nConfigure o caminho correto via -C/--compiler ou edite $ConfigPath."
    exit 1
}

if (-not (Test-Path $SourceFile)) {
    Write-Error "Arquivo fonte nao encontrado: $SourceFile"
    exit 1
}

$OutputDir = Split-Path $OutputExe -Parent
if ($OutputDir -and -not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$UtcNow = [DateTime]::UtcNow
$BuildEpoch = [DateTimeOffset]::new($UtcNow, [TimeSpan]::Zero).ToUnixTimeSeconds()
$BuildHex = "{0:X8}" -f $BuildEpoch
$BuildDateText = $UtcNow.ToString("yyyy-MM-dd HH:mm:ss") + " UTC"

# Icone padrao do app (Explorer/propriedades do .exe). Embutido como recurso
# via /ICON do pbcompiler; em runtime, App_ApplyWindowIcon() (BadigEditor.pb)
# reextrai esse mesmo recurso do proprio .exe (ExtractIconEx) pra aplicar em
# cada janela (barra de titulo/sistema, barra de tarefas, Alt+Tab) - nao
# depende do arquivo .ico sobreviver ao lado do executavel depois do build.
$IconFile = Join-Path $PSScriptRoot "resource\branding\paleobasic-new.ico"
$IconArgs = @()
if (Test-Path $IconFile) {
    $IconArgs = @("/ICON", $IconFile)
} else {
    Write-Warning "Icone nao encontrado em $IconFile - compilando sem /ICON."
}

Write-Host "Compilador : $CompilerPath"
Write-Host "Fonte      : $SourceFile"
Write-Host "Saida      : $OutputExe"
Write-Host "Versao     : $Version"
Write-Host "Build      : $BuildHex ($BuildDateText)"
# /XP embute o manifesto de dependencia do comctl32 v6 (mesmo mecanismo do
# antigo "Windows XP visual styles") - sem ele, gadgets nativos nao-tematizados
# (checkbox/combobox/listview/scrollbar/groupbox - o ButtonImageGadget dos
# botoes ja e desenhado a mao, ver ThemedButtons.pbi, entao nao depende disso)
# renderizam no estilo antigo, sem tema, mesmo no Windows 10/11.
Write-Host ""

& $CompilerPath $SourceFile /OUTPUT $OutputExe /QUIET /CONSOLE /XP @IconArgs `
    /CONSTANT "App_Version=$Version" `
    /CONSTANT "App_Build=$BuildHex" `
    /CONSTANT "App_BuildDate=$BuildDateText"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Falha na compilacao (codigo $LASTEXITCODE)."
    exit $LASTEXITCODE
}

Write-Host "Build concluido: $OutputExe"

# fossauro e parte do PaleoBasic (nao um projeto separado) - todo build deste
# script tambem builda o fossauro, mesma versao, licenca propria/nao-comercial
# (LICENSE-fossauro) a parte so muda ONDE o codigo mora, nao SE ele e buildado
# junto. Script proprio porque compila um .pb diferente (src\fossauro\fossauro.pb),
# mas roda sempre daqui em diante - pedido explicito do usuario (2026-08-20).
Write-Host ""
Write-Host "Compilando fossauro..."
$FossauroBuildScript = Join-Path $PSScriptRoot "src\fossauro\build.ps1"
& $FossauroBuildScript -Version $Version
if ($LASTEXITCODE -ne 0) {
    Write-Error "Falha na compilacao do fossauro (codigo $LASTEXITCODE)."
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Atualizando dist\..."

# dist\ NAO e um pacote descartavel (era o caso da antiga distribute\, sempre
# apagada e refeita do zero) - tem conteudo VERSIONADO junto (dist\sample\,
# dist\projects\, dist\res\) que este passo nao pode tocar. So copia por cima
# os itens GERADOS/derivados de resource\+src\ (fontes, imagens de ajuda,
# ferramentas externas, docs, branding, ROMs) - Copy-Item -Force sobrescreve
# arquivo por arquivo sem remover o resto da arvore.
$DistDir = Join-Path $PSScriptRoot "dist"
$DistEditorDir = Join-Path $DistDir "editor"
New-Item -ItemType Directory -Path $DistEditorDir -Force | Out-Null

function Copy-DistItem([string]$Path, [string]$Destination, [switch]$Recurse) {
    if (Test-Path $Path) {
        # Bug real encontrado rodando este passo pela SEGUNDA vez (2026-08-19): quando
        # $Destination ja existe como pasta (sobrou da execucao anterior), "Copy-Item -Recurse"
        # copia a pasta ORIGEM PRA DENTRO dela em vez de sobrescrever arquivo por arquivo -
        # resultado "dist\editor\fonts\fonts\..." aninhado. Apagar o destino primeiro (so
        # quando -Recurse e' pasta) torna o passo idempotente de verdade.
        if ($Recurse -and (Test-Path $Destination -PathType Container)) {
            Remove-Item -Path $Destination -Recurse -Force
        }
        Copy-Item -Path $Path -Destination $Destination -Recurse:$Recurse -Force
        Write-Host "  incluido: $Path -> $Destination"
    } else {
        Write-Warning "  nao encontrado, pulando: $Path"
    }
}

Copy-DistItem -Path (Join-Path $PSScriptRoot "README.md") -Destination $DistDir
Copy-DistItem -Path (Join-Path $PSScriptRoot "docs\MANUAL.md") -Destination $DistDir
Copy-DistItem -Path (Join-Path $PSScriptRoot "LICENSE") -Destination $DistDir
Copy-DistItem -Path (Join-Path $PSScriptRoot "resource\branding\paleobasic.png") -Destination $DistDir
Copy-DistItem -Path (Join-Path $PSScriptRoot "resource\fonts") -Destination (Join-Path $DistEditorDir "fonts") -Recurse
Copy-DistItem -Path (Join-Path $PSScriptRoot "resource\redbook_images") -Destination (Join-Path $DistEditorDir "redbook_images") -Recurse
Copy-DistItem -Path (Join-Path $PSScriptRoot "resource\th2handbook_images") -Destination (Join-Path $DistEditorDir "th2handbook_images") -Recurse
Copy-DistItem -Path (Join-Path $PSScriptRoot "resource\superx\SUPER-X-PT.notas") -Destination (Join-Path $DistEditorDir "SUPER-X-PT.notas")
$DistToolsDir = Join-Path $DistEditorDir "tools"
New-Item -ItemType Directory -Path $DistToolsDir -Force | Out-Null
Copy-DistItem -Path (Join-Path $PSScriptRoot "resource\tools\msxbas2rom") -Destination (Join-Path $DistToolsDir "msxbas2rom") -Recurse
Copy-DistItem -Path (Join-Path $PSScriptRoot "resource\tools\n80") -Destination (Join-Path $DistToolsDir "n80") -Recurse

# help do Fossauro (o executavel em si ja foi compilado acima, direto pra
# dist\fossauro.exe por src\fossauro\build.ps1).
$DistFossauroDir = Join-Path $DistDir "fossauro"
New-Item -ItemType Directory -Path $DistFossauroDir -Force | Out-Null
Copy-DistItem -Path (Join-Path $PSScriptRoot "resource\fossauro_help") -Destination (Join-Path $DistFossauroDir "help") -Recurse

# ROMs do sistema MSX pro Fossauro (MSX.pbi le "roms/MSX.ROM" e afins, caminho
# cru relativo ao diretorio de trabalho no lancamento - dist\fossauro.exe roda
# com CWD = dist\, entao a pasta precisa se chamar dist\roms\, nao
# dist\fossauro\roms\). Fonte canonica fica em resource\roms\ - copyright
# proprio, nunca rastreado no git (ver .gitignore); so' copia se o usuario ja
# tiver colocado as ROMs la.
if (Test-Path (Join-Path $PSScriptRoot "resource\roms")) {
    $DistRomsDir = Join-Path $DistDir "roms"
    New-Item -ItemType Directory -Path $DistRomsDir -Force | Out-Null
    Copy-DistItem -Path (Join-Path $PSScriptRoot "resource\roms\*.ROM") -Destination $DistRomsDir
}

Write-Host "dist\ atualizado em: $DistDir"

# --- ZIP do pacote dist\ inteiro ------------------------------------------
# paleobasic-v<versao>.zip na raiz do repo - mesma convencao ja usada nos
# releases manuais anteriores (paleobasic-v073344.zip, paleobasic-v080200.zip,
# etc. - ver .gitignore e docs/RELEASE_NOTES.md), so' que gerada automatica
# a cada build agora em vez de manualmente. Tag de versao = cada parte de
# $Version (Major.Minor.Patch) com 2 digitos, sem pontos (ex.: "8.4.0" ->
# "080400") - mesmo esquema dos releases anteriores. Zipa o CONTEUDO de dist\
# (Join-Path ... "*"), nao a pasta dist\ em si, pra quem extrair o zip cair
# direto nos executaveis, sem uma pasta "dist" extra no meio.
if (-not $SkipZip) {
    Write-Host ""
    Write-Host "Gerando .zip do pacote dist\..."

    $VersionParts = $Version -split '\.'
    $ZipTag = -join (0..2 | ForEach-Object {
        $Part = if ($_ -lt $VersionParts.Count) { $VersionParts[$_] } else { "0" }
        $DigitsOnly = ($Part -replace '[^0-9]', '')
        if ($DigitsOnly -eq "") { $DigitsOnly = "0" }
        "{0:D2}" -f [int]$DigitsOnly
    })

    $ZipPath = Join-Path $PSScriptRoot "paleobasic-v$ZipTag.zip"
    Compress-Archive -Path (Join-Path $DistDir "*") -DestinationPath $ZipPath -Force
    $ZipSizeMB = [Math]::Round((Get-Item $ZipPath).Length / 1MB, 1)
    Write-Host "  zip: $ZipPath ($ZipSizeMB MB)"
} else {
    Write-Host ""
    Write-Host "Zip do pacote dist\ pulado (--skipzip)."
}

# --- Instalador standalone -------------------------------------------------
# build-installer.ps1 (raiz do repo) - chamado com -SkipAppBuild porque dist\
# ja esta fresco (acabou de ser gerado acima nesta mesma execucao); sem essa
# flag ele chamaria de volta este proprio build.ps1, recompilando tudo de
# novo a toa.
if (-not $SkipInstaller) {
    Write-Host ""
    Write-Host "Gerando instalador (build-installer.ps1)..."
    $InstallerScript = Join-Path $PSScriptRoot "build-installer.ps1"
    & $InstallerScript -Version $Version -SkipAppBuild
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Falha gerando o instalador (codigo $LASTEXITCODE)."
        exit $LASTEXITCODE
    }
} else {
    Write-Host ""
    Write-Host "Instalador pulado (--skipinstaller)."
}

if ($Run) {
    Write-Host "Executando $OutputExe ..."
    Start-Process -FilePath $OutputExe
}
