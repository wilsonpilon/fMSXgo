# Assembler Z80 nativo (módulo 2) — resumo de progresso

> Documento de acompanhamento desta frente de trabalho (não é a spec funcional — essa é
> `docs/SPEC.md` módulo 2 — este arquivo é o "estado da implementação", para retomar em qualquer
> máquina). Atualizado a cada marco concluído.

## Objetivo

Assembler Z80 nativo em PureBasic, **compatível com M80/L80** (Microsoft MACRO-80/LINK-80),
integrado ao editor. Especificação de comportamento: **Nestor80** (Konamiman,
github.com/Konamiman/Nestor80) — assembler C# moderno, 100% compatível M80/L80.

## Decisões de escopo (fechadas com o usuário, 2026-07-24)

1. **REL + Linker desde já** — arquitetura completa tipo N80/LK80 (assembler emite `.REL`
   relocável, linker separado resolve símbolos entre módulos, gera binário final), não só saída
   absoluta.
2. **Macros básicas na v1** — `MACRO`/`ENDM` com parâmetros e expansão, `IF`/`ENDIF`. `REPT`/`IRP`/
   `IRPC`/`IRPS` ficam para depois.
3. **Motor já integrado ao menu do editor** — item de menu "Montar" real já na v1, não só CLI
   headless.
