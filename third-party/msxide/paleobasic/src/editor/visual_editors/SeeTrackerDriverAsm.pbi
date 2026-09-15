;
; ------------------------------------------------------------
;  SeeTrackerDriverAsm.pbi - fonte Z80 do driver de replay nativo desta IDE,
;  compativel com o formato de arquivo .SEE (Sound Effect Editor, Fuzzy
;  Logic 1991/95) - ver Ajuda -> SEE Tracker... e docs/SPEC.md modulo 23.
;
;  PORTA de see/SEE3PLAY.ASC (driver original v3.10a, "100% PUBLIC DOMAIN"
;  segundo o proprio cabecalho daquele arquivo - so o EDITOR/formato .SEE em
;  si e shareware, o driver de replay nao), NAO uma copia literal - foi
;  reescrita/adaptada pra assemblar com o Z80Asm.pbi nativo desta IDE
;  (Z80Asm::Assemble(), mesmo motor de "Executar -> Montar Assembly"):
;
;  - `&Hxx` (sintaxe BASIC de hex, que o WBass2 original aceitava) virou
;    `#xx` (unica forma de hex sem sufixo/prefixo M80 que o Z80Asm entende
;    sem risco de ambiguidade - ver ChIsHexDigit/tokenizer em Z80Asm.pbi).
;  - Rotulos com "%"/"!" no nome (`%SEEID`, `!EVENT`) viraram nomes normais
;    (`SEEID_OFS`, `DOEVENT`) - "%"/"!" nao sao caracteres de identificador
;    validos neste assembler (so letras/digitos/`$.?@_`, ver ChIsIdentExtra);
;    rotulos com "." no nome (`MAIN.A`, `EV_N.0`) foram MANTIDOS como no
;    original - "." E' um caractere de identificador valido aqui (mesma
;    regra do Nestor80).
;  - Bug real corrigido: no `SEE_IN` original, o loop que confere a
;    identificacao (`"SEE3"`, so 4 bytes - permissivo de proposito, aceita
;    tanto `SEE3org` quanto `SEE3EDIT`, os dois sufixos vistos nos arquivos
;    reais desta pasta) e o `LDIR` que copia os 4 contadores do cabecalho
;    pra memoria de trabalho ficavam ENCADEADOS - o `LDIR` comecava
;    exatamente onde o loop de 4 bytes parou (offset 4 do arquivo), nao no
;    offset 8 onde os contadores realmente ficam (confirmado por analise
;    cruzada byte a byte contra os 4 arquivos `.SEE` reais desta pasta -
;    ver Ajuda -> SEE Tracker..., topico "Cabecalho do arquivo... RESOLVIDO
;    por analise cruzada"). Aqui os dois ficam DESACOPLADOS: valida so 4
;    bytes (continua aceitando os dois sufixos reais), mas reposiciona HL
;    explicitamente pro offset 8 antes do `LDIR`.
;  - Removida a checagem opcional de overflow de pattern via `RST #20`
;    (ROM-BIOS) que o comentario do proprio driver original ja descrevia
;    como dispensavel ("only an xtra security... not really necessary if
;    you make correct SEE data... you'd better remove it if you've set
;    page 0 to RAM") - dado que O .SEE E' GERADO POR NOS MESMOS (Gerar
;    codigo do editor SEE Tracker), esse dado sempre e bem formado; menos
;    codigo, menos risco de uma dependencia de ROM-BIOS mal-entendida.
;  - Vetor NOVO (nao existe no original): `BSETFX`, um adaptador que
;    empacota o argumento inteiro de `USR()` do MSX-BASIC (que chega em HL)
;    em B (prioridade, byte alto) + C (numero do SFX, byte baixo) antes de
;    saltar pro `SETSFX` original - o `SETSFX` cru espera esses dois
;    parametros em registradores, o que uma chamada `USR()` de UM argumento
;    nao entrega diretamente. Chame como
;    `DEFUSR=BASE+15:A=USR(prioridade*256+numero_do_sfx)`.
;
;  Layout de memoria (igual ao original): driver de codigo em #C000 (ORG
;  fixo - RAM alta da pagina 3 num MSX de 64KB; se o programa BASIC calulador
;  for grande, reserve memoria antes com `CLEAR ,&HBFFF` ou similar, mesma
;  ressalva de qualquer utilitario BASIC+maquina deste tipo), dados `.SEE`
;  residem onde o `SEEADR` (variavel de trabalho do driver) apontar - o
;  gerador de codigo desta IDE usa #8000 por padrao, mesmo valor do
;  original.
;
;  Tabela de vetores (offsets a partir do endereco base, cada um 3 bytes -
;  `JP endereco`):
;    +0  SEE_IN  - inicializa (confere ID, copia cabecalho, liga no H_TIMI)
;    +3  SEE_EX  - desliga, silencia o PSG, restaura o hook de interrupcao
;    +6  SETSFX  - inicia um SFX (crua: C=numero, B=prioridade)
;    +9  CUTSFX  - corta o SFX atual
;    +12 SEEINT  - ponto de entrada alternativo (temporizacao propria)
;    +15 BSETFX  - NOSSO adaptador BASIC-friendly de SETSFX (ver acima)
; ------------------------------------------------------------
;

