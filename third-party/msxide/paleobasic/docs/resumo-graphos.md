# Graphos III (módulo 14) — resumo de progresso

> Documento de acompanhamento desta frente de trabalho (não é a spec funcional — essa é
> `docs/SPEC.md` módulo 14/14b-14i — este arquivo é o "estado da implementação", para retomar em
> qualquer máquina). Atualizado a cada marco concluído.

## Objetivo

Replicar o **Graphos III** (Renato Degiovani, 1987 — editor de vídeo clássico do MSX, manual completo
lido de `graphos/graphos.txt`) dentro desta IDE, como **`Criar → Graphos III Screen 2...`**
(`editor/GraphosScreenGui.pbi`). Decisão de escopo confirmada com o usuário: cada função do Graphos III
original vira uma opção separada dentro de "Criar" — o editor de alfabetos do Graphos III já existia
antes desta frente de trabalho (`editor/CharsetEditorGui.pbi`, módulo 4) e não faz parte daqui.

## Estado atual (fim da sessão de 2026-07-25) — **tudo implementado, nada commitado**

Todas as fases abaixo foram feitas **na mesma sessão maratona**, em sequência, cada uma a partir de um
pedido explícito do usuário. Versão embutida no executável no fim: **`7.5.12`**.

| Fase | O quê | Status |
|------|-------|--------|
| 1 | Tela SCREEN 2 + color clash, paleta INK/PAPER, TRAÇO (Lápis/Borracha), LIMPA TELA | ✅ feita, commitada (`8f1ce92 Graphos III Inicio`) |
| 2 | Resto do menu DESENHO: BLOCO/LINHA/RETÂNGULO/RAIO/CÍRCULO/PINTURA/SPRAY/FILL | ✅ feita, commitada (`8797ad5`) |
| 3 | Menu TEXTO (F2): imprime com alfabeto do projeto, 6 estilos | ✅ feita, commitada (`b483acf`) |
| 4 | Menu TELA (F3) + reorganização de layout + alfabeto "padrao" auto-seed no startup | ✅ feita, **não commitada** |
| 5 | Persistência no projeto: Telas/Layouts/Shapes em `ProjectDB.pbi` (nav/tag/Novo/Registrar) | ✅ feita, **não commitada** |
| — | 3 correções de layout (barra sobrepondo coluna direita, janela alta demais, prévia do Shape sobrepondo navegadores) | ✅ feitas, **não commitadas** |
| 6 | Menu AJUSTE (F4): SCROLL/ROTAÇÃO, 1px e 8×8, 4 direções | ✅ feita, **não commitada** |
| 7 | Menu MISCELÂNEA (F5): ZOOM (janela à parte), SHAPE (carimbo, 4 modos), CORTE, GRID | ✅ feita, **não commitada** |
| 8 | Cursor de teclado (setas/espaço/TAB dentro do canvas) | ❌ **tentada e revertida** — usuário achou desnecessária com o mouse já disponível. Zero vestígio no código. Ver `feedback_no_keyboard_canvas_nav.md` na memória do Claude — **não reintroduzir sem pedido explícito novo** |
| 9 | Formatos nativos `.ALF`/`.LAY`/`.SCR`/`.SHP` (import/export) | ✅ feita, **não commitada** |
| — | Correção: abas "noname" sem extensão → `noname1.dmx`, `noname2.dmx`, ... | ✅ feita, **não commitada** |

**Com isso, os 5 menus do Graphos III original (DESENHO/TEXTO/TELA/AJUSTE/MISCELÂNEA) e os 4 formatos
de arquivo nativos (.ALF/.LAY/.SCR/.SHP) estão implementados.** Detalhe técnico completo de cada fase:
`docs/SPEC.md`, módulo 14 (linha ~55) e seções 14b até 14i.

## ⚠️ Importante para retomar em outra máquina

**Só as Fases 1-3 foram commitadas** (`8f1ce92`/`8797ad5`/`b483acf`, `git log` confirma). As Fases 4-9
inteiras (e a correção do "noname") existem só como alterações **não commitadas** no working directory
desta máquina, na sessão em que foram feitas — `git status` mostra `.gitignore`, `README.md`,
`build.ps1`, `docs/SPEC.md`, `editor/BadigEditor.exe`, `editor/BadigEditor.pb`,
`editor/GraphosScreenGui.pbi`, `editor/ProjectDB.pbi` modificados, mais `docs/resumo-graphos.md`,
`editor/GraphosNativeIO.pbi`, `editor/tools/GraphosNativeIOTestCli.pb`/`.exe` como novos/não rastreados.
Se você rodar `git pull origin main` numa outra máquina **antes de commitar e dar push nesta**, vai
puxar só até a Fase 3 — a maior parte do trabalho (Fases 4-9 + fix do "noname") não estará lá.