4. **(2026-07-24, adicionado depois do plano original) Libstor80 (gerenciador de biblioteca) também
   entra em escopo**, não só o Linkstor80/LK80 (linker). O pedido explícito do usuário: gerar uma
   biblioteca (`.LIB`, várias rotinas montadas separadamente) e, na hora de linkar um programa contra
   ela, só as partes/módulos realmente referenciados são puxados pro `.COM` final (linkagem estática
   seletiva — nenhuma rotina não usada da lib entra no binário). Isso **não muda a arquitetura do
   linker em si**: o algoritmo de resolução de `.REQUEST`/biblioteca já pesquisado (ver
   `nestor80-linker.md`, Fase B) já é exatamente esse comportamento — uma "biblioteca" é só um
   arquivo com vários "programas" `.REL` concatenados (cada um já auto-delimitado pelo item "End of
   program" do formato), e o linker só puxa pra dentro o(s) programa(s) que resolvem um símbolo
   externo pendente (sem esse programa, ninguém referenciado → não entra). O que falta é um **gerenciador de biblioteca próprio**
   (`editor/Z80Lib.pbi`, `DeclareModule Z80Lib`, equivalente ao LB80/Libstor80 — criar/listar/
   adicionar/remover módulos `.REL` dentro de um arquivo `.LIB`), reaproveitando o parser/escritor de
   `.REL` que `Z80Link.pbi` já vai ter. Ver checklist da Fase B abaixo.
5. **(2026-07-24, adicionado ao fechar a sessão) Duas integrações adicionais confirmadas como objetivo
   do módulo, nenhuma iniciada ainda** — registradas aqui pra não se perderem entre sessões:
   - **Integração com o sistema de projeto** (módulo 13 do `docs/SPEC.md`) — o assembler ainda não tem
     tabela própria no `.msxproject` (número/tag/navegação/Registrar, mesmo padrão de sprites/
     alfabetos/sons/músicas/telas). O texto-fonte `.asm` já é salvo como `documents` (mecanismo
     genérico que toda aba de texto já tem), mas o **binário montado** não tem lugar nenhum no banco
     hoje.
   - **Integração com MSX-BASIC** — hoje "Montar" só salva um `.bin` solto no disco do PC. Dois
     caminhos pedidos: (1) **`BLOAD`** — colocar o `.bin` num `.dsk` (reaproveitando `MSXDisk.pbi`,
     mesmo mecanismo de `RunOnOpenMSX()`); (2) **listing `DATA`/`POKE` em hexadecimal** gerado a partir
     do binário montado, pro código Z80 poder ser colado dentro de um programa BASIC sem depender de
     carregar um arquivo à parte (mesmo espírito de `PsgGen_RawBytes()`, o botão "Gerar bytes crus" já
     existente no editor de som PSG — ver módulo 6 do `docs/SPEC.md` como referência de como esse tipo
     de botão já funciona no resto da IDE).
   Ver `docs/SPEC.md` módulo 2c pro texto completo dessas duas pendências.

Plano completo (fases A/B/C, arquitetura de arquivos, convenções PureBasic a seguir):
`C:\Users\wilso\.claude\plans\lazy-soaring-swing.md` (máquina local do Claude Code, não faz parte
do repo — o resumo abaixo é a versão persistida/git-tracked do que importa desse plano).

## Material de referência

- **`E:\msxbasica\nestor80\`** — clone raso do Nestor80, **gitignored** (`.gitignore` já tem
  `/nestor80/`, mesmo tratamento de `/badig/`: referência de leitura, não dependência de runtime).
  Para recriar em outra máquina:
  ```powershell
  git clone --depth 1 https://github.com/Konamiman/Nestor80.git nestor80
  ```
  Docs mais importantes dentro do clone: `docs/LanguageReference.md` (sintaxe/diretivas),
  `docs/MACRO-80.txt` (manual original Microsoft MACRO-80), `docs/asmlnk.txt` (manual original
  LINK-80), `docs/RelocatableFileFormat.md` (formato `.REL` byte-a-byte),
  `docs/WritingRelocatableCode.md` (modelo ASEG/CSEG/DSEG/COMMON/PUBLIC/EXTRN).
- **Oráculos de teste `N80.exe`/`LK80.exe`/`LB80.exe`** — o próprio Nestor80 (assembler + linker +
  gerenciador de biblioteca) compila e roda neste ambiente (`dotnet` 10.0.300 instalado). Usados para
  validar bytes gerados pelo port PureBasic, mesma técnica já usada para o tokenizador nativo
  (`docs/SPEC.md` módulo 11). Para recriar em qualquer máquina com `dotnet` instalado:
  ```powershell
  cd nestor80
  dotnet build N80/N80.csproj -c Release    # assembler - binário em N80\bin\Release\net6.0\N80.exe
  dotnet build LK80/LK80.csproj -c Release  # linker - binário em LK80\bin\Release\net6.0\LK80.exe
  dotnet build LB80/LB80.csproj -c Release  # biblioteca - binário em LB80\bin\Release\net6.0\LB80.exe
  ```
  Uso do assembler: `N80.exe fonte.asm saida.bin` (segundo argumento posicional = arquivo de saída,
  **não** `--output-file`). `LK80.exe`/`LB80.exe` ainda não foram exercitados além do `--help` nesta
  sessão (Fase B não começou de verdade) — `--help` de cada um já dá a sintaxe completa. Todos os três
  testados e confirmados compilando/funcionando 2026-07-24.
- `docs/reference/nestor80-language.md`, `docs/reference/nestor80-rel-format.md`,
  `docs/reference/nestor80-linker.md` — notas extraídas, mesmo padrão de
  `docs/reference/dignified-core.md`.

## Arquitetura (arquivos)

| Arquivo | Papel | Status |
|---|---|---|
| `editor/Z80RelFormat.pbi` | só tipos: `Enumeration Z80SegType` + `Structure Z80Addr` (valor+segmento) — nenhuma `Procedure` (ver "Módulo não enxerga Structure externa" no log técnico) | **Fase A pronto**; Fase B só reaproveita, sem mudar |
| `editor/Z80Asm.pbi` | `DeclareModule Z80Asm` — vocabulário, avaliador de expressão, parser de linha, tabela de opcodes Z80 completa, driver de 2 passes ABSOLUTO (`RunOnePass`/`Assemble`), diretivas de dados, condicionais, macros básicas, escritor de bit-stream `.REL` (`RelW_*`), driver de 2 passes RELOCÁVEL (`RunOnePassRel`/`AssembleRelocatable`/`NeedsRelocatable`) | **Fase A completa**. Fase B: geração de `.REL` real funcionando ponta a ponta (CSEG/DSEG/COMMON/PUBLIC/EXTRN bare), validada por oráculo (~3300 linhas) — falta o linker (`Z80Link.pbi`) e a integração de menu/projeto |
| `editor/tools/Z80AsmTestCli.pb` | harness `/CONSOLE`, PASS/FAIL (67 testes unitários) + modo `--assemble <fonte> <saida.bin>` (absoluto) / `--assemble-rel <fonte> <nome> <saida.rel>` (relocável) pra comparar contra `N80.exe` | **Fase A + B (parte assembler) completo** |
| `editor/Z80Link.pbi` | `DeclareModule Z80Link` — leitor `.REL` (`RR_*`) + algoritmo de linkagem (segmentos, `PUBLIC`/`EXTRN`, `.REQUEST`/biblioteca com ponto fixo transitivo, saída binária) | **Cortes 1 e 2 completos e validados por oráculo** |
| `editor/Z80Lib.pbi` | `DeclareModule Z80Lib` — gerenciador de biblioteca `.LIB` (`CreateOrAddLibrary`/`ListLibrary`/`RemoveProgram`), equivalente Libstor80/LB80 | **Completo e validado byte a byte contra `LB80.exe`** |
| `editor/tools/Z80LinkTestCli.pb` | harness pro linker (`--link`/`--libcreate`/`--liblist`/`--libremove` + suíte PASS/FAIL, 7 testes), mesmo padrão do `Z80AsmTestCli.pb` | **Completo** |
| (a definir) integração com `ProjectDB.pbi` | tabela pro binário montado no `.msxproject` | **Não iniciado**, ver decisão de escopo 5 |
| (a definir) geração de listing hex / `BLOAD` | consumir o `.bin` a partir de MSX-BASIC | **Não iniciado**, ver decisão de escopo 5 |

Convenções obrigatórias (já confirmadas por exploração do código existente e, durante a
implementação, por testes empíricos de compilação — ver "Log de decisões técnicas" abaixo para o
detalhe mais importante, a visibilidade de `Structure` através de `Module`):
- `DeclareModule`/`Module` real para `Z80Asm`/`Z80Link` (mesmo padrão de `ProjectDB.pbi`), não só
  prefixo — o subsistema tem verbos genéricos demais para prefixo simples não colidir.
- Buffer de saída do assembler: array 1D fixo de 64KB, nunca `ReDim` (gotcha conhecido: `ReDim` só
  redimensiona a última dimensão de um array multi-dim — ver
  `C:\Users\wilso\.claude\projects\E--msxbasica\memory\purebasic_redim_last_dim_only.md`). Ainda não
  implementado (parte da tarefa "driver de 2 passes").
- Listas de tamanho variável (símbolos, fixups, itens REL) usam `NewList ... Structure()`.
- Símbolos são case-insensitive — normalizado para maiúsculas em todo lookup/definição de símbolo
  (`Z80Asm::DefineSymbol`/uso interno de `Symbols()`).
- `KwZ80Mnemonic`/`KwZ80Register`/`KwZ80Directive`/`KwZ80Operator` (antes em `BadigEditor.pb`) **já
  migraram** para dentro de `Z80Asm.pbi` (`Z80Asm::IsMnemonic()`/`IsRegister()`/`IsDirective()`/
  `IsOperatorWord()`) — `HighlightZ80Text()` já consome de lá, vocabulário duplicado eliminado.

## Checklist Fase A

- [x] Clonar `nestor80/` como referência (gitignored)
- [x] Confirmar `dotnet`/`N80.exe` como oráculo de teste
- [x] Plano de arquitetura aprovado pelo usuário
- [x] `docs/reference/nestor80-language.md` — extração da spec (674 linhas)
- [x] `editor/Z80RelFormat.pbi` — tipos (`Z80Addr`/`Z80SegType`, sem `Procedure`)
- [x] Migrar `KwZ80Mnemonic`/etc. + `InitZ80KeywordMaps()` para `Z80Asm.pbi`
- [x] Tokenizador de expressão (números em todas as bases, strings de 1-2 chars, `$`, símbolos)
- [x] Avaliador de expressão (RPN/shunting-yard, precedência idêntica ao Nestor80 — conferida direto
      no C# fonte, não só na doc — 20 operadores, `HIGH`/`LOW`/`NOT`/unários) — **44/44 testes
      passando, incluindo comparação byte-a-byte com `N80.exe`**
- [x] Parser de **linha completa** (`Z80Asm::ParseLine()`) — label clássico (`nome:`/`nome::`),
      forma `símbolo EQU/DEFL/ASET valor` (sem `:` — ver nota abaixo), operador, argumentos crus,
      comentário com`;` (consciente de aspas), linha em branco/só-comentário. **15/15 testes
      passando** (59/59 no total do harness até agora)
- [x] **Tabela de opcodes Z80 completa** — todo o conjunto documentado (LD/aritmética/lógica/INC-DEC/
      16-bit/PUSH-POP/EX/rotação-deslocamento CB/BIT-SET-RES/saltos-condicionais/CALL-RET/RST/IM/
      IN-OUT/blocos ED LDI-LDIR-etc/IX-IY completo incl. `(IX+d)`/`(IY+d)` e os CB indexados
      DD-CB-d-op) **+ o subconjunto indocumentado comum de IXH/IXL/IYH/IYL** (LD/INC/DEC/aritmética
      com A). `Z80Asm::ClassifyOperand()` classifica forma do operando, `Z80Asm::EncodeInstruction()`
      despacha por família de mnemônico (~20 procedures `EncodeXxx` internas)
- [x] **Driver de 2 passes** (`Z80Asm::Assemble()`) — reprocessa o texto-fonte inteiro do zero em
      cada pass (mesma estratégia do próprio Nestor80), buffer de saída fixo de 64KB (`Dim
      Mem.a(65535)`, nunca `ReDim`), sem lista de fixups (desnecessária com 2 passes completos — ver
      log). `ORG`/rótulo/`EQU`/`DEFL`/`ASET`/`END` tratados; `ASEG`/`CSEG`/`DSEG`/`COMMON`/`PUBLIC`/
      `EXTRN`/etc. reconhecidos sem efeito pleno (Fase B)
- [x] **Diretivas de dados**: `DB`/`DEFB`/`DEFM` (string de qualquer tamanho ou expressão de 1 byte,
      lista separada por vírgula), `DW`/`DEFW` (expressão de 2 bytes LE, string de 1-2 chars via o
      mesmo empacotamento do avaliador de expressão), `DS`/`DEFS` (tamanho + valor de preenchimento
      opcional — tamanho precisa resolver já no pass 1, conferido), `DC` (como `DB`, mas o último byte
      recebe bit 7 setado), `DZ`/`DEFZ` (como `DB`, mas acrescenta um `0x00` no final). Reaproveitam
      `CountOperands`/`GetOperand` (mesmos helpers de split de operando das instruções de CPU).
      **Validado contra `N80.exe`**: `sample/teste_opcodes.asm` ampliado com um bloco de exemplos de cada
      diretiva → **441 bytes idênticos byte a byte** (era 394 antes do bloco de dados)
- [x] **Condicionais**: `IF`/`IFT`/`IFE`/`IFF`/`IFDEF`/`IFNDEF`/`IF1`/`IF2`/`ELSE`/`ENDIF`
      (`IFB`/`IFNB`/`IFIDN`/`IFDIF`/`IFIDNI`/`IFDIFI`/`IFABS`/`IFREL`/`IFCPU`/`IFNCPU` ficaram de fora
      — formas raras, não fazem parte de "macros básicas")
- [x] **Macros básicas**: `MACRO`/`ENDM`/`EXITM`/`LOCAL`, sintaxe `nome MACRO p1,p2` (nome em posição
      de rótulo, `:` opcional — igual a `EQU`/`DEFL`/`ASET`), parâmetros substituídos por posição,
      `LOCAL` gera um sufixo único por expansão (evita colisão de rótulo interno entre invocações da
      mesma macro). Implementado em `Z80Asm::ExpandLines()` — roda **uma vez no início de cada pass**
      (não uma vez só pro `Assemble()` inteiro inteiro), produzindo uma lista "achatada" sem
      `IF`/`MACRO`/`ENDM` nenhum, que só então passa pelo processamento normal de linha. Isso é o que
      permite `IF1`/`IF2` verem o pass certo. Fora de escopo desta fase: `REPT`/`IRP`/`IRPC`/`IRPS`,
      aninhamento de macro nomeada dentro de macro nomeada (não suportado nem no Nestor80), o
      modificador `&` de colagem de texto e os prefixos `!`/`%` de passagem de argumento (ver
      `docs/reference/nestor80-language.md`) — todos ficam pra Fase C se algum dia forem pedidos.
      **Validado contra `N80.exe`**: `sample/teste2_macros.asm` (novo arquivo, cobre os 6 tipos de
      condicional + uma macro chamada 2x testando `LOCAL`) → **21 bytes idênticos byte a byte**
- [x] `editor/tools/Z80AsmTestCli.pb` — suíte unitária (59 casos: vocabulário/expressão/ParseLine) +
      **modo `--assemble <entrada.asm> <saida.bin>`** pra comparação binária direta contra `N80.exe`
- [x] **`sample/teste_opcodes.asm`** (206 linhas, ~190 formas de instrução distintas — ORG/EQU/rótulos/toda a
      família de mnemônicos incl. IX/IY/indexado/indocumentado) — **suíte de regressão oficial deste
      módulo, mesmo papel de `sample/teste.dmx` pro pré-processador Dignified**. Rodar depois de
      qualquer mudança em `Z80Asm.pbi`:
      ```
      editor\tools\Z80AsmTestCli.exe --assemble sample\teste_opcodes.asm saida_minha.bin
      nestor80\N80\bin\Release\net6.0\N80.exe sample\teste_opcodes.asm saida_oracle.bin
      fc /b saida_minha.bin saida_oracle.bin
      ```
- [x] **Validação byte-a-byte contra `N80.exe`**: `sample/teste_opcodes.asm` produz **394 bytes idênticos**
      byte a byte ao `N80.exe` real (confirmado 2026-07-24). Suíte unitária: 59/59 também passando.
- [x] **Menu "Montar" no editor** — `Executar → Montar Assembly (.bin)...` (`Ctrl+F5`),
      `AssembleZ80FromActiveTab()` em `BadigEditor.pb`, habilitado quando `Docs()\Mode = "ASM"`,
      salva via `SaveFileRequester`, erro mostra linha + mensagem
- [x] Atualizar `docs/SPEC.md` módulo 2 (+ módulo 2b/2c), `README.md` (bullet + changelog + créditos
      ao Nestor Soriano/Konamiman) e `docs/MANUAL.md` (nova seção "Assembler Z80") — **Fase A 100%
      completa e documentada em todos os `*.md` do projeto**, versão embutida `7.3.1`

## Checklist Fase B (em andamento a partir de 2026-07-24)

- [x] `docs/reference/nestor80-rel-format.md` + `nestor80-linker.md` — extraídos de
      `RelocatableFileFormat.md`/`WritingRelocatableCode.md` + leitura direta do C# do linker
      (`Linker/RelocatableFilesProcessor.cs`)
- [x] **`LK80.exe`/`LB80.exe` compilados localmente** (mesma receita do `N80.exe`) — oráculo de teste
      também pro linker e pro gerenciador de biblioteca, não só pro assembler
- [x] **Escritor de bit-stream genérico** (`RelW_*` em `Z80Asm.pbi`, seção logo depois de
      `EncodeInstruction`) — primitivas de baixo nível que espelham `Assembler/Relocatable/
      BitStreamWriter.cs` + a camada `WriteByte`/`WriteAddress`/`WriteLinkItem`/`WriteSymbolField`
      de `Assembler/OutputGenerator.cs` do Nestor80: `RelW_WriteBits()` (empacotador MSB-first cru,
      buffer próprio `RelBuf()` que cresce por dobra via `ReDim` 1D), `RelW_WriteExtendedHeader()`
      (cabeçalho fixo de 16 bytes), `RelW_WriteByteItem()` (byte absoluto, prefixo `0`),
      `RelW_WriteValueItem()` (valor relocável, prefixo `1`+2 bits segmento+16 bits LE),
      `RelW_WriteLinkItem()` (item de link, prefixo `100`+4 bits tipo+campos opcionais de
      endereço/símbolo), `RelW_WriteSymbolField()` (campo de símbolo formato estendido, com a
      lógica de escape `FFh`+tamanho pra símbolos >7 bytes). Só o formato ESTENDIDO do Nestor80 é
      suportado (recomendação da própria doc de referência). **Validado byte a byte reproduzindo um
      `.REL` real do `N80.exe`** (programa mínimo `cseg`/`public start`/`ld a,1`/`ret`/`end`, 55
      bytes) — ver log de decisões técnicas abaixo pro método de validação (decodificador Python
      bit a bit escrito pra confirmar o entendimento do formato antes de portar). Suíte unitária:
      64/64 (5 novos casos).
- [x] **Serialização `.REL` real, integrada ao driver de 2 passes** (`RunOnePassRel()`/
      `AssembleRelocatable()`/`NeedsRelocatable()` em `Z80Asm.pbi`, logo depois do escritor de
      bit-stream) — driver de 2 passes DEDICADO ao modo relocável, separado de `RunOnePass()`/
      `Assemble()` (Fase A, absoluto — **intocados**, zero mudança de comportamento, convivem lado a
      lado). `ASEG`/`CSEG`/`DSEG`/`COMMON`/`PUBLIC`/`ENTRY`/`GLOBAL`/`EXTRN`/`EXT`/`EXTERNAL` passam a
      ter efeito de verdade (só no driver relocável — no absoluto continuam reconhecidas-sem-efeito,
      de propósito, Fase A nunca foi validada com segmentos reais):
      - **Contador de localização por área** (`RelLocASEG`/`CSEG`/`DSEG`/`COMMON`, `COMMON` reseta pra
        0 a cada entrada, `ORG` funciona dentro de qualquer área) — `SetLocationCounter`/
        `SelectCommonBlock` emitidos nas trocas de área.
      - **`PUBLIC`/`ENTRY`/`GLOBAL`** (e rótulo com `::`) — `EntrySymbol` no início do arquivo,
        `DefineEntryPoint` no final (valor+segmento resolvidos depois do pass 1).
      - **`EXTRN`/`EXT`/`EXTERNAL` como referência BARE** (operando de `CALL`/`JP`/`LD nn` ou de `DW`
        = só o nome do externo, nada mais) — mecanismo de "corrente" (`ChainExternal`,
        `RelWriteExternalChainRef()`): a 1ª referência grava `00 00`, referências seguintes ao mesmo
        nome apontam pra posição da anterior, formando lista encadeada que o linker percorre.
      - **Aritmética de expressão ficou segment-aware de verdade** (`EvalPostfixExpr`, que desde a
        Fase A só sabia lidar com `#Z80Seg_Absolute` — groundwork deliberadamente deixado pronto):
        `reloc±abs`/`abs+reloc` = reloc; `reloc-reloc` mesmo segmento = abs; qualquer outra combinação
        com operando relocável (`reloc+reloc`, `reloc-reloc` de segmentos diferentes, `*`/`/`/`MOD`/
        shift/bitwise/relacional com operando relocável) = **erro explícito** (precisaria do item de
        extensão RPN, fora de escopo). Risco zero pro Fase A: todo teste existente já tinha
        `SegType` sempre `Absolute`, então o comportamento não muda em nenhum caso já validado.
      - **`DS`/`DEFS` sem valor de preenchimento explícito não materializa bytes** — replica o
        comportamento padrão do `N80.exe` (só avança o contador via `SetLocationCounter`, igual
        `ORG $+tamanho`), achado durante a validação por oráculo (ver log técnico).
      - **Fora de escopo nesta etapa, erro explícito em vez de resultado silenciosamente errado**:
        expressão externa composta (ex. `(FOO+1)*2`, precisaria do item de extensão RPN — só a forma
        bare `FOO`/`CALL FOO` é suportada), valor relocável truncado pra 1 byte (`DB`/`DC`/`DZ`/`HIGH`/
        `LOW` de símbolo relocável — `ExpandDataOperand` agora rejeita explicitamente), `.PHASE`/
        `.DEPHASE` dentro do modo relocável, biblioteca/`.REQUEST` (trabalho do futuro
        `Z80Link.pbi`/`Z80Lib.pbi`, não do assembler).
      **Validado byte a byte contra o `N80.exe` real** em 3 programas (`sample/teste4_rel_public.asm`
      — `cseg`+`public` simples; `sample/teste5_rel_dseg.asm` — `cseg`+`dseg`+`public`+`DW` relocável+
      `DS` sem preenchimento; `sample/teste6_rel_extrn.asm` — `EXTRN` bare com `CALL`/`LD`, corrente de
      externo), suíte de regressão oficial do driver relocável (mesmo papel de
      `sample/teste_opcodes.asm` pro driver absoluto), fixados como testes self-contained (bytes
      esperados embutidos no harness, não precisam do `N80.exe` presente pra rodar). Suíte unitária:
      **67/67** (3 novos casos). Regressão absoluta (`teste_opcodes`/`teste2_macros`/`teste3_phase`)
      continua 100% idêntica ao oráculo — nenhuma mudança de comportamento no driver Fase A.
- [x] **`editor/Z80Link.pbi` (`DeclareModule Z80Link`) — linker, corte 1: múltiplos `.REL` SEM
      biblioteca ainda** (`RR_*` leitor de bit-stream, espelha `Z80Asm::RelW_*` ao contrário +
      `ProcessProgram()`/`LinkFiles()`, algoritmo extraído direto de
      `Linker/RelocatableFilesProcessor.cs` — ver `docs/reference/nestor80-linker.md`). Concatena
      `CSEG`/`DSEG`/`COMMON` de todos os módulos (endereço-base = fim do programa anterior + 1,
      começando em `0103h` — convenção CP/M/LINK-80), `ASEG`, resolve `PUBLIC`↔`EXTRN` (corrente
      `ChainExternal` — mesmo mecanismo do lado escritor, agora percorrido ao contrário — +
      `ExternalPlusOffset`/`MinusOffset`), detecta símbolo público duplicado entre programas. Só o
      modo de sequenciamento **padrão** do LK80 ("dados antes de código", igual ao LK80 sem nenhum
      argumento) — `--code`/`--data`/`--align-code`/`--align-data`/`--code-before-data` **fora de
      escopo nesta etapa**. **Validado byte a byte contra o `LK80.exe` real** em 3 cenários
      (`sample/teste4_rel_public.rel` sozinho; `sample/teste7_link_main.rel`+`teste7_link_lib.rel` —
      `PUBLIC`/`EXTRN` cruzado nos dois sentidos, incl. `LD A,(externo)` via corrente; `sample/
      teste8_link_common_a.rel`+`teste8_link_common_b.rel` — bloco `COMMON` compartilhado entre
      módulos com rótulos diferentes resolvendo pro mesmo endereço) — **os 3 bateram byte a byte já
      na primeira tentativa completa** (ver log de decisões técnicas). Suíte própria
      `editor/tools/Z80LinkTestCli.pb` (3/3, self-contained, bytes fixados).
      **Achado durante a validação end-to-end**: `LD A,(externo)`/`LD HL,(externo)` (referência
      externa via endereçamento indireto, não só `CALL externo`) não era reconhecida como referência
      *bare* — o texto do operando ainda tinha os parênteses (`"(shareddata)"`) quando comparado
      contra o nome puro do símbolo desconhecido; corrigido com um helper (`BareExternKeyOf()` em
      `Z80Asm.pbi`) que tira uma camada de parênteses antes de comparar, usado tanto no `DW` quanto
      nas instruções de CPU.
      **Fora de escopo nesta etapa** (erro explícito): item de extensão RPN (tipo 4), `.REQUEST`/
      biblioteca (tipo 3 — fica pro corte 2, junto de `Z80Lib.pbi`), `--code`/`--data`/`--align-*`/
      `--code-before-data`, detecção de sobreposição de segmento entre programas (feature de
      diagnóstico, não bloqueia linkagem correta de fonte bem-formado), saída Intel HEX.
- [x] **`.REQUEST`/pesquisa de biblioteca no linker — corte 2** (`LLoadRequestedLibraryFile()`/
      ponto fixo em `LinkFiles()`, `Z80Link.pbi`) — resolve externos pendentes procurando em
      arquivo(s) de biblioteca pedidos via `.REQUEST` (agora suportado como diretiva de verdade no
      assembler também, `RunOnePassRel`), indexando o(s) símbolo(s) público(s) de **cada programa
      individualmente** (não do arquivo inteiro) e só carregando (`ProcessProgram`) o(s) programa(s)
      que resolvem algo pendente — linkagem estática seletiva de verdade, pedido original do
      usuário. Loop de ponto fixo (repete até uma rodada não carregar nada novo) cobre resolução
      **transitiva** (um programa de biblioteca carregado que ele mesmo precise de outro símbolo,
      da mesma ou de outra biblioteca pedida).
      **Achado importante da validação**: o `LK80.exe` local desta máquina tem uma limitação/bug
      confirmado empiricamente (repro isolado, ver log de decisões técnicas) — só enxerga o símbolo
      público do **primeiro** programa de uma biblioteca `.REQUEST` com mais de um programa; pedir
      um símbolo do segundo (ou posterior) programa sempre falha com "can't resolve external symbol
      reference", mesmo com o arquivo de biblioteca perfeitamente válido (conferido decodificando
      byte a byte). Por isso a validação usou duas estratégias complementares: **oráculo direto**
      pros casos que o `LK80.exe` local resolve corretamente (biblioteca de 1 programa; biblioteca de
      2+ programas pedindo o primeiro) — bateram byte a byte; **auto-consistência** pro caso que o
      oráculo não consegue validar (pedir o segundo/terceiro programa) — comparado contra o binário
      de uma biblioteca EQUIVALENTE onde o símbolo pedido é reordenado pra ser o primeiro (deveria
      dar exatamente os mesmos bytes de saída, já que só o programa referenciado deveria entrar
      de qualquer forma) — bateu. Cadeia transitiva de 3 níveis (`funcx→funcy→funcz`, cada um num
      programa diferente da mesma biblioteca) também validada dessa forma. Suíte própria: 2 novos
      casos em `Z80LinkTestCli.pb`.