CompilerIf Not Defined(SEETRACKERDRIVERASM_PBI_INCLUDED, #PB_Constant)
#SEETRACKERDRIVERASM_PBI_INCLUDED = 1

Procedure.s SeeDrv_SourceCode()
  Protected S.s = ""

  S + "        ORG #C000" + #CRLF$
  S + #CRLF$
  S + "        JP SEE_IN" + #CRLF$
  S + "        JP SEE_EX" + #CRLF$
  S + "        JP SETSFX" + #CRLF$
  S + "        JP CUTSFX" + #CRLF$
  S + "SEEINT: JP MAIN.A" + #CRLF$
  S + "        JP BSETFX" + #CRLF$
  S + #CRLF$
  S + "POSTB_OFS EQU #10" + #CRLF$
  S + "PATTS_OFS EQU #0210" + #CRLF$
  S + "H_TIMI    EQU #0FD9F" + #CRLF$
  S + #CRLF$
  S + "SEEADR: DW #8000" + #CRLF$
  S + "SEEMAP: DB 1" + #CRLF$
  S + "SEETID: DB 0" + #CRLF$
  S + "SEESTA: DB 0" + #CRLF$
  S + "SFXPRI: DB 0" + #CRLF$
  S + "SEEVOL: DB 15" + #CRLF$
  S + #CRLF$

  ; --- Init ---
  S + "SEE_IN: LD A,(SEESTA)" + #CRLF$
  S + "        AND A" + #CRLF$
  S + "        RET NZ" + #CRLF$
  S + #CRLF$
  S + "        LD A,(SEEADR+1)" + #CRLF$
  S + "        AND #0BF" + #CRLF$
  S + "        LD (SEEADR+1),A" + #CRLF$
  S + #CRLF$
  S + "        CALL SETMAP" + #CRLF$
  S + #CRLF$
  S + "        LD HL,(SEEADR)" + #CRLF$
  S + "        LD DE,SEE_ID" + #CRLF$
  S + "        LD B,4" + #CRLF$
  S + "SEEI.0: LD A,(DE)" + #CRLF$
  S + "        CP (HL)" + #CRLF$
  S + "        SCF" + #CRLF$
  S + "        JP NZ,DRVRET" + #CRLF$
  S + "        INC HL" + #CRLF$
  S + "        INC DE" + #CRLF$
  S + "        DJNZ SEEI.0" + #CRLF$
  S + #CRLF$
  S + "        LD HL,(SEEADR)" + #CRLF$
  S + "        LD DE,8" + #CRLF$
  S + "        ADD HL,DE" + #CRLF$
  S + "        LD DE,_HISPT" + #CRLF$
  S + "        LD BC,8" + #CRLF$
  S + "        LDIR" + #CRLF$
  S + #CRLF$
  S + "        LD A,1" + #CRLF$
  S + "        LD (SEESTA),A" + #CRLF$
  S + "        DEC A" + #CRLF$
  S + "        LD (SFXPRI),A" + #CRLF$
  S + #CRLF$
  S + "        LD A,(SEETID)" + #CRLF$
  S + "        AND A" + #CRLF$
  S + "        JP NZ,DRVRET" + #CRLF$
  S + #CRLF$
  S + "        DI" + #CRLF$
  S + "        LD HL,H_TIMI" + #CRLF$
  S + "        LD DE,OLDVBL" + #CRLF$
  S + "        LD BC,5" + #CRLF$
  S + "        LDIR" + #CRLF$
  S + "        LD DE,H_TIMI" + #CRLF$
  S + "        LD HL,NEWVBL" + #CRLF$
  S + "        LD BC,5" + #CRLF$
  S + "        LDIR" + #CRLF$
  S + "        EI" + #CRLF$
  S + "        AND A" + #CRLF$
  S + "        JP DRVRET" + #CRLF$
  S + #CRLF$
  S + "NEWVBL: JP MAIN" + #CRLF$
  S + "        RET" + #CRLF$
  S + "        RET" + #CRLF$
  S + #CRLF$

  ; --- Exit ---
  S + "SEE_EX: LD A,(SEESTA)" + #CRLF$
  S + "        AND A" + #CRLF$
  S + "        RET Z" + #CRLF$
  S + "        XOR A" + #CRLF$
  S + "        LD (SEESTA),A" + #CRLF$
  S + #CRLF$
  S + "        CALL PSGOFF" + #CRLF$
  S + #CRLF$
  S + "        LD A,(SEETID)" + #CRLF$
  S + "        AND A" + #CRLF$
  S + "        RET NZ" + #CRLF$
  S + #CRLF$
  S + "        DI" + #CRLF$
  S + "        LD HL,OLDVBL" + #CRLF$
  S + "        LD DE,#0FD9F" + #CRLF$
  S + "        LD BC,5" + #CRLF$
  S + "        LDIR" + #CRLF$
  S + "        EI" + #CRLF$
  S + "        RET" + #CRLF$
  S + #CRLF$

  ; --- BASIC-friendly adapter for SETSFX (our own addition) ---
  S + "BSETFX: LD A,H" + #CRLF$
  S + "        LD B,A" + #CRLF$
  S + "        LD A,L" + #CRLF$
  S + "        LD C,A" + #CRLF$
  S + "        JP SETSFX" + #CRLF$
  S + #CRLF$

  ; --- Set new Sound Effect ---
  S + "SETSFX: LD A,B" + #CRLF$
  S + "        AND A" + #CRLF$
  S + "        JR NZ,SEFF.0" + #CRLF$
  S + "        LD A,(SFXPRI)" + #CRLF$
  S + "        AND A" + #CRLF$
  S + "        JR Z,SEFF.0" + #CRLF$
  S + "        LD A,(SEESTA)" + #CRLF$
  S + "        AND 2" + #CRLF$
  S + "        SCF" + #CRLF$
  S + "        LD A,1" + #CRLF$
  S + "        RET NZ" + #CRLF$
  S + #CRLF$
  S + "SEFF.0: CALL SETMAP" + #CRLF$
  S + #CRLF$
  S + "        LD A,(_HISFX)" + #CRLF$
  S + "        CP C" + #CRLF$
  S + "        LD A,0" + #CRLF$
  S + "        JP C,DRVRET" + #CRLF$
  S + #CRLF$
  S + "        LD L,C" + #CRLF$
  S + "        LD H,0" + #CRLF$
  S + "        ADD HL,HL" + #CRLF$
  S + "        LD DE,(SEEADR)" + #CRLF$
  S + "        ADD HL,DE" + #CRLF$
  S + "        LD DE,POSTB_OFS" + #CRLF$
  S + "        ADD HL,DE" + #CRLF$
  S + "        LD E,(HL)" + #CRLF$
  S + "        INC HL" + #CRLF$
  S + "        LD D,(HL)" + #CRLF$
  S + "        LD A,D" + #CRLF$
  S + "        CP #0FF" + #CRLF$
  S + "        SCF" + #CRLF$
  S + "        JP Z,DRVRET" + #CRLF$
  S + #CRLF$
  S + "        LD A,C" + #CRLF$
  S + "        LD (SFX_NR),A" + #CRLF$
  S + "        LD A,B" + #CRLF$
  S + "        LD (SFXPRI),A" + #CRLF$
  S + #CRLF$
  S + "        CALL CUTSFX" + #CRLF$
  S + #CRLF$
  S + "        LD A,(SEESTA)" + #CRLF$
  S + "        OR #04" + #CRLF$
  S + "        LD (SEESTA),A" + #CRLF$
  S + #CRLF$
  S + "        LD (PAT_NR),DE" + #CRLF$
  S + #CRLF$
  S + "        CALL C_PTAD" + #CRLF$
  S + #CRLF$
  S + "        LD HL,0" + #CRLF$
  S + "        LD (TEMPO),HL" + #CRLF$
  S + "        LD A,3" + #CRLF$
  S + "        LD (SEESTA),A" + #CRLF$
  S + "        AND A" + #CRLF$
  S + "        JP DRVRET" + #CRLF$
  S + #CRLF$

  ; --- Cut Sound Effect ---
  S + "CUTSFX: LD A,(SEESTA)" + #CRLF$
  S + "        AND 1" + #CRLF$
  S + "        RET Z" + #CRLF$
  S + "        LD (SEESTA),A" + #CRLF$
  S + "        JP PSGOFF" + #CRLF$
  S + #CRLF$

  ; --- Main (timed) ---
  S + "MAIN:   CALL OLDVBL" + #CRLF$
  S + #CRLF$
  S + "MAIN.A: LD A,(SEESTA)" + #CRLF$
  S + "        BIT 0,A" + #CRLF$
  S + "        RET Z" + #CRLF$
  S + "        BIT 1,A" + #CRLF$
  S + "        RET Z" + #CRLF$
  S + "        BIT 2,A" + #CRLF$
  S + "        RET NZ" + #CRLF$
  S + #CRLF$
  S + "        LD A,(TEMPO+1)" + #CRLF$
  S + "        SUB 1" + #CRLF$
  S + "        LD (TEMPO+1),A" + #CRLF$
  S + "        RET NC" + #CRLF$
  S + "        LD A,(TEMPO+0)" + #CRLF$
  S + "        LD (TEMPO+1),A" + #CRLF$
  S + #CRLF$
  S + "        CALL SETMAP" + #CRLF$
  S + "        LD HL,(PATADR)" + #CRLF$
  S + #CRLF$
  S + "MAIN.0: LD A,(_HALT)" + #CRLF$
  S + "        AND A" + #CRLF$
  S + "        JR Z,MAIN.1" + #CRLF$
  S + #CRLF$
  S + "        DEC A" + #CRLF$
  S + "        LD (_HALT),A" + #CRLF$
  S + "        AND A" + #CRLF$
  S + "        JP NZ,DRVRET" + #CRLF$
  S + "        JR MAIN.2" + #CRLF$
  S + #CRLF$
  S + "MAIN.1: CALL DOEVENT" + #CRLF$
  S + #CRLF$
  S + "MAIN.2: CALL SETPSG" + #CRLF$
  S + "        LD (PATADR),HL" + #CRLF$
  S + "        JP DRVRET" + #CRLF$
  S + #CRLF$

  ; --- Event commands ---
  S + "DOEVENT: LD A,(HL)" + #CRLF$
  S + "        LD C,A" + #CRLF$
  S + "        AND #70" + #CRLF$
  S + "        AND A" + #CRLF$
  S + "        RET Z" + #CRLF$
  S + #CRLF$
  S + "        CP #10" + #CRLF$
  S + "        JP Z,EV_HLT" + #CRLF$
  S + "        CP #20" + #CRLF$
  S + "        JP Z,EV_FOR" + #CRLF$
  S + "        CP #30" + #CRLF$
  S + "        JP Z,EV_NXT" + #CRLF$
  S + "        CP #40" + #CRLF$
  S + "        JP Z,EV_STR" + #CRLF$
  S + "        CP #50" + #CRLF$
  S + "        JP Z,EV_RER" + #CRLF$
  S + "        CP #60" + #CRLF$
  S + "        JP Z,EV_TEM" + #CRLF$
  S + "        JP EV_END" + #CRLF$
  S + #CRLF$
  S + "EV_HLT: LD A,C" + #CRLF$
  S + "        AND #0F" + #CRLF$
  S + "        LD (_HALT),A" + #CRLF$
  S + "        POP AF" + #CRLF$
  S + "        JP DRVRET" + #CRLF$
  S + #CRLF$
  S + "EV_FOR: PUSH HL" + #CRLF$
  S + #CRLF$
  S + "        LD A,(LOOPNR)" + #CRLF$
  S + "        INC A" + #CRLF$
  S + "        AND 3" + #CRLF$
  S + "        LD (LOOPNR),A" + #CRLF$
  S + #CRLF$
  S + "        PUSH HL" + #CRLF$
  S + "        LD HL,LOOPBF" + #CRLF$
  S + "        LD D,0" + #CRLF$
  S + "        LD E,A" + #CRLF$
  S + "        ADD HL,DE" + #CRLF$
  S + "        ADD HL,DE" + #CRLF$
  S + "        ADD HL,DE" + #CRLF$
  S + #CRLF$
  S + "        LD A,C" + #CRLF$
  S + "        AND #0F" + #CRLF$
  S + "        LD (HL),A" + #CRLF$
  S + "        INC HL" + #CRLF$
  S + "        POP DE" + #CRLF$
  S + "        LD (HL),E" + #CRLF$
  S + "        INC HL" + #CRLF$
  S + "        LD (HL),D" + #CRLF$
  S + #CRLF$
  S + "        POP HL" + #CRLF$
  S + "        RET" + #CRLF$
  S + #CRLF$
  S + "EV_NXT: PUSH HL" + #CRLF$
  S + #CRLF$
  S + "        LD A,(LOOPNR)" + #CRLF$
  S + "        AND 3" + #CRLF$
  S + #CRLF$
  S + "        LD HL,LOOPBF" + #CRLF$
  S + "        LD D,0" + #CRLF$
  S + "        LD E,A" + #CRLF$
  S + "        ADD HL,DE" + #CRLF$
  S + "        ADD HL,DE" + #CRLF$
  S + "        ADD HL,DE" + #CRLF$
  S + "        DEC (HL)" + #CRLF$
  S + "        JR Z,EV_N.0" + #CRLF$
  S + #CRLF$
  S + "        INC HL" + #CRLF$
  S + "        LD E,(HL)" + #CRLF$
  S + "        INC HL" + #CRLF$
  S + "        LD D,(HL)" + #CRLF$
  S + #CRLF$
  S + "        POP HL" + #CRLF$
  S + "        EX DE,HL" + #CRLF$
  S + "        RET" + #CRLF$
  S + #CRLF$
  S + "EV_N.0: LD A,(LOOPNR)" + #CRLF$
  S + "        DEC A" + #CRLF$
  S + "        AND 3" + #CRLF$
  S + "        LD (LOOPNR),A" + #CRLF$
  S + #CRLF$
  S + "        POP HL" + #CRLF$
  S + "        RET" + #CRLF$
  S + #CRLF$
  S + "EV_STR: LD (CLPADR),HL" + #CRLF$
  S + "        RET" + #CRLF$
  S + #CRLF$
  S + "EV_RER: LD HL,(CLPADR)" + #CRLF$
  S + "        RET" + #CRLF$
  S + #CRLF$
  S + "EV_TEM: LD A,C" + #CRLF$
  S + "        AND #0F" + #CRLF$
  S + "        LD (TEMPO+0),A" + #CRLF$
  S + "        LD (TEMPO+1),A" + #CRLF$
  S + "        RET" + #CRLF$
  S + #CRLF$
  S + "EV_END: LD A,1" + #CRLF$
  S + "        LD (SEESTA),A" + #CRLF$
  S + "        POP AF" + #CRLF$
  S + "        JP DRVRET" + #CRLF$
  S + #CRLF$

  ; --- Set all PSG regs ---
  S + "SETPSG: LD IX,PSGREG" + #CRLF$
  S + "        LD E,0" + #CRLF$
  S + "        INC HL" + #CRLF$
  S + #CRLF$
  S + "        LD B,3" + #CRLF$
  S + "STPS.0: PUSH BC" + #CRLF$
  S + "        LD C,(HL)" + #CRLF$
  S + "        INC HL" + #CRLF$
  S + "        LD B,(HL)" + #CRLF$
  S + "        BIT 7,(HL)" + #CRLF$
  S + "        CALL NZ,TUNWUP" + #CRLF$
  S + "        BIT 6,(HL)" + #CRLF$
  S + "        CALL NZ,TUNWDW" + #CRLF$
  S + "        INC HL" + #CRLF$
  S + "        LD A,C" + #CRLF$
  S + "        CALL WRTPSG" + #CRLF$
  S + "        LD A,B" + #CRLF$
  S + "        AND #0F" + #CRLF$
  S + "        CALL WRTPSG" + #CRLF$
  S + "        POP BC" + #CRLF$
  S + "        DJNZ STPS.0" + #CRLF$
  S + #CRLF$
  S + "        LD A,(HL)" + #CRLF$
  S + "        INC HL" + #CRLF$
  S + "        BIT 7,A" + #CRLF$
  S + "        CALL NZ,TUN_UP" + #CRLF$
  S + "        BIT 6,A" + #CRLF$
  S + "        CALL NZ,TUN_DW" + #CRLF$
  S + "        AND #1F" + #CRLF$
  S + "        CALL WRTPSG" + #CRLF$
  S + #CRLF$
  S + "        LD A,(HL)" + #CRLF$
  S + "        AND #3F" + #CRLF$
  S + "        OR #80" + #CRLF$
  S + "        INC HL" + #CRLF$
  S + "        CALL WRTPSG" + #CRLF$
  S + #CRLF$
  S + "        LD B,3" + #CRLF$
  S + "STPS.1: PUSH BC" + #CRLF$
  S + "        LD A,(HL)" + #CRLF$
  S + "        INC HL" + #CRLF$
  S + "        LD C,A" + #CRLF$
  S + "        AND #1F" + #CRLF$
  S + "        LD B,A" + #CRLF$
  S + "        BIT 4,A" + #CRLF$
  S + "        JP NZ,STPS.2" + #CRLF$
  S + "        BIT 7,C" + #CRLF$
  S + "        CALL NZ,TUN_UP" + #CRLF$
  S + "        BIT 6,C" + #CRLF$
  S + "        CALL NZ,VOL_DW" + #CRLF$
  S + "        LD B,A" + #CRLF$
  S + "        CALL FIXVOL" + #CRLF$
  S + "STPS.2:" + #CRLF$
  S + "        CALL WRTPSG" + #CRLF$
  S + "        LD (IX-1),B" + #CRLF$
  S + "        POP BC" + #CRLF$
  S + "        DJNZ STPS.1" + #CRLF$
  S + #CRLF$
  S + "        LD B,3" + #CRLF$
  S + "STPS_2: LD A,(HL)" + #CRLF$
  S + "        INC HL" + #CRLF$
  S + "        CALL WRTPSG" + #CRLF$
  S + "        DJNZ STPS_2" + #CRLF$
  S + "        RET" + #CRLF$
  S + #CRLF$

  ; --- Tuning ---
  S + "TUN_UP: ADD A,(IX)" + #CRLF$
  S + "        RET" + #CRLF$
  S + "TUN_DW: SUB (IX)" + #CRLF$
  S + "        NEG" + #CRLF$
  S + "        RET" + #CRLF$
  S + "TUNWUP: PUSH HL" + #CRLF$
  S + "        LD L,(IX)" + #CRLF$
  S + "        LD H,(IX+1)" + #CRLF$
  S + "        ADD HL,BC" + #CRLF$
  S + "        PUSH HL" + #CRLF$
  S + "        POP BC" + #CRLF$
  S + "        POP HL" + #CRLF$
  S + "        RET" + #CRLF$
  S + "TUNWDW: PUSH HL" + #CRLF$
  S + "        LD L,(IX)" + #CRLF$
  S + "        LD H,(IX+1)" + #CRLF$
  S + "        XOR A" + #CRLF$
  S + "        SBC HL,BC" + #CRLF$
  S + "        PUSH HL" + #CRLF$
  S + "        POP BC" + #CRLF$
  S + "        POP HL" + #CRLF$
  S + "        RET" + #CRLF$
  S + #CRLF$
  S + "VOL_DW: AND #0F" + #CRLF$
  S + "        LD B,A" + #CRLF$
  S + "        LD A,(IX+0)" + #CRLF$
  S + "        AND #0F" + #CRLF$
  S + "        SUB B" + #CRLF$
  S + "        RET NC" + #CRLF$
  S + "        XOR A" + #CRLF$
  S + "        RET" + #CRLF$
  S + #CRLF$
  S + "FIXVOL: AND #0F" + #CRLF$
  S + "        XOR 15" + #CRLF$
  S + "        LD C,A" + #CRLF$
  S + "        LD A,(SEEVOL)" + #CRLF$
  S + "        AND #0F" + #CRLF$
  S + "        SUB C" + #CRLF$
  S + "        RET NC" + #CRLF$
  S + "        XOR A" + #CRLF$
  S + "        RET" + #CRLF$
  S + #CRLF$

  ; --- PSG helpers ---
  S + "PSGOFF: LD A,7" + #CRLF$
  S + "        OUT (#0A0),A" + #CRLF$
  S + "        LD A,#0BF" + #CRLF$
  S + "        OUT (#0A1),A" + #CRLF$
  S + "        RET" + #CRLF$
  S + #CRLF$
  S + "WRTPSG: LD (IX),A" + #CRLF$
  S + "        INC IX" + #CRLF$
  S + "        PUSH AF" + #CRLF$
  S + "        LD A,E" + #CRLF$
  S + "        OUT (#0A0),A" + #CRLF$
  S + "        INC E" + #CRLF$
  S + "        POP AF" + #CRLF$
  S + "        OUT (#0A1),A" + #CRLF$
  S + "        RET" + #CRLF$
  S + #CRLF$

  ; --- Pattern address ---
  S + "C_PTAD: PUSH AF" + #CRLF$
  S + "        PUSH HL" + #CRLF$
  S + "        PUSH BC" + #CRLF$
  S + "        LD HL,(SEEADR)" + #CRLF$
  S + "        LD BC,PATTS_OFS" + #CRLF$
  S + "        ADD HL,BC" + #CRLF$
  S + "        LD BC,(PAT_NR)" + #CRLF$
  S + "        LD DE,15" + #CRLF$
  S + "C_PA.0: LD A,B" + #CRLF$
  S + "        OR C" + #CRLF$
  S + "        JR Z,C_PA.1" + #CRLF$
  S + "        ADD HL,DE" + #CRLF$
  S + "        DEC BC" + #CRLF$
  S + "        JP C_PA.0" + #CRLF$
  S + "C_PA.1: LD (PATADR),HL" + #CRLF$
  S + "        EX DE,HL" + #CRLF$
  S + "        POP BC" + #CRLF$
  S + "        POP HL" + #CRLF$
  S + "        POP AF" + #CRLF$
  S + "        RET" + #CRLF$
  S + #CRLF$

  ; --- Mapper (page 2) ---
  S + "SETMAP: PUSH AF" + #CRLF$
  S + "        IN A,(#0FE)" + #CRLF$
  S + "        LD (OLDMAP),A" + #CRLF$
  S + "        LD A,(SEEMAP)" + #CRLF$
  S + "        OUT (#0FE),A" + #CRLF$
  S + "        POP AF" + #CRLF$
  S + "        RET" + #CRLF$
  S + #CRLF$
  S + "DRVRET: PUSH AF" + #CRLF$
  S + "        LD A,(OLDMAP)" + #CRLF$
  S + "        OUT (#0FE),A" + #CRLF$
  S + "        POP AF" + #CRLF$
  S + "        RET" + #CRLF$
  S + #CRLF$

  ; --- Work area ---
  S + "SEE_ID: DB " + Chr(34) + "SEE3????" + Chr(34) + #CRLF$
  S + "TEMPO:  DB 0,0" + #CRLF$
  S + "PAT_NR: DW 0" + #CRLF$
  S + "PATADR: DS 2" + #CRLF$
  S + "SFX_NR: DB 0" + #CRLF$
  S + "_HALT:  DB 0" + #CRLF$
  S + "LOOPNR: DB 0" + #CRLF$
  S + "LOOPBF: DS 12" + #CRLF$
  S + "CLPADR: DW 0" + #CRLF$
  S + #CRLF$
  S + "_HISPT: DS 2" + #CRLF$
  S + "_HIPTA: DS 2" + #CRLF$
  S + "_HISFX: DS 2" + #CRLF$
  S + "_FLELN: DS 2" + #CRLF$
  S + #CRLF$
  S + "PSGREG: DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0" + #CRLF$
  S + #CRLF$
  S + "OLDVBL: DS 5" + #CRLF$
  S + "OLDMAP: DB 0" + #CRLF$
  S + #CRLF$
  S + "        END" + #CRLF$

  ProcedureReturn S
EndProcedure

CompilerEndIf ; SEETRACKERDRIVERASM_PBI_INCLUDED