Antes de trocar de máquina: `git status` nesta máquina pra confirmar o que está pendente, decidir com o
usuário se commita (⚠️ só commitar quando pedido explicitamente — instrução padrão do projeto) e dar
`git push`. Arquivos novos não rastreados que fazem parte deste trabalho (não esquecer no `git add`):
- `editor/GraphosNativeIO.pbi`
- `editor/tools/GraphosNativeIOTestCli.pb` (+ o `.exe` compilado, se for versionado — checar convenção do
  projeto pra binários de teste antes de adicionar)

## Arquivos principais desta frente de trabalho

- **`editor/GraphosScreenGui.pbi`** — janela/lógica principal (~3000 linhas), todas as Fases 1-9 (exceto
  8, revertida). Cabeçalho do arquivo tem um comentário grande documentando o escopo de cada fase.
- **`editor/GraphosNativeIO.pbi`** (Fase 9) — codecs `.LAY`/`.SCR`/`.SHP` + conversão de endereçamento
  VRAM (3 "terços" × 256 tiles de 8×8, ver comentário no topo do arquivo pra fórmula completa).
- **`editor/ProjectDB.pbi`** (Fase 5) — tabelas `graphos_screens`/`graphos_layouts`/`graphos_shapes`,
  deliberadamente separadas da tabela `screens` pré-existente (formato incompatível, usada pelo editor
  "Draw Screen 2..." do módulo 5).
- **`editor/BadigEditor.pb`** — `App_EnsureDefaultAlphabet()` (Fase 4, seed do alfabeto "padrao" no
  startup) + fix do "noname" (`AddDocumentTab`/`SaveDocument`).
- **`editor/tools/GraphosNativeIOTestCli.pb`** (Fase 9) — harness de round-trip pros 3 codecs nativos,
  ver "Como testar" abaixo.

## Material de referência

- **`graphos/`** — pasta já rastreada no repositório com material original do Graphos III (manual
  `graphos.txt`, e amostras reais `.LAY`/`.SCR`/`.SHP` em `graphos/Layout|Telas|Shapes/`), usada como
  fixture de teste na Fase 9.
- **`E:\msxbasica\graphos-IV\`** — clone local dos visualizadores Python de referência
  (`alphabetV.py`/`layoutV.py`/`screenV.py`/`shapeV_2.py`) e das fontes Pascal originais de CyberKnight
  (`readers/*.pas`, `readers/g3viewer.doc` — a documentação mais autoritativa dos formatos, um `.doc`
  binário lido via `strings`). **Gitignored** (`.gitignore` já tem `/graphos-IV/`, mesmo tratamento de
  `/badig/`/`/nestor80/`: referência de leitura, não dependência de runtime). Se precisar dessa pasta em
  outra máquina e ela não estiver lá, avisar o usuário — não há comando de clone único documentado (era
  uma cópia local que o usuário já tinha).

## Como testar (reproduzir nesta ou noutra máquina)

```powershell
# Recompilar o editor completo
.\build.ps1

# Recompilar e rodar o harness da Fase 9 (round-trip .LAY/.SCR/.SHP contra arquivos reais)
& "<caminho do pbcompiler.exe>" editor\tools\GraphosNativeIOTestCli.pb /EXE editor\tools\GraphosNativeIOTestCli.exe /CONSOLE
.\editor\tools\GraphosNativeIOTestCli.exe <pasta_scratch_qualquer>
# Esperado: "=== Resultado: 24/24 OK ===", exit code 0
```

Não há harness de console dedicado pras Fases 2-8 (são todas lógica de UI/desenho, verificadas por
compilação limpa + execução manual do `.exe` — mesma limitação de automação de clique ao vivo já
registrada em cada seção do `docs/SPEC.md`).

## O que fica de fora (simplificações deliberadas, não são bugs)

- Rotina de apresentação "COMPACTA"/121-byte encontrada em alguns `.SCR` reais (ex.:
  `graphos/Telas/MSX_310/*.SCR`) não foi decodificada a fundo — só descartada com segurança no import
  (o tamanho é calculado pelo tamanho real do arquivo, não pelo cabeçalho, então isso é seguro).
- Máscara de shape (tipos 3/4 do `.SHP`) é lida mas ignorada — nenhuma ferramenta desta IDE usa máscara
  de shape ainda (o carimbo MÁSCARA/AND/OR/XOR da Fase 7 já cobre o uso prático sem precisar de máscara
  própria do shape).
- Importação de banco `.SHP` com múltiplos shapes só carrega 1 por vez (pede o número via
  `InputRequester` se houver mais de um) — sem lista/prévia de todos os shapes do banco.
- Cursor de teclado dentro do canvas (Fase 8) — **não reintroduzir sem pedido explícito novo do
  usuário**, ver tabela acima.