- [x] **`editor/Z80Lib.pbi`** (`DeclareModule Z80Lib`, equivalente Libstor80/LB80) — `create`/`add`
      (`CreateOrAddLibrary()`), `list` (`ListLibrary()`), `remove` (`RemoveProgram()`). **Achado que
      simplificou muito `create`/`add`**: como `Z80Asm::RelW_ForceByteBoundary()` sempre roda
      imediatamente antes do item "Fim de arquivo" (7 bits `100`+`1111`, nunca byte-alinhado por si
      só), esse item **sempre** ocupa exatamente o ÚLTIMO BYTE de qualquer `.REL` de programa único,
      sempre valendo `9Eh` (7 bits do item + 1 bit de padding) — confirmado em todo `.REL` gerado
      nesta sessão. Ou seja, "criar uma biblioteca" não precisa entender bit-stream nenhum: é só
      concatenar os bytes de cada `.REL` de entrada, cortando o ÚLTIMO BYTE de todos menos o último
      pedaço escrito (que mantém seu próprio "Fim de arquivo", virando o terminador único da
      biblioteca inteira). `list`/`remove` aí sim precisam de leitura de verdade (achar nome de
      programa/símbolos públicos/fronteiras entre programas) — cópia trivial do mesmo leitor de
      `Z80Link.pbi` (mesmo espírito de não compartilhar lógica pequena entre módulos já documentado).
      **Validado byte a byte contra o `LB80.exe` real**: `create`(moda)+`add`(modb) produz arquivo
      **idêntico** ao `LB80.exe create`+`LB80.exe add` na mesma sequência; `remove` conferido
      comparando contra o `.REL` de programa único equivalente (biblioteca de 1 programa só = o
      próprio `.REL` daquele programa, byte a byte idêntico). Suíte própria: 2 novos casos.
- [x] **Menu/UI do linker e da biblioteca — implementado (2026-07-25)**: `editor/Z80LinkGui.pbi`
      (**Executar → Linkar (.REL) → binário...**, lista ordenável de `.REL` + pasta de biblioteca
      opcional + botão Linkar) e `editor/Z80LibGui.pbi` (**Criar → Biblioteca Z80 (.LIB)...**,
      Nova/Abrir + lista de programas + Adicionar .REL/Remover selecionado — sem cópia de rascunho
      temporária, `Z80Lib.pbi` já grava atômico no arquivo escolhido). Novo item **Executar → Montar
      Assembly relocável (.REL)...** (`AssembleZ80RelFromActiveTab()` em `BadigEditor.pb`) fecha o
      "fluxo multi-arquivo": monta uma aba `.asm` em `.REL`, que aí sim vira insumo do linker/
      biblioteca a partir do editor, sem precisar do CLI de teste. Ver "Log de decisões técnicas"
      abaixo pro bug de `XIncludeFile` pego durante essa integração.
- [ ] `--code`/`--data`/`--align-code`/`--align-data`/`--code-before-data` do linker, detecção de
      sobreposição de segmento entre programas, saída Intel HEX — fora de escopo dos cortes 1/2

## Integrações planejadas (não fazem parte da Fase B em si, mas foram confirmadas como objetivo do
## módulo em 2026-07-24 — ver decisão de escopo 5 acima)

- [x] **Sistema de projeto — implementado (2026-07-25)**: tabela `asm_builds` em `ProjectDB.pbi`
      (`StoreAsmBuild`/`FetchAsmBuild`/`HasAsmBuild`/`ListAsmBuildKeys`, mesmo padrão DELETE+INSERT dos
      demais tipos de conteúdo), chave = caminho do `.asm` (montagem simples) ou `"LINK|" + .rel's` na
      ordem escolhida (sessão de link, sem uma única aba de origem) — guarda build_kind/output_kind/
      output_path/endereços/flag de cabeçalho da **última** exportação que virou arquivo de verdade.
      Gravada automaticamente por `Z80Out_ExportBin`/`Z80Out_ExportDisk` (`Z80OutputGui.pbi`). Fora da
      soma de `HasUnsavedContent()` de propósito, mesmo motivo de `documents` (metadado de algo já
      exportado pra um arquivo independente em disco). Coberto por round-trip em
      `editor/tools/ProjectDBTestCli.pb`.
- [x] **Cabeçalho MSX BLOAD** (2026-07-24, achado real depurando o programa do usuário) — "Montar"
      pergunta se quer o `.bin` com o cabeçalho clássico de 7 bytes (`FE`+início+fim+execução, exec =
      início) já embutido, pronto pro `BLOAD "ARQUIVO.BIN",R` do MSX-BASIC. Binário cru continua
      disponível (opção "Não") e já serve como `.COM` quando o fonte usa `ORG 100h` — nenhuma mudança
      extra precisou ser feita pro `.COM`, o binário absoluto que já existia desde a Fase A já é
      exatamente esse formato.
- [x] **`BLOAD` direto num `.dsk` — implementado (2026-07-25)**: `Z80Out_ExportDisk()` em
      `editor/Z80OutputGui.pbi` monta um `.dsk` (reaproveitando `MSXDisk.pbi`, mesma mecânica de
      `RunOnOpenMSX()`) com o binário sempre-com-cabeçalho mais um `AUTOEXEC.BAS` de autorun
      (`10 BLOAD"NOME.BIN",R`) — abrir esse disco no openMSX já carrega e roda sozinho. Uma das três
      opções da janela "Saída da montagem" (`Z80Out_ChooseAndExport`), ao lado de `.bin` solto e do
      listing hexadecimal abaixo.
- [x] **Listing hexadecimal — implementado (2026-07-25)**: `Z80Gen_BasicLoader()` em
      `editor/Z80OutputGui.pbi` gera um loop `FOR/READ/POKE` + blocos `DATA` em hexa (16 bytes por
      linha, mesmo espírito de `PsgGen_RawBytes()` do editor de som PSG, mas com o loop de `POKE` que
      o PSG não precisa) numa janela com **Copiar**/**Injetar no cursor**. Validado por um script
      isolado conferindo a formatação exata (quebra de linha a cada 16 bytes, caso de 1 byte só).
- [x] **`.COM` direto (MSX-DOS, independente do MSX-BASIC) — implementado (2026-07-25)**: pedido
      explícito do usuário — `Z80Out_ExportCom()` em `editor/Z80OutputGui.pbi`, quarto botão da janela
      "Saída da montagem" (**Gerar .COM (MSX-DOS, independente do BASIC)...**). Sempre grava sem
      cabeçalho nenhum (um `.COM` CP/M/MSX-DOS clássico não tem cabeçalho — o próprio sistema
      operacional carrega em `0100h` e pula pra lá) e avisa (sem bloquear) se `StartAddr <> 0100h`, já
      que nesse caso o binário provavelmente não vai rodar certo (endereços absolutos calculados a
      partir de outro `ORG`). Reaproveita `Z80Out_WriteBinFile()` sem nenhuma mudança (já era
      exatamente esse formato quando chamado com `AddHeader = #False`) — a única lógica nova é o aviso
      de endereço e o novo `output_kind = "COM"` em `ProjectDB::StoreAsmBuild()`.
- [x] **`.PHASE`/`.DEPHASE`** (2026-07-24) — necessário pro caso geral de "código montado num
      endereço, mas com labels resolvendo como se rodasse noutro" (ROM→RAM, ou o próprio cabeçalho
      BLOAD que precisa vir ANTES do código no arquivo mas sem deslocar os labels do código). Ver log
      técnico abaixo pro mecanismo (`RealPos` vs. `CurLoc`) e `sample/teste3_phase.asm` (exemplo oficial
      do próprio manual do Nestor80/MACRO-80, validado idêntico byte a byte, 47 bytes)

## Assembly Sub Project — "Makefile primitivo" (implementado 2026-07-25)

Pedido explícito do usuário: **Criar → Assembly Sub Project...** — um subprojeto onde o usuário junta
vários `.asm` (cada um vira um `.REL` na hora do build) mais bibliotecas referenciadas via `.REQUEST`,
numa lista com ORDEM, e manda montar tudo de uma vez num binário final (`.bin`/`.com`), com opção de
gerar bibliotecas a partir de um subconjunto dos `.asm` do próprio subprojeto e adicioná-las à lista.

- [x] **Motor** (`editor/Z80SubProject.pbi`, sem GUI): `Z80SubProj_Build(List AsmPaths, List LibPaths,
      Array OutBytes)` monta cada `.asm` em `.REL` (`Z80SubProj_AssembleAllToRel`, pasta de trabalho
      temporária dedicada, `Z80SubProj_WorkDir()`) e linka tudo (`Z80Link::LinkFiles`), devolvendo o
      binário final + endereços via getters. `Z80SubProj_BuildLibraryFromAsm(List AsmPaths, LibPath)`
      monta um subconjunto e empacota via `Z80Lib::CreateOrAddLibrary`.
- [x] **Achado real: extensão obrigatória `.rel` pra bibliotecas via `.REQUEST`** — `Z80Link::
      LResolveLibPath()` sempre resolve um nome de `.REQUEST` bare pra `"<nome>.rel"` dentro da pasta
      de biblioteca (SEMPRE anexa `.rel`, mesmo que o nome já termine em `.lib` — vira `"nome.lib.rel"`,
      nunca encontrado). Isso significa que a extensão `.lib` sugerida por `editor/Z80LibGui.pbi`
      (**Criar → Biblioteca Z80 (.LIB)...**, sessão anterior) **não funciona sozinha** com `.REQUEST` -
      só o nome-base do arquivo importa. Corrigido no nível certo (o subprojeto, que é quem realmente
      monta a `LibraryDir` passada pro linker): `Z80SubProj_StageLibraries()` copia cada biblioteca da
      lista do usuário (de qualquer extensão/pasta) pra uma pasta de trabalho temporária, RENOMEANDO
      pra `"<nome-base>.rel"` antes de linkar — o usuário pode continuar salvando bibliotecas como
      `.lib` sem problema, o subprojeto normaliza sozinho. `Z80LibGui.pbi`/`Z80Lib.pbi` não precisaram
      de nenhuma mudança (o "bug" não é deles — `Z80Lib::CreateOrAddLibrary` nunca exigiu extensão
      nenhuma, é só a resolução de `.REQUEST` no linker que é rígida quanto a isso).
- [x] **Persistência** (`ProjectDB.pbi`): tabela `asm_subprojects` — `asm_files`/`lib_files` como TEXT
      unidos por `Chr(10)` na ordem escolhida (mesmo padrão de `mml_songs`), `Store`/`Fetch`/`Has`/
      `List` completos. Diferente de `asm_builds` (metadado de algo já exportado, fora da soma), um
      subprojeto é configuração de verdade sem cópia em nenhum outro lugar — **entra** na soma de
      `HasUnsavedContent()`.
- [x] **GUI** (`editor/Z80SubProjectGui.pbi`) — mesma barra de projeto (número/tag/navegação/Novo/
      Registrar, reaproveitando `SpriteEd_FindNavTarget`/`SpriteEd_CreateNewSpriteIcon`/
      `CreateRegisterIcon` do editor de sprites) dos demais tipos de conteúdo registrados no
      `.msxproject`. Duas listas lado a lado (`.asm` com Adicionar/Remover/Subir/Descer + seleção
      múltipla; bibliotecas com Adicionar/Remover), botão **"Gerar biblioteca a partir dos .ASM
      selecionados..."** (sem nada marcado, usa a lista inteira) que oferece adicionar a lib recém-
      gerada à lista do subprojeto, e **"Montar tudo (Build)..."** que chama `Z80SubProj_Build()` e
      manda o resultado pro mesmo escolhedor de saída do assembler/linker (`Z80Out_ChooseAndExport`,
      `Z80OutputGui.pbi`) — `.bin`/`.com` (o usuário escolhe a extensão ao salvar), disco `.dsk` ou
      listing BASIC.
- [x] **Validação ponta a ponta** (`editor/tools/Z80SubProjectTestCli.pb`, 4/4, self-contained): monta
      os pares `.asm` reais de `sample/teste7_*`/`teste8_*` (PUBLIC/EXTRN cruzado; bloco `COMMON`
      compartilhado) DIRETO dos fontes `.asm` (não dos `.rel` já prontos) e confere que o binário final
      bate byte a byte com os mesmos resultados já validados contra o `LK80.exe` real em
      `Z80LinkTestCli.pb` — prova que o "compilar tudo e linkar" ponta a ponta reproduz exatamente o
      que já se sabia correto. Um quarto teste gera uma biblioteca a partir de
      `teste9_link_request_moda.asm`+`modb.asm`, salva com o nome-base exato que
      `teste9_link_request_main.asm` pede via `.request`, e confirma que o build final resolve o
      `.REQUEST` corretamente (só `MODB` entra, `MODA` fica de fora — linkagem estática seletiva).

## Fora de escopo (Fase C, backlog distante)

`REPT`/`IRP`/`IRPC`/`IRPS`, `MODULE`/`ENDMOD` e labels locais/relativos, saída Intel HEX, arquivo de
listagem `.LST`, R800/Z280. (Biblioteca/`.REQUEST` **saiu daqui e entrou na Fase B**, ver acima —
pedido explícito do usuário 2026-07-24.)

## Log de decisões técnicas durante a implementação

_(preenchido conforme a implementação avança — bugs encontrados, ajustes de design em relação ao
plano original, etc., mesmo espírito do "Próximos passos em aberto" do `docs/SPEC.md`)_

- **2026-07-25 (mesmo dia, terceira sessão) — botão "Gerar .COM" na janela de saída**, pedido explícito
  do usuário: "Nas opções de Execução/Assembler, vamos criar uma opção de gerar .COM, assim o
  assembler pode trabalhar independente do MSX BASIC". Não precisou de lógica nova de verdade — o
  binário "cru" (sem cabeçalho) que `Z80Out_WriteBinFile()` já sabia gravar desde a sessão anterior JÁ
  é um `.COM` válido quando `ORG 100h` (documentado desde então em `docs/MANUAL.md`, seção "Montar"),
  só não tinha um botão dedicado — o usuário tinha que usar "Salvar .bin no PC...", responder "Não" na
  pergunta de cabeçalho, e digitar a extensão `.com` manualmente. `Z80Out_ExportCom()` só formaliza esse
  caminho como opção de primeira classe (nome do botão deixa explícito "independente do BASIC", sem
  pergunta de cabeçalho já que `.COM` nunca tem, aviso se `StartAddr <> 0100h`). Decisão de escopo: não
  mexi no caminho de disco (`Z80Out_ExportDisk`, que continua BASIC/BLOAD apenas) nem tentei inventar um
  equivalente "disco MSX-DOS bootável" — o pedido era especificamente sobre gerar o arquivo `.COM`, não
  sobre todo um fluxo de disco MSX-DOS (que teria outras questões em aberto, tipo se MSX-DOS suporta
  autorun tipo `AUTOEXEC.BAT` sem carregar antes um shell/COMMAND.COM — não pesquisado, fora de escopo
  deste pedido).

- **2026-07-25 (mesmo dia, sessão seguinte) — Assembly Sub Project ("Makefile primitivo"), pedido
  explícito do usuário**: "no assembly, vamos criar uma opção Criar->Assembly Sub Project, vamos criar
  um subprojeto onde o usuário pode colocar os arquivos .ASM que vão ser compilados em vários .REL para
  gerar um .BIN ou .COM final, [...] ter opções de gerar LIBs e de adicionar estas libs no projeto
  também". Ver seção "Assembly Sub Project" acima pro detalhe completo do que foi construído; aqui só o
  achado técnico real:
  - **Extensão `.rel` é obrigatória pra qualquer arquivo referenciado via `.REQUEST`** —
    `Z80Link::LResolveLibPath()` (já existente, validado desde a Fase B) sempre resolve um nome bare
    pra `"<nome>.rel"`, mesmo que o nome já termine em `.lib` (vira `"nome.lib.rel"`, nunca encontrado
    de verdade). Isso só virou um problema prático agora porque o Assembly Sub Project é a primeira
    peça que gera E consome bibliotecas dentro do mesmo fluxo (`Z80LibGui.pbi`, sessão anterior, sugere
    `.lib` como extensão default) — sem essa descoberta, uma biblioteca gerada por "Criar → Biblioteca
    Z80..." e depois usada via `.REQUEST` falharia silenciosamente com "não consegui abrir biblioteca".
    Corrigido no lugar certo: `Z80SubProj_StageLibraries()` sempre copia+renomeia pra `.rel` antes de
    linkar, então o usuário pode continuar salvando com qualquer extensão. Pego durante a escrita do
    harness de teste (`Z80SubProjectTestCli.pb`) — a primeira tentativa nomeou o arquivo de teste com um
    prefixo de isolamento (`z80subprojtest_teste9_link_request_lib.rel`) que mudava o nome-BASE e
    quebrava a resolução por motivo completamente diferente (nome não batendo com o `.request` do
    fonte) — dois bugs distintos pegos na mesma sessão de debug, resolvidos separadamente (extensão no
    motor, nome-base no teste).
  - Suíte própria 4/4 (self-contained, sem precisar de `LK80.exe` presente) reconstrói binários já
    validados byte a byte contra o `LK80.exe` real **a partir dos `.asm` originais** (não dos `.rel` já
    prontos), servindo de prova end-to-end de que compilar-e-linkar pelo pipeline novo reproduz
    exatamente o resultado já conhecido correto.

- **2026-07-25 — integração de menu/saída/projeto (checklist Fase B fechado), pedido explícito do
  usuário: "1-Menu de UI para o Linker/Lib, 2-Saida consumivel do assembler para o MSX BASIC, 3
  integracao do assembler com o sistema de projeto"**. Resumo do que foi construído nas checklists
  acima; aqui só os dois achados técnicos reais da sessão:
  - **Bug real de `XIncludeFile`**: `Z80Asm.pbi` e `Z80Link.pbi` cada um fazia seu próprio
    `XIncludeFile "Z80RelFormat.pbi"` de dentro do respectivo `DeclareModule` — o padrão já
    documentado no topo de `Z80RelFormat.pbi` ("cada Module inclui a própria cópia porque um Module
    não enxerga tipos de fora"). O que não estava documentado (porque nunca tinha acontecido): o
    PureBasic `XIncludeFile` deduplica por **caminho de arquivo em TODO o programa**, não por
    `Module` — então quando os dois módulos passaram a coexistir na mesma unidade de compilação
    (`BadigEditor.pb`, ao ligar `Z80LinkGui.pbi`/`Z80LibGui.pbi` no editor), a segunda tentativa de
    incluir `Z80RelFormat.pbi` (de dentro de `DeclareModule Z80Link`) virou no-op silencioso, deixando
    `#Z80Seg_Code`/`#Z80Seg_Data`/etc. inexistentes dentro do namespace de `Z80Link` — erro só
    aparecia em `LEffectiveAddr()` ("Constant not found: #Z80Seg_Code"). Nunca tinha sido pego porque
    `editor/tools/Z80LinkTestCli.pb` (o único lugar que compilava `Z80Link.pbi` até então) nunca
    incluía `Z80Asm.pbi` na mesma unidade. **Correção**: `editor/Z80RelFormatLink.pbi`, uma cópia
    dedicada (mesmo conteúdo, arquivo com nome diferente) só pro `Module Z80Link` — resolve porque
    `XIncludeFile` dedupe por CAMINHO, então um caminho diferente sempre inclui de verdade. Lição:
    "cada Module tem sua cópia" de um arquivo de tipos compartilhado só funciona de verdade se cada
    cópia estiver num ARQUIVO distinto, não apenas numa seção de código reincluída do mesmo arquivo.
  - **Limitação de ambiente, não do código**: tentativa de smoke test ao vivo via `WM_COMMAND`/
    `PostMessage` (mesma técnica de automação já usada em sessões anteriores pra Psg/Mml/Screen2)
    não funcionou neste ambiente — o processo do `BadigEditor.exe` lançado pelas ferramentas de
    shell (Bash/PowerShell) abre sua janela numa sessão do Windows diferente da sessão onde essas
    mesmas ferramentas rodam (`Get-Process` enxerga o `MainWindowTitle` cross-session, mas
    `FindWindow`/`PostMessage`, que dependem do window station/desktop do processo CHAMADOR, retornam
    handle 0). Não é uma regressão nem um bug do editor — é isolamento de sessão do ambiente de
    execução das ferramentas automatizadas. Verificação da UI nova (`Z80LinkGui.pbi`/`Z80LibGui.pbi`/
    `Z80OutputGui.pbi`) ficou por revisão de código cuidadosa + validação das APIs de motor via CLI
    (`Z80AsmTestCli.exe`/`Z80LinkTestCli.exe`/`ProjectDBTestCli.exe`, todos passando sem regressão) em
    vez de clique real — mesma limitação, reforçada, das notas de sessões anteriores sobre automação
    de canvas não ser confiável neste tipo de ambiente. Versão embutida no executável atualizada de
    `7.3.3` pra **`7.3.5`**.
- **2026-07-24 — gotcha real de PureBasic descoberto e confirmado empiricamente: um `Module` não
  enxerga NENHUMA `Structure`/`Enumeration` definida fora dele**, nem para uso como campo aninhado
  (`Field.OutraStructure`) nem como tipo de parâmetro de ponteiro (`*P.OutraStructure`) — mesmo que a
  `Structure` externa esteja definida bem antes, textualmente, do `Module`. Confirmado com um
  repro mínimo isolado (`Structure Outer` global + `Module Foo` tentando usar `Outer` → erro
  "Structure not found: Outer", tanto pra campo aninhado quanto pra parâmetro `*P.Outer`).
  **Correção**: a `Structure`/`Enumeration` precisa ser declarada **dentro do próprio
  `DeclareModule ... EndDeclareModule`** (não só dentro do `Module ... EndModule` — `DeclareModule`
  só aceita declarações, não corpo de `Procedure`, então isso força uma separação: tipos entram via
  `XIncludeFile` dentro do bloco `DeclareModule`, e `Procedure`s que os usam entram separadamente
  dentro do `Module`). Confirmado funcionando com um segundo repro (`Structure Outer` dentro de
  `DeclareModule Foo`, usada sem qualificar dentro do próprio módulo, e como `Foo::Outer` de fora).
  **Mesma causa raiz do comentário já existente em `ProjectDB.pbi` sobre `DefaultCharsetMsx.pbi`**
  ("um Module nao enxerga procedures/DataSection definidas fora dele") — só que aqui o problema pega
  `Structure`/`Enumeration` também, não só `Procedure`/`DataSection`.
  **Efeito na arquitetura**: `editor/Z80RelFormat.pbi` (destinado a ser compartilhado entre
  `Z80Asm.pbi` e o futuro `Z80Link.pbi`, Fase B) só pode conter `Structure`/`Enumeration` — nenhuma
  `Procedure` — e é incluído via `XIncludeFile "Z80RelFormat.pbi"` **de dentro do
  `DeclareModule Z80Asm`** (não mais no topo de `BadigEditor.pb` junto com os outros
  `XIncludeFile`). Os 3 helpers pequenos que antes estavam nesse arquivo (`Z80Addr_Make`/
  `Z80Addr_IsAbsolute`/`Z80Addr_SameSegment`) moraram para dentro do `Module Z80Asm` — quando o
  `Z80Link.pbi` da Fase B existir, ele terá sua própria cópia trivial desses 3 helpers (mesmo
  espírito de não compartilhar `Structure`/lógica pequena entre módulos já visto em
  `ProjectDB.pbi`/`psg_sounds`/`screens`, ver comentários lá). Código do `Module` que usa um tipo de
  outro módulo por fora precisa qualificar (`Z80Asm::Z80Addr`), inclusive em código-cliente como
  `editor/tools/Z80AsmTestCli.pb`.
- **2026-07-24 — bug real (não gotcha de linguagem, erro meu) encontrado via o debugger do
  PureBasic** (`pbcompiler.exe ... /DEBUGGER /LINENUMBERING`, dá crash com linha exata em vez de só
  "exit code X"): `EvalPostfixExpr()` fazia `CopyStructure(@Stack(), Out, Z80Addr)` em vez de
  `CopyStructure(@Stack(), *Out, Z80Addr)` — usar o nome do parâmetro sem o `*` em vez do ponteiro de
  verdade. **Notável**: `EnableExplicit` **não pegou isso em tempo de compilação** (seria de se
  esperar um erro "variável não declarada" para `Out`) — compilou limpo e só quebrou em runtime
  ("Invalid memory access, read error at address 3"). Lição: quando uma `Procedure` recebe
  `*Nome.Tipo`, sempre usar `*Nome` (nunca `Nome` sozinho) ao repassar como argumento de ponteiro pra
  outra função — `EnableExplicit` não é uma rede de segurança confiável pra esse erro específico.
  **Como foi encontrado**: compilar com `/DEBUGGER /LINENUMBERING` deu a linha exata do crash
  (diferente do build normal, que só dá "exit code 5" sem contexto) — vale a pena usar essas duas
  flags sempre que um `.exe`/harness crashar sem explicação durante o desenvolvimento deste módulo.
- **2026-07-24 — confirmado por leitura direta do C#** (não só da doc): a tabela de precedência de
  operadores do Nestor80 (`ArithmeticOperator.Precedence` em cada classe de
  `Assembler/Expressions/ExpressionParts/ArithmeticOperators/*.cs`) tem `TYPE`=0, `HIGH`/`LOW`=1,
  `* / MOD SHL SHR`=2, unário `+`/`-`=3, `+`/`-` binário=4, relacionais (`EQ NE LT LE GT GE`)=5,
  `NOT`=6, `AND`=7, `OR`/`XOR`=8 (menor número liga mais forte) — ordem não-óbvia (o `+`/`-` unário
  liga **mais fraco** que `*`/`/`, e `NOT` liga mais fraco que os relacionais) que bateu exatamente
  com o algoritmo de shunting-yard implementado (`Postfixize()` em `Expression.Evaluation.cs`,
  operadores unários sempre empilhados sem checar precedência, só resolvidos no próximo operador
  binário ou `)`). Replicado fielmente em `Z80Asm::OpPrecedence()`/`OpIsUnary()`/`ToPostfixExpr()`.
  Convenção verdadeiro/falso dos operadores relacionais (`FFFFh`/`0000h`) confirmada tanto pelo C#
  quanto por teste real no `N80.exe` (`db 3 eq 3` → byte `255`, ou seja `FFFFh` truncado pro `DB`).
- **2026-07-24 — regra de rótulo que quebraria `EQU`/`DEFL`/`ASET` se implementada ingenuamente**: a
  primeira suposição (rótulo = "primeira palavra da linha, se não bater com nenhuma keyword" — regra
  usada só cosmeticamente pelo highlighter, `HighlightZ80Text()`) está **errada** pro parser de
  verdade. A doc (LR:161) é explícita: rótulo **sempre** precisa terminar em `:`/`::` — não existe
  rótulo implícito por coluna/posição. Só que isso sozinho quebraria a forma clássica e onipresente
  `SIMBOLO EQU valor` (sem `:`) — resolvido porque `EQU`/`DEFL`/`ASET` são os
  "constantDefinitionOpcodes" do Nestor80 (achado já registrado na pesquisa original): quando a
  **segunda** palavra da linha é uma dessas três, a primeira palavra é o símbolo sendo definido,
  mesmo sem `:`. `Z80Asm::ParseLine()` implementa isso com um lookahead de 1 palavra (só quando a
  primeira palavra não tem `:` na sequência) — ver `Structure Z80ParsedLine\LabelHasColon` (distingue
  as duas formas, caso algum consumidor futuro precise saber qual delas foi usada).
- **2026-07-24 — dois bugs pequenos pegos pelos testes (harness compensou bem)**:
  (1) variável local chamada `WEnd` colidiu com a palavra-chave `Wend` do PureBasic
  (`While...Wend`) — erro de compilação claro ("A variable can't be named the same as a keyword"),
  renomeada pra `WStop`. Lição: evitar nomes de variável que sejam também palavra-chave de controle
  de fluxo, mesmo com capitalização diferente (PureBasic é case-insensitive pra palavras-chave).
  (2) `ParseLine()` não tirava o espaço **à esquerda** do texto do comentário (só `RTrimWs`, nunca um
  "skip whitespace" depois do `;`) — `"; foo"` virava `Comment = " foo"` em vez de `"foo"`. Pego por
  4 dos 15 testes novos de `ParseLine` falharem de forma idêntica (mesmo padrão "sobrou um espaço no
  início"), o que tornou o diagnóstico rápido. Corrigido com `SkipWs()` antes do `RTrimWs()`.
- **2026-07-24 — segundo gotcha real de PureBasic (grande): não dá pra passar uma `Structure` POR
  VALOR como parâmetro de `Procedure`** (`Procedure X(Campo.MinhaStructure)`) — só por ponteiro
  (`Procedure X(*Campo.MinhaStructure)`). Confirmado com repro mínimo (`Procedure.i Test(F.Foo, N.l)`
  → "Syntax error" na própria linha da assinatura). Isso derrubou a primeira versão inteira do
  codificador de instruções (~20 procedures `EncodeXxx` recebendo `Z80Operand` por valor). Corrigido
  em massa com um script Perl (`perl -i -pe` com regex de word-boundary + lookbehind negativo pra não
  mexer em usos já corretos como `@Op1`) que converteu assinatura (`Op1.Z80Operand` →
  `*Op1.Z80Operand`), acesso a campo (`Op1\X` → `*Op1\X`) e passagem por valor como argumento (`Op1`
  cru → `*Op1`) em massa, deixando de fora deliberadamente o dispatcher `EncodeInstruction()` (onde
  `Op1`/`Op2` são de fato variáveis locais por valor, preenchidas por `ClassifyOperand(..., @Op1)`) —
  esse precisou de um ajuste manual separado (trocar as chamadas `EncodeXxx(Op1, ...)` por
  `EncodeXxx(@Op1, ...)`). **Lição prática**: ao escrever uma nova `Procedure` que recebe uma
  `Structure` "de leitura" (não é lista/array), já nascer com `*Nome.Tipo` — nunca `Nome.Tipo` puro.
- **2026-07-24 — terceiro gotcha: `Protected NomeArray.tipo(N)` não declara array — precisa de
  `Protected Dim NomeArray.tipo(N)`** (confirmado com repro mínimo). Sem o `Dim`, erro de sintaxe na
  própria linha. Achado ao declarar o buffer temporário de 4 bytes (`Bytes`) dentro do driver de
  passes e o buffer fixo de 64KB (`Mem`) dentro de `Assemble()`.
- **2026-07-24 — quarto gotcha, o mais sutil: `Variavel = Not OutraVariavel` (atribuição direta) é
  erro de sintaxe** ("A variável não pode ter o mesmo nome de uma palavra reservada: Not"), mas
  `If Not OutraVariavel ... EndIf` (contexto condicional) funciona normalmente — confirmado com repro
  isolado. `Not` como operador prefixo só parece ser aceito pelo parser em posição de condição
  booleana, não numa atribuição de valor solta. **Correção**: envolver em `Bool(...)` quando precisar
  do resultado de `Not` como valor atribuível (`X = Bool(Not Y)`), nunca `X = Not Y` cru.
- **2026-07-24 — bug real de lógica (não de sintaxe): ambiguidade "C" registrador vs. "C" condição**.
  `ClassifyOperand()` classifica um `"C"` isolado como `#Z80Opnd_Reg8` (RegCode=1, o mais comum),
  nunca como `#Z80Opnd_Cond` — mas `JP C,nn`/`JR C,e`/`CALL C,nn`/`RET C` também usam exatamente esse
  texto, só que como condição (RegCode de condição = 3, valor diferente!). Pego pelo teste de
  regressão contra `N80.exe` (`sample/teste_opcodes.asm` tem `jp c,start`) — sem o oráculo, um teste unitário
  ingênuo que não cobrisse justo essa combinação passaria batido. Corrigido com um helper dedicado,
  `Z80Asm::CondCodeOf()`, chamado nos 4 pontos que aceitam condição na posição 1 (`JP cc,nn`/
  `JR cc,e`/`CALL cc,nn`/`RET cc`) — trata tanto `#Z80Opnd_Cond` quanto o caso especial "Reg8 com
  RegCode=1" (ou seja, literalmente `C`), devolvendo o código de condição certo (3) nos dois casos.
- **2026-07-24 — bug real de arquitetura do driver de 2 passes: `EQU` "já definido" disparando no
  PASS 2 pra toda constante**. Como `Assemble()` roda os 2 passes sobre a MESMA tabela de símbolos
  (só um `ResetState()` no início, nunca entre os passes — de propósito, pra rótulos definidos no
  pass 1 continuarem visíveis no pass 2), toda linha `EQU` processada no pass 1 batia de novo no pass
  2 contra o próprio guard "EQU não pode ser redefinido" — `sample/teste_opcodes.asm` já tinha um `CONST equ
  42` que disparava isso na primeira tentativa. **Correção**: `DefineSymbol()` só rejeita quando o
  NOVO valor difere do já existente — redefinir um `EQU` com o mesmo valor (exatamente o que
  acontece relendo a mesma linha no pass 2) agora é um no-op silencioso; só um `EQU` genuinamente
  conflitante (duas definições DIFERENTES pro mesmo nome) ainda erra.
- **2026-07-24 — validação por oráculo, resultado**: `sample/teste_opcodes.asm` (206 linhas, ~190 formas de
  instrução distintas cobrindo praticamente toda a tabela — 8 condições de desvio, indexado IX/IY com
  deslocamento positivo/negativo, CB indexado, blocos ED, halves indocumentados IXH/IXL/IYH/IYL)
  monta pra um binário de **394 bytes idêntico byte a byte ao `N80.exe` real**. Esse nível de
  cobertura + comparação binária direta (não só alguns `CheckEval` manuais) dá confiança alta na
  tabela de opcodes inteira, não só nos casos individualmente testados.
- **2026-07-24 — erro de arquitetura pego pelo oráculo, não pelo raciocínio**: a primeira versão de
  `ExpandLines()` (condicionais/macros) rodava como um **pré-processamento totalmente separado**,
  antes de qualquer EQU/rótulo ser resolvido pelo loop principal de `RunOnePass()` — parecia razoável
  ("achatar tudo primeiro, montar depois"), mas quebra o caso mais comum de todos:
  `FLAG equ 1` seguido de `if FLAG` no mesmo arquivo. `sample/teste2_macros.asm` (que tem exatamente
  esse padrão, `DEBUG equ 0` / `if DEBUG`) falhou na primeira tentativa com "símbolo desconhecido:
  DEBUG" — o `EQU` simplesmente ainda não tinha rodado quando o `IF` tentava ler o valor, porque os
  dois vivem em estágios diferentes (macro/condicional resolvido num sub-passo antes de tudo; EQU só
  no loop principal, depois). **Correção**: `ExpandLines()` ganhou uma cópia enxuta da lógica de
  `EQU`/`DEFL`/`ASET` (chamando `DefineSymbol()` na hora, igual o loop principal já faz) — assim
  o walk de cima a baixo do próprio `ExpandLines()` mantém a tabela de símbolos atualizada o
  suficiente pra um `IF` mais adiante NA MESMA passada já enxergar qualquer `EQU` anterior. Rótulo
  (valor = contador de localização) ficou de fora de propósito — `ExpandLines()` não rastreia
  tamanho de instrução/endereço (só `RunOnePass()` faz isso), então um `IF` que dependa do *valor* de
  um rótulo (não de uma `EQU`) é uma lacuna conhecida e aceita nesta fase (padrão raro). Rodar
  `DefineSymbol()` de novo mais tarde no loop principal pro mesmo `EQU` é seguro (mesmo mecanismo de
  "redefinição idêntica é no-op" já implementado pro problema do EQU-duplicado-entre-pass-1-e-pass-2).
  **Lição mais ampla**: mesmo com plano/arquitetura bem pensados de antemão, o oráculo (`N80.exe`)
  continua sendo o jeito mais rápido de achar esse tipo de erro de sequenciamento — o raciocínio
  isolado ("isso devia funcionar") não pegou, o teste ponta a ponta pegou na primeira tentativa.
- **2026-07-24 — groundwork da Fase B**: `LK80.exe` (linker) e `LB80.exe` (gerenciador de biblioteca)
  compilam limpo a partir do mesmo clone `nestor80/` (`dotnet build LK80/LK80.csproj -c Release` /
  `LB80/LB80.csproj` — mesma receita do `N80.exe`), confirmando que os **três** oráculos (assembler +
  linker + biblioteca) estão disponíveis pra validar o port nativo byte a byte, não só o assembler.
  `docs/reference/nestor80-rel-format.md` (formato `.REL` bit-a-bit — não byte-alinhado, precisa de
  um leitor/escritor de bit-stream próprio) e `docs/reference/nestor80-linker.md` (algoritmo completo
  do linker, lido direto do C# já que a doc oficial não descreve o algoritmo em si) escritos. Ainda
  **não iniciada** a implementação de verdade (bit-stream writer/reader, `Z80Link.pbi`, `Z80Lib.pbi`) —
  ver checklist Fase B acima pra retomar.
- **2026-07-24 — fechamento da sessão (Fase A entregue, Fase B pausada por escolha, não por
  bloqueio)**: usuário pediu uma pausa antes de começar a implementação de verdade da Fase B (bit-stream
  writer/reader/linker/biblioteca — trabalho do mesmo porte da Fase A inteira, decisão deliberada de
  não escrever isso às cegas sem espaço pra validar com o mesmo rigor). Documentação atualizada em
  todos os `*.md` do projeto nesta sessão de fechamento: `README.md` (novo bullet dedicado ao
  assembler em "O que já temos", changelog, crédito ao **Nestor Soriano (Konamiman)** — autor do
  Nestor80 — na seção "Agradecimentos"), `docs/SPEC.md` (módulo 2 reescrito com status real + novo
  módulo 2c documentando as integrações planejadas de projeto/BASIC), `docs/MANUAL.md` (nova seção
  "Assembler Z80" — uso prático: aba `.asm`, `Ctrl+F5`, o que é/não é suportado ainda). Versão do
  executável corrigida de `7.2.0` pra **`7.3.1`** — convenção do projeto (registrada em memória
  também, `version_numbering_convention.md`): **minor ímpar = build interno/dev, minor par = release
  de verdade**; como ainda não houve nenhum release, nunca pular pra minor par. **Para retomar a Fase
  B (nesta máquina ou em outra)**: este arquivo já tem tudo — clonar/compilar `nestor80/` (seção
  "Material de referência" acima, agora com N80+LK80+LB80), ler `docs/reference/nestor80-rel-format.md`
  e `nestor80-linker.md` (já escritos), e seguir o checklist "Fase B" + "Integrações planejadas" acima,
  primeiro item pendente é o escritor de bit-stream dentro de `Z80Asm.pbi`.
- **2026-07-24 — dois bugs reais achados pelo primeiro uso de verdade do usuário** (escrevendo um
  programa real, `sample/teste.asm`, não um fixture sintético — mesmo padrão de valor que
  `sample/teste.dmx` já provou pro pré-processador Dignified):
  1. **`(expr) OP expr2` classificava errado.** `ld a, (COLOR_BLUE SHL 4) OR COLOR_BLACK` (M80 não
     tem `<<`/`|` simbólico — só `SHL`/`OR` por extenso, confirmado contra o `N80.exe`: ele também
     rejeita `<<` com "Unexpected character found: <") — o operando começa com `(` mas o `)` que
     fecha não é o último caractere (sobra ` OR COLOR_BLACK` depois). `ClassifyOperand()` exigia que
     `(` e `)` cobrissem o operando inteiro pra reconhecer como `(nn)` (memória) — nesse caso caía
     como `Imm` (imediato), gerando `LD A,n` em vez de `LD A,(nn)`. Testado contra o `N80.exe` real:
     ele trata **qualquer** operando começando com `(` como `(nn)`, mesmo com texto sobrando depois
     do primeiro `)` que fecha — a expressão inteira (parênteses inclusos) é avaliada como um só bloco
     pro endereço. Corrigido: `IndImm` agora dispara só com "começa com `(`" (não precisa mais
     terminar com `)`), e `Expr` guarda o texto ORIGINAL inteiro (parênteses inclusos) em vez de
     tirar as bordas — o próprio avaliador de expressão já sabe tratar `(`/`)` como agrupamento
     normal, então não precisa de nenhuma lógica extra além de não truncar a string. A forma
     `(IX+d)`/`(IY+d)` continua exigindo bater o operando inteiro (essa é uma forma de endereçamento
     de hardware de verdade, não uma expressão comum).
  2. **Mensagem de erro vinha vazia.** Quando `EvalOperandExpr()` falhava dentro de qualquer
     `EncodeXxx`, o `ProcedureReturn -1` não propagava `LastEvalError`/`LastEvalUnknownSymbol` pra
     `LastAsmError` — o usuário via só "linha N:" sem explicação nenhuma. Corrigido num lugar só
     (`EvalOperandExpr()` agora seta `LastAsmError` na hora que ela mesma falha), o que consertou
     automaticamente os ~24 pontos de chamada em todos os `EncodeXxx` de uma vez, sem precisar editar
     cada um. Mensagem agora: `Expressao invalida (...): Caractere inesperado em expressao: '<'`.
  `sample/teste.asm` (nome do usuário) foi sobrescrito pelo programa real dele (SCREEN2 demo) — a
  suíte de regressão original foi preservada em **`sample/teste_opcodes.asm`** (renomeada, mesmo
  conteúdo + um novo caso de teste pro bug 1 acima, `ld a,(CONST SHL 4) OR 5` → 444 bytes, ainda
  idêntico ao `N80.exe`). Todas as referências a `sample/teste.asm` como suíte de regressão em
  `README.md`/`docs/SPEC.md` já foram atualizadas pra `sample/teste_opcodes.asm` (`docs/MANUAL.md` não
  citava o arquivo pelo nome, nada a mudar lá).
- **2026-07-24 — `.PHASE`/`.DEPHASE` implementado a pedido do usuário** (queria gerar `.bin` no
  formato `BLOAD` do MSX — cabeçalho de 7 bytes `FE`+início+fim+execução ANTES do código, mas com os
  rótulos do código resolvendo pro endereço de carga real, não pro endereço-mais-7-bytes onde os
  bytes de fato caem no arquivo). Mecanismo: duas variáveis de posição em vez de uma só —
  **`CurLoc`** (o contador "reportado", usado por rótulos/`$`/matemática de `JR` relativo — é o que o
  CPU realmente vê rodando) e **`RealPos`** (posição real de escrita em `Mem()`). Fora de um bloco
  `.PHASE`, as duas sempre valem o mesmo (avançam juntas a cada instrução/diretiva). `.PHASE <expr>`
  muda só `CurLoc` pro endereço pedido, sem tocar `RealPos` — daí em diante os bytes continuam sendo
  escritos sequencialmente de onde estavam (`RealPos`), mas rótulos/`$`/`JR` dentro do bloco
  "acreditam" que estão no endereço do `.PHASE`. `.DEPHASE` reverte com uma única linha,
  `CurLoc\Value = RealPos` — simples porque `RealPos` já é, por definição, exatamente o valor que
  `CurLoc` teria se o `.PHASE` nunca tivesse acontecido (mesma prova que bate com o exemplo oficial da
  doc, onde o rótulo `CALCULATE_CHECKSUM_END` volta a `402Dh`, batendo exato com `4013h + 1Ah` = o
  tamanho do bloco fasado). **Validado com o exemplo exato do `nestor80/docs/LanguageReference.md`**
  (seção `.PHASE`, código de checksum de ROM copiado por `LDIR` pra RAM) — `sample/teste3_phase.asm`,
  **47 bytes idênticos byte a byte ao `N80.exe`**, incluindo a matemática de `JR`/tamanho de bloco
  calculada via subtração de rótulos atravessando a fronteira do `.PHASE`. Cross-checado também contra
  o manual original da Microsoft (`MACRO-80.txt`, seção 2.6.29 "Relocation Before Loading") — mesmo
  mecanismo, exemplo equivalente (só com mnemônicos 8080 em vez de Z80 no manual original).
- **2026-07-24 — geração de `.bin` com cabeçalho MSX BLOAD, direto pelo menu "Montar"**: em vez de
  obrigar o usuário a escrever o cabeçalho na mão (`DEFB`/`DEFW` + `.PHASE`), `AssembleZ80FromActiveTab()`
  agora pergunta (depois de montar com sucesso) se quer o cabeçalho de 7 bytes embutido automaticamente
  — usa o endereço mínimo/máximo tocado (`Z80Asm::GetAssembleStartAddr()`/`GetAssembleEndAddr()`, novos
  getters que só expõem `MinAddrTouched`/`MaxAddrTouched`, já existentes internamente desde a Fase A)
  como início/fim, e o próprio início como endereço de execução (caso comum: executar onde foi
  carregado). Escrito byte a byte (`WriteByte`, não `WriteWord`) de propósito, pra não depender da
  ordem de bytes nativa da plataforma que compila o editor. `.COM` não precisou de nenhum código novo —
  o binário absoluto que a Fase A já gera, quando o fonte usa `ORG 100h`, já É um `.COM` válido (formato
  CP/M/MSX-DOS não tem cabeçalho nenhum), então a opção "binário cru" do mesmo diálogo já cobre esse
  caso.
- **2026-07-24 — `sample/teste.asm` e `sample/nteste.asm` (programas reais do usuário) ajustados na
  mão pro padrão de cabeçalho BLOAD "fonte-nativo"** (a pedido do usuário, como demonstração de que o
  cabeçalho não depende do diálogo do menu "Montar" — qualquer assembler M80/Nestor80-compatível, ex.
  `N80.exe` puro sem a IDE, já produz o `.bin` pronto). Padrão aplicado igual nos dois arquivos:
  operador `<<`/`|` da linha da paleta de cores (`ld a, (COLOR_BLUE << 4) | COLOR_BLACK`) trocado por
  `SHL`/`OR` (só precisou em `teste.asm` — `nteste.asm` já estava com a sintaxe certa); e o antigo
  `org 0C000h` isolado virou:
  ```
  LOAD_ADDR equ 0C000h
      org 0
      defb 0FEh
      defw LOAD_ADDR
      defw CODE_END - 1
      defw LOAD_ADDR
      .phase LOAD_ADDR
  START:
      ...código original sem nenhuma outra mudança...
  CODE_END:
      .dephase
  ```
  Detalhe importante: `CODE_END:` tem que vir **antes** do `.dephase` (não depois, ao contrário do
  jeito que o rótulo final aparece no exemplo oficial do `LanguageReference.md`) — aqui o objetivo é
  capturar o endereço LÓGICO/fasado (`0xC000 + tamanho do código`) pro campo "fim" do cabeçalho, não o
  endereço real pós-`.dephase`. `CODE_END - 1` é referência-pra-frente pro `defw` do cabeçalho (linha
  bem antes de `CODE_END` existir) — funciona sem problema porque é rótulo (dois passes resolvem),
  diferente de `EQU`, que teria que vir antes do uso. Validado: montado com
  `editor\tools\Z80AsmTestCli.exe --assemble` e com `N80.exe` puro, **315 bytes idênticos byte a byte**
  nos dois arquivos (`fc /b`); cabeçalho conferido na mão: `FE 00 C0 33 C1 00 C0` = marca `FE`, início
  `C000h`, fim `C133h` (= `C000h + 308 bytes de código - 1`), execução `C000h`.
- **2026-07-24 — escritor de bit-stream `.REL` (`RelW_*`), primeiro item de verdade da Fase B**.
  Antes de portar, li o C# fonte real do Nestor80 (`nestor80/Assembler/Relocatable/
  BitStreamWriter.cs` + `Assembler/OutputGenerator.cs`, não só a doc) pra tirar uma ambiguidade que
  a doc (`nestor80-rel-format.md`) não deixa clara sozinha: o prefixo `1` (valor relocável) e o
  prefixo `100` (item de link) colidem em cima do padrão de bits `1`+`00` — parecia que um valor
  relocável de segmento ASEG (`00`) seria indistinguível de um item de link. **Resolvido lendo
  `Linker/Parsing/RelocatableFileParser.cs` (o leitor, não o escritor)**: o parser real primeiro lê
  1 bit (`0`=byte absoluto, `1`=continua), depois 2 bits — só entra no ramo "valor relocável" se
  esses 2 bits forem **diferentes de zero** (`01`=CSEG/`10`=DSEG/`11`=COMMON); `00` sempre quer
  dizer "isso é um item de link, os próximos 4 bits são o tipo". Ou seja **ASEG nunca aparece como
  segmento de um "valor relocável"** (faz sentido: endereço absoluto não precisa de relocação, por
  isso nunca gera esse item) — a ambiguidade não existe de verdade, só parecia existir lendo só a
  tabela da doc sem ver o algoritmo de decisão bit a bit. Dentro de um item de link já identificado
  (depois do `100`+tipo), o campo de endereço opcional aceita ASEG(`00`) normalmente, sem restrição
  nenhuma (não há mais ambiguidade nesse ponto, o parser já sabe que é um item de link).
  **Método de validação**: gerei um `.REL` real mínimo com o `N80.exe` (`cseg`/`public start`/
  `ld a,1`/`ret`/`end`, 55 bytes) e escrevi um decodificador Python bit a bit **do zero**, direto a
  partir do meu próprio entendimento do formato (script descartável, não faz parte do repo) — rodei
  contra os 55 bytes reais e o decode bateu item por item com o que o código-fonte esperava
  (`ProgramName RELMIN`, `EntrySymbol start`, `DataAreaSize ASEG 0`, `ProgramAreaSize CSEG 3`,
  `SetLocationCounter CSEG 0`, bytes crus `3E 01 C9`, `DefineEntryPoint CSEG 0 start`,
  `EndProgram ASEG 0`, `EndFile`) **antes** de escrever uma linha de PureBasic. Só depois portei
  pra `Z80Asm.pbi` e escrevi um teste (`Z80AsmTestCli.pb`) que reproduz a MESMA sequência de
  chamadas `RelW_*` e compara os 55 bytes resultantes contra o `.REL` real, byte a byte — passou de
  primeira, confirmando os dois lados (entendimento do formato E port) de uma vez só. **Lição**: pra
  formatos bit-a-bit não byte-alinhados, vale a pena escrever um decodificador jogável (não
  produção) só pra provar o entendimento antes de portar a lógica de escrita — muito mais barato
  de debugar um script Python solto do que um bug de "off-by-alguns-bits" dentro do PureBasic.
  **Escolhas de escopo**: só o formato ESTENDIDO Nestor80 foi implementado (recomendação da própria
  doc de referência — o legado `--link-80-compatibility` fica de fora, não é necessário pro
  par assembler/linker nativo se entenderem); campo de símbolo estendido suporta o caso comum
  (< 256 bytes, imensamente mais que qualquer identificador Z80 real) com o escape `FFh`+tamanho,
  mas não replica a otimização `WriteDirect` (escrita byte-alinhada direta) que o Nestor80 usa só
  pra símbolos > 255 bytes — já que símbolos desse tamanho não existem na prática, a versão simples
  (via `RelW_WriteBits`, sempre) já basta e é mais fácil de manter correta. Buffer de saída
  (`RelBuf()`) é 1D com `ReDim` por dobra (nunca multi-dim — ver
  `purebasic_redim_last_dim_only.md`), separado do `Mem()` de 64KB fixo do driver absoluto (podem
  coexistir sem conflito, cada um serve um formato de saída diferente). **Ainda não integrado ao
  driver de 2 passes** — `RelW_*` é só a camada de baixo nível (equivalente a `BitStreamWriter.cs`
  puro); consumir isso pra emitir um `.REL` de verdade a partir de `Assemble()` (detectar ASEG-puro
  vs. relocável, percorrer segmentos/símbolos/EXTRN durante os passes) é a próxima tarefa da Fase B,
  já anotada no checklist acima.
- **2026-07-24 — integração do escritor de bit-stream ao driver de 2 passes (`RunOnePassRel`/
  `AssembleRelocatable`), geração de `.REL` real funcionando ponta a ponta**. Decisão de arquitetura
  central: em vez de modificar `RunOnePass()`/`Assemble()` (Fase A, já validado byte a byte contra o
  oráculo, ~190 formas de instrução) pra ficarem "segment-aware", criei um driver **paralelo e
  totalmente separado** (`RunOnePassRel`/`AssembleRelocatable`) que reaproveita as peças que já eram
  segment-agnostic por natureza (`ParseLine`, `EncodeInstruction`, `EncodeDataDirective`,
  `ExpandLines`, `CountOperands`/`GetOperand`, `EvalExpr`) sem tocar nelas, e só reimplementa a parte
  que muda de verdade (o laço principal do driver: como interpretar `ASEG`/`CSEG`/`DSEG`/`COMMON`/
  `PUBLIC`/`EXTRN` e como despejar bytes — `Mem()` linear pro absoluto, `RelW_*` bit-stream pro
  relocável). Isso manteve o risco de regressão em ZERO pro driver absoluto (nem uma linha de
  `RunOnePass()` foi tocada) às custas de duplicar ~150 linhas de estrutura de laço — troca deliberada
  (mesmo espírito já registrado no resumo de "Z80Link.pbi terá sua própria cópia trivial" dos helpers
  de `Z80Addr`, preferir duplicação pequena a acoplamento frágil entre os dois drivers).
  - **Aritmética de expressão precisou ficar segment-aware de verdade** (`EvalPostfixExpr`) — a Fase A
    já tinha deixado um comentário avisando que isso ficaria pendente ("por enquanto os dois operandos
    são sempre absolutos... fica pronta pra quando CSEG/DSEG passarem a valer alguma coisa"). Implementei
    a regra do Nestor80 (`WritingRelocatableCode.md`): `reloc±abs`/`abs+reloc` = reloc (mesmo segmento
    do operando relocável); `reloc-reloc` do MESMO segmento = absoluto (distância entre dois endereços
    do mesmo segmento já é conhecida sem precisar do endereço-base final); qualquer outra combinação
    com pelo menos um operando relocável (`reloc+reloc`, `reloc-reloc` de segmentos diferentes, e todo
    operador que não seja `+`/`-` — `*`/`/`/`MOD`/shift/bitwise/relacional) agora **erra explicitamente**
    em vez de silenciosamente virar um valor absoluto errado (precisaria do item de extensão RPN do
    Nestor80, fora de escopo). Risco de regressão zero: como TODO `SegType` na Fase A é sempre
    `#Z80Seg_Absolute` (só `ASEG` existia), o novo código sempre cai no ramo "os dois são absolutos" pra
    qualquer teste já existente — confirmado rodando a suíte de 444 bytes idênticos de novo depois da
    mudança.
  - **Bug real pego pelo oráculo, não pelo raciocínio: nomes de símbolo em MAIÚSCULO indevido no
    `.REL`**. Primeira tentativa gerou um `.REL` de 59 bytes pro programa `cseg/public start/ld a,1/
    ret/end`, mas divergindo do oráculo bem no meio do arquivo — decodificando manualmente, a diferença
    era `53544152` (ASCII "STAR", meu output) vs `73746172` (ASCII "star", oráculo) dentro do campo de
    símbolo do `DefineEntryPoint`. Causa: eu uppercase-ava o nome ANTES de guardar em `RelPublicOrder()`/
    passar pro `RelW_WriteLinkItem()`, misturando "chave de tabela" (tem que ser maiúscula, comparação
    case-insensitive, como o resto do assembler já faz) com "conteúdo de verdade gravado no arquivo"
    (precisa preservar a grafia ORIGINAL do fonte — doc de referência já avisava: "símbolos UTF-8...
    comparados sem diferenciar maiúsculo/minúsculo", ou seja, comparação case-insensitive mas
    ARMAZENAMENTO com case preservado). Corrigido separando os dois em todo lugar que lida com nome de
    símbolo relocável: `RelPublicOrder()`/`RelChainOrder()`/`RelExternDeclared()` agora guardam a chave
    maiúscula (dedup/lookup) E o valor com a grafia original (`Z80RelChainState\DisplayName`,
    `RelExternDeclared()` virou `Map.s()` em vez de `Map.b()` — guarda a grafia declarada no `EXTRN`,
    não só um flag booleano). Mesma classe de bug (case perdido em bookkeeping) que quase passou batido
    porque o assembler inteiro já uppercasa tudo internamente por convenção (Fase A) — só o oráculo
    binário pegou, um teste que só checasse "montou sem erro" não pegaria.
  - **Segundo achado do oráculo: `DS`/`DEFS` sem valor de preenchimento explícito NÃO materializa bytes
    reais no `.REL`** — o `N80.exe` só avança o contador de localização via um item `SetLocationCounter`
    (equivalente a `ORG $+tamanho`), sem escrever nenhum byte. Minha primeira versão reaproveitava
    `EncodeDataDirective` cegamente (que sempre materializa `tamanho` bytes de `0x00`, comportamento
    CORRETO pro driver absoluto — um binário plano não tem como "pular" bytes) — resultado: 15 bytes
    extra de zeros no meio do arquivo (99 vs 84 bytes esperados). Corrigido dando um `Case` próprio pra
    `DS`/`DEFS` dentro do driver relocável: só materializa bytes de verdade quando o SEGUNDO operando
    (valor de preenchimento) foi dado explicitamente; sem ele, só emite `SetLocationCounter` pulando
    pra frente. `EncodeDataDirective` em si (compartilhado com o driver absoluto) não mudou.
  - **Terceiro achado, não do oráculo mas de compilação: `EncodeInstruction()` (compartilhado com o
    driver absoluto) sempre foi projetado pra ERRAR quando uma expressão de operando não resolve** — o
    comportamento certo pro driver absoluto (símbolo desconhecido é sempre erro fatal), mas quebra na
    hora de codificar `CALL algumexterno` no driver relocável (a expressão "algumexterno" nunca vai
    resolver por definição, é externo). Em vez de modificar `EncodeInstruction()`/`EvalOperandExpr()`
    pra saber sobre `EXTRN` (contaminaria o driver absoluto com um conceito que não existe lá), a
    solução foi: ANTES de chamar `EncodeInstruction()`, classificar o operando-cauda (mesmo mecanismo
    de forma/heurística usado depois pra decidir emitir `RelW_WriteValueItem`); se for uma referência
    bare a um externo declarado, definir um símbolo TEMPORÁRIO (`DefineSymbolSeg(nome, 0, Absoluto,
    ...)`) só pra `EncodeInstruction()` conseguir avaliar a expressão sem erro (os bytes que ele produz
    pra essa posição são descartados de qualquer forma — a emissão de verdade usa o mecanismo de
    corrente `RelWriteExternalChainRef`, não `Bytes()`), removendo o símbolo temporário logo depois
    (`DeleteMapElement`) pra não contaminar a tabela de símbolos pro resto do arquivo (uma expressão
    composta envolvendo o mesmo externo, ainda fora de escopo, continua errando corretamente depois
    disso).
  - **Gotcha de PureBasic (ordem de declaração, não de linguagem em si): `Global`/`Procedure`
    declarados mais abaixo no MESMO `Module` não são visíveis de código mais acima**, mesmo dentro do
    mesmo arquivo/módulo — confirmado 3 vezes nesta sessão (`ExpandLines()`, `EncodeDataDirective()`,
    `SplitSourceLines()`, todas definidas na seção do driver ABSOLUTO, mais abaixo no arquivo do que o
    novo driver relocável que citei ANTES delas) — cada uma exigiu um `Declare` avulso antes do ponto de
    uso (mesmo padrão que `ExpandLines()` já usava pra si mesma, chamada recursiva). Os `Global
    AsmErrorLine.i`/`AsmErrorText.s` (compartilhados pelos dois drivers) tiveram que ser
    FISICAMENTE MOVIDOS pra mais cedo no arquivo (perto de `LastEvalError`), porque `Global` (ao
    contrário de `Procedure`) não aceita um `Declare` avulso — só resolve movendo a declaração de
    verdade. Lição prática: ao inserir uma nova seção de código ANTES de onde suas dependências já
    existem no mesmo arquivo, ou mover a seção nova pra depois delas, ou (mais rápido pra evitar
    reescrever um bloco grande) usar `Declare` avulso pra cada `Procedure`/mover só os `Global`
    realmente necessários.
- **2026-07-24 — `editor/Z80Link.pbi`, corte 1 do linker (múltiplos `.REL` sem biblioteca)**.
  Diferente do escritor de bit-stream (onde precisei decodificar manualmente um `.REL` real pra
  confirmar o entendimento do formato antes de portar), desta vez o algoritmo inteiro já estava
  documentado em `docs/reference/nestor80-linker.md` (escrito numa sessão de planejamento anterior,
  direto do C# de `Linker/RelocatableFilesProcessor.cs`) — então portei direto do C# lido em paralelo
  (`ProcessProgram`/`EffectiveAddressOf`/`ResolveExternalChain`/`DoLinking`), sem precisar de nenhuma
  decodificação manual extra. Escopo fechado ANTES de escrever código: só o modo de sequenciamento
  **padrão** do LK80 ("dados antes de código", que é o que acontece quando você roda `LK80 a.rel
  b.rel` sem nenhum argumento extra) — `--code`/`--data`/`--align-code`/`--align-data`/
  `--code-before-data` ficam de fora, junto de `.REQUEST`/biblioteca (isso é o corte 2, junto de
  `Z80Lib.pbi`) e do item de extensão RPN (tipo 4 — nosso `AssembleRelocatable` nunca gera isso,
  só suporta externo *bare*, então nem tinha como testar essa parte mesmo se implementasse).
  - **Leitor de bit-stream (`RR_*`) é literalmente o escritor (`RelW_*`) ao contrário** — mesmo
    empacotamento MSB-first, mesma disputa de prefixo `1`+`00`=item-de-link vs. `1`+seg=valor
    relocável, mesmo campo de símbolo com escape `FFh`+tamanho. Como o formato já tinha sido
    validado bit a bit na sessão do escritor, o leitor saiu correto de primeira — nenhum bug de
    parsing apareceu durante os testes.
  - **Achado notável da validação: os 3 cenários de teste bateram byte a byte contra o `LK80.exe`
    JÁ NA PRIMEIRA TENTATIVA COMPLETA** (módulo único; 2 módulos com `PUBLIC`/`EXTRN` cruzado nos
    dois sentidos incl. leitura de dado externo; 2 módulos compartilhando um bloco `COMMON`) — o
    único ajuste necessário no meio do caminho foi no lado do ASSEMBLER (ver próximo item), não no
    linker em si. Isso confirma que ler o C# com atenção (em vez de tentar adivinhar o algoritmo a
    partir só da descrição em prosa) compensa: o algoritmo de `ProcessProgram` tem detalhes não
    óbvios (ex. `ProgramInfo.MaxSegmentEnd` **exclui** o segmento `COMMON` do cálculo de "onde o
    próximo programa começa" — um bloco `COMMON` é posição fixa compartilhada, não K deveria
    empurrar o próximo módulo pra frente; replicar isso sem ler o C# diretamente teria sido fácil de
    errar por raciocínio "razoável" mas incorreto).
  - **Bug real pego pela validação, do lado do ASSEMBLER**: `LD A,(externo)`/`LD HL,(externo)`
    (referência externa via endereçamento indireto — padrão tão comum quanto `CALL externo`) não
    era reconhecida como referência *bare* dentro de `RunOnePassRel` — o texto do operando ainda
    carregava os parênteses (`"(shareddata)"`) na hora de comparar contra `LastEvalUnknownSymbol`
    (que nunca tem parênteses, é só o nome do símbolo). Resultado: `Expressao externa composta nao
    suportada` num caso que na verdade é bare simples. Corrigido com um helper novo,
    `Z80Asm::BareExternKeyOf()`, que tira uma camada de parênteses (se houver) antes de comparar —
    usado tanto na classificação de operando de `DW` quanto na de instrução de CPU. Lição: a
    suíte de testes do assembler sozinha (67/67) não pegou isso porque nenhum teste anterior tinha
    `EXTRN` referenciado via `(nome)` — só apareceu testando um cenário de linkagem de verdade com
    dado compartilhado entre módulos, um lembrete de que "testado" é sempre relativo à cobertura
    real dos casos exercitados, não uma garantia absoluta.
  - **Simplificações deliberadas registradas pra não esquecer**: detecção de sobreposição de
    segmento entre programas (`AddressRange.Intersection` no C#) não foi implementada — é uma
    feature de diagnóstico (pega erro do usuário), não bloqueia linkagem correta de fonte
    bem-formado, então ficou pra depois. Duplicata de símbolo público é detectada mas com relato
    mais simples que o original (erra na primeira duplicata encontrada, em vez de coletar todas as
    ocorrências pra reportar de uma vez no fim) — funcionalmente equivalente pra fins de correção,
    só menos "amigável" na mensagem.
- **2026-07-24 — `.REQUEST`/biblioteca (corte 2 do linker) + `editor/Z80Lib.pbi`, achado real de
  limitação do `LK80.exe` local**. Antes de escrever qualquer código, tentei validar o entendimento
  do mecanismo de `.REQUEST` criando um cenário real (`N80.exe` monta 2 módulos separados, cada um
  com um `PUBLIC`, `LB80.exe create` concatena os dois numa "biblioteca", um terceiro módulo faz
  `.REQUEST` da biblioteca e usa `EXTRN` só de um dos dois símbolos) e rodando com `LK80.exe` puro,
  do jeito que o usuário final faria — **antes** de portar a lógica. Resultado inesperado: pedir o
  símbolo do **primeiro** programa da biblioteca funciona perfeitamente (`Program: MODA ... funca =
  0107h`), mas pedir o símbolo do **segundo** programa sempre falha com `can't resolve external
  symbol reference`, mesmo trocando a ORDEM dos programas na biblioteca (o que falha é sempre "o que
  não é o primeiro", nunca um nome específico) — decodifiquei o `.LIB` gerado pelo `LB80.exe` byte a
  byte (usando o mesmo decodificador Python já validado nesta sessão pro escritor) e confirmei que o
  arquivo está perfeitamente formado (dois programas completos, cabeçalho de 16 bytes cada, um só
  `EndFile` no final) — ou seja, o arquivo está certo, é o `LK80.exe` local que não processa
  corretamente `EntrySymbol` de programas além do primeiro dentro de uma biblioteca pedida via
  `.REQUEST` (provável limitação/bug real desta build específica do Nestor80, não do formato em si
  nem do meu entendimento dele). **Decisão**: implementar o algoritmo CORRETO (por programa, não por
  arquivo inteiro — cada programa da biblioteca tem seu próprio conjunto de símbolos públicos
  indexado separadamente em `LLibProgIndex()`), já que "linkagem estática seletiva" só faz sentido
  granular por programa, e validar via DUAS estratégias: oráculo direto onde o `LK80.exe` local
  funciona (biblioteca de 1 programa; biblioteca de 2+ pedindo o primeiro — bateram byte a byte) e
  auto-consistência pro resto (pedir o "não-primeiro" produz binário byte-idêntico ao cenário
  equivalente onde esse mesmo programa É o primeiro — prova que só ELE entra, nenhum outro). Cadeia
  transitiva de 3 níveis (biblioteca com `funcx`→`funcy`→`funcz` em 3 programas diferentes, `main` só
  referencia `funcx`) resolvida corretamente pelo loop de ponto fixo em `LinkFiles()` (repete a busca
  até uma rodada inteira não carregar programa nenhum novo) — todos os 3 programas entram no binário
  final mesmo sem NENHUM deles ser referenciado diretamente por `main` (só `funcx` é, os outros dois
  entram por resolver a cadeia). **Lição reforçada**: rodar o cenário real primeiro com as ferramentas
  originais (antes de portar) continua sendo o jeito mais confiável de achar essas pegadinhas — dessa
  vez a "pegadinha" nem era no meu entendimento, era uma limitação de verdade do software de
  referência, que só apareceu testando um caso (segundo programa de biblioteca multi-programa) que a
  documentação oficial não deixava claro que seria um problema.
  - **`.REQUEST`/`REQUEST` virou diretiva de verdade no assembler** (`RunOnePassRel` em
    `Z80Asm.pbi`) — antes só reconhecida no vocabulário (destaque de sintaxe), sem efeito nenhum;
    agora emite o item de link tipo 3 de verdade (`RelW_WriteLinkItem(#Z80Rel_RequestLibrarySearch,
    ...)`), um por nome de arquivo pedido (aceita lista separada por vírgula, mesma sintaxe do
    `EXTRN`/`PUBLIC`).
  - **Achado que simplificou MUITO `Z80Lib::CreateOrAddLibrary()`**: como
    `Z80Asm::RelW_ForceByteBoundary()` sempre roda logo antes do item "Fim de arquivo" (7 bits fixos
    `100`+`1111`, nunca alinhado por conta própria), esse item **sempre** ocupa exatamente o ÚLTIMO
    byte de qualquer `.REL` de programa único, sempre valendo `9Eh` — confirmado em todo `.REL`
    gerado nesta sessão (Fase A e B). "Criar uma biblioteca" (concatenar N `.REL`) não precisa
    entender bit-stream nenhum por causa disso: só cortar o último byte de cada pedaço (exceto o
    último escrito, que fica intacto) e concatenar — validado byte a byte idêntico ao `LB80.exe`
    real (`create`+`add` em sequência).
  - **Dois gotchas de PureBasic pegos na implementação de `Z80Lib.pbi`**: (1) `*Ptr.Integer`
    (tentando declarar "ponteiro pro tipo Integer" com o NOME do tipo) compila sem erro mas não
    funciona como esperado (o dereference `*Ptr\i` mais tarde falhava de um jeito que só apareceu em
    runtime, como erro de parse de `.REL` válido) — o sufixo certo pra tipo nativo é a LETRA (`.i`),
    não a palavra ("Integer"); e mesmo `.i` sozinho não resolve, porque (2) **PureBasic não deixa
    dereferenciar ponteiro de tipo NATIVO nenhum** (`*Ptr.i\i` dá erro de compilação "Native types
    can't be used with pointers") — só de `Structure`. Corrigido com uma "caixinha" de 1 campo só
    (`Structure Z80LibPtrBox : P.i : EndStructure`) só pra poder devolver um ponteiro por
    out-parameter (`*OutBuf.Z80LibPtrBox`), mesmo truque que a Fase A já usa pra qualquer valor
    passado por referência.
  - **Bug real de lógica (pego pelo mesmo teste real, não adivinhado)**: minha primeira versão de
    `IndexLibraryBuffer()` tratava falha de `RB_CheckAndSkipHeader()` como erro FATAL (`If Not
    RB_CheckAndSkipHeader(...) : ProcedureReturn #False`), quebrando com "erro fazendo parse" em todo
    `.REL` de programa único — a causa: depois do último `EndProgram` de um arquivo, só sobra o item
    "Fim de arquivo" (sem cabeçalho de 16 bytes nenhum antes dele, óbvio em retrospecto), e o loop
    externo tenta checar cabeçalho ali de novo. A versão em `Z80Link::RR_ParseBuffer()` (escrita
    antes, já funcionando) tinha esse mesmo padrão mas **não tratava a falha como fatal** — só
    ignorava o retorno e deixava o item ser lido normalmente a seguir (que aí sim reconhece "Fim de
    Arquivo" corretamente). Corrigido replicando o MESMO padrão (chamar sem checar o retorno) em vez
    de reinventar a lógica de controle - lição prática de manter as duas cópias "trivialmente
    idênticas" na estrutura de controle, não só nos nomes de campo.
- **2026-07-24 — fechamento da sessão (Fase B: motor completo)**: com `Z80Link.pbi`/`Z80Lib.pbi`
  prontos e o checklist Fase B todo marcado (menos UI de menu e os itens já documentados como fora de
  escopo — `--code`/`--data`/`--align-*`, overlap de segmento, Intel HEX), documentação atualizada em
  todos os `*.md` do projeto: `README.md` (changelog + versão no topo), `docs/SPEC.md` (módulo 2b +
  nova entrada em "Próximos passos em aberto"), `docs/MANUAL.md` (seção "Assembler Z80" deixou de dizer
  que `.REL`/linker "ainda não é suportado" — o motor existe e está validado, só falta menu). Versão do
  executável atualizada de `7.3.1` pra **`7.3.3`** (convenção do projeto, `version_numbering_convention`
  na memória: minor ímpar = build interno/dev, segue ímpar até o primeiro release de verdade).
- 2026-07-24: início da Fase A.
