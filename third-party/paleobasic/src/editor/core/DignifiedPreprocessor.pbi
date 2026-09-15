;
; ------------------------------------------------------------
;  Apelido interno: Raptor (tema pre-historico do projeto, ver README.md)
;  Basic Dignified - pre-processador nativo
;  Converte codigo no dialeto "Dignified" (labels, defines,
;  variaveis de nome longo, comentarios especiais, etc) para
;  MSX-BASIC classico em ASCII, com numeros de linha, pronto
;  para ser tokenizado por MsxTokenizer.pbi.
;
;  Port do nucleo de badig.py + badig_dignified.py + badig_msx.py
;  (Basic Dignified Suite, Fred Rique/farique). Ver docs/SPEC.md
;  modulo 3 (e 3g para INCLUDE/remtags) e docs/reference/
;  dignified-core.md / docs/reference/badig-msx-module.md para a
;  especificacao.
;
;  Escopo (ver docs/SPEC.md modulo 3 para o historico completo):
;    Implementado: comentarios (## / ### / ''), toggle rems e
;    KEEP (#all/#none), juncao de linhas (_ e :), DEFINE (com
;    variavel posicional e default) incluindo o [?](x,y)
;    embutido do modulo MSX, DECLARE + reducao automatica de
;    nomes longos para curtos (ZZ->AA), labels de linha, jump
;    labels, loop labels ( nome{ ... } ) e EXIT, TRUE/FALSE,
;    operadores compostos (++ -- += -= *= /= ^=), numeracao de
;    linha com resolucao de referencias para frente (2 passes),
;    FUNC/RET (proto-funcoes), conversao ?/PRINT (-cp), strip
;    THEN/GOTO (-tg), traducao Unicode->ASCII MSX (-tr),
;    maiusculas geral (-ca), tamanho de TAB configuravel,
;    INCLUDE (recursivo, namespace de label/loop/funcao isolado
;    por arquivo via Dig_ProcessSource/Dig_CurrentPrefix, ver
;    docs/SPEC.md modulo 3g) e remtags (##BB:arguments=/
;    export_file=/help=, so no arquivo principal).
;    Configuravel via BadigCfg (editor/BadigSettings.pbi) atraves
;    de Dig_SyncConfigFromBadigCfg() em BadigEditor.pb, ou
;    diretamente via os globals Dig_* abaixo (usado por
;    editor/tools/DigTestCli.pb, que roda com os defaults fixos).
;    NAO implementado: relatorios (-lbr/-lnr/-var/-lex/-par, sem
;    consumidor na IDE), strip_spaces (reinterpretado: remove so
;    espacos que nao ficam entre duas palavras, para nao colar
;    identificadores/keywords - nao e byte-a-byte identico ao
;    original).
; ------------------------------------------------------------
;

EnableExplicit

;- ------------------------------------------------------------
;- Configuracao (defaults equivalentes aos de badig_settings.py;
;- sincronizados a partir de BadigCfg quando rodando no editor)
;- ------------------------------------------------------------

Global Dig_LineStart.i = 10
Global Dig_LineStep.i = 10
Global Dig_RemHeader.b = #True
Global Dig_TabLength.i = 4
Global Dig_StripSpaces.b = #False
Global Dig_CapitalizeAll.b = #False
Global Dig_ConvertPrintCfg.s = ""      ; "" = nao converter, "?" ou "P" (forma final desejada)
Global Dig_StripThenGotoCfg.s = ""     ; "" = nao remover, "T" ou "G"
Global Dig_Translate.b = #False

Global Dig_HasError.b
Global Dig_ErrorMsg.s
Global Dig_ErrorLine.i

; #True quando o documento sendo processado e um projeto MSXBAS2ROM (ver
; parametro IsMsxBas2Rom de Dig_Preprocess, setado la e lido aqui por Global
; em vez de parametro - Dig_CollectHardVar_Piece/Dig_ShortenVars_Piece/
; Dig_ScanLabelRefs_Piece sao chamadas via ponteiro de funcao (Prototype
; Dig_PieceFn, assinatura fixa Piece.s/LineNum.i, ver Dig_MapCodeSegments) e
; por isso NAO podem ganhar um parametro extra - mesmo idioma ja usado por
; Dig_CurrentPrefix acima). Fica valido por toda a chamada de Dig_Preprocess,
; inclusive dentro de INCLUDE recursivo (nao precisa reset por nivel, ao
; contrario de Dig_CurrentPrefix, porque o modo nao muda dentro do mesmo
; documento).
Global Dig_ModeIsMsxBas2Rom.b = #False

; Diretorio do arquivo fonte sendo processado (passado a Dig_Preprocess),
; usado para resolver caminhos relativos de INCLUDE e do remtag export_file.
; "" quando desconhecido (documento nao salvo ainda) - INCLUDE relativo falha
; nesse caso, caminho absoluto ainda funciona.
Global Dig_BasePath.s = ""

; Namespace da "linha logica" sendo processada agora (labels/loop-labels/nomes
; de funcao ganham esse prefixo internamente, para nao colidir entre arquivo
; principal e includes - variaveis continuam compartilhadas, so labels/funcs/
; loops sao isolados por arquivo, ver docs/SPEC.md modulo 3g). "" no arquivo
; principal (comportamento 100% identico a antes de INCLUDE existir).
Global Dig_CurrentPrefix.s = ""
Global Dig_IncludeCounter.i = 0
Global NewList Dig_IncludeStack.s()   ; caminhos absolutos dos includes abertos (deteccao de ciclo)
#Dig_MaxIncludeDepth = 16

; Preenchido pelo remtag ##BB:export_file=... (so lido do arquivo principal,
; nunca de includes - mesma regra do badig.py original). "" = nao usado.
Global Dig_ExportFileOverride.s = ""
Global Dig_RemtagHelpRequested.b = #False

; Marcador interno usado para "esconder" placeholders (referencias de label,
; variavel de define, etc) de estagios posteriores do pipeline ate serem
; resolvidos. Chr(2) nunca aparece em codigo MSX-BASIC digitavel.
#Dig_Mark = Chr(2)

Procedure Dig_Fail(LineNum.i, Msg.s)
  If Not Dig_HasError
    Dig_HasError = #True
    Dig_ErrorMsg = Msg
    Dig_ErrorLine = LineNum
  EndIf
EndProcedure

;- ------------------------------------------------------------
;- Helpers de caractere
;- ------------------------------------------------------------

Procedure.b Dig_IsAlpha(C.s)
  ProcedureReturn Bool((C >= "A" And C <= "Z") Or (C >= "a" And C <= "z"))
EndProcedure

Procedure.b Dig_IsDigit(C.s)
  ProcedureReturn Bool(C >= "0" And C <= "9")
EndProcedure

Procedure.b Dig_IsWordChar(C.s)
  ProcedureReturn Bool(Dig_IsAlpha(C) Or Dig_IsDigit(C) Or C = "_")
EndProcedure

; Nome de label sintetico usado para o ponto de entrada de uma FUNC - mesma
; string usada tanto ao registrar o label (LabelNames) quanto ao gerar o
; marcador "G" da chamada (Dig_BuildFuncCallReplacement), sob o mesmo prefixo
; de namespace (Dig_CurrentPrefix) - precisa ser IDENTICA nos dois lados.
Procedure.s Dig_FuncLabelName(Prefix.s, FuncName.s)
  ProcedureReturn Prefix + "__func_" + FuncName
EndProcedure

; Acha a primeira ocorrencia de Needle em Line que esteja FORA de um literal
; de string entre aspas. Devolve a posicao (1-based) ou 0 se nao encontrar.
Procedure.i Dig_FindUnquoted(Line.s, Needle.s)
  Protected pos.i = 1, inStr.b = #False
  While pos <= Len(Line)
    If Mid(Line, pos, 1) = Chr(34)
      If inStr : inStr = #False : Else : inStr = #True : EndIf
      pos + 1
      Continue
    EndIf
    If Not inStr And Mid(Line, pos, Len(Needle)) = Needle
      ProcedureReturn pos
    EndIf
    pos + 1
  Wend
  ProcedureReturn 0
EndProcedure

; Verifica se Line(Pos, Length) e uma palavra isolada (nao colada a outro
; caractere de identificador antes/depois) - usado para casar "REM"/"DATA".
Procedure.b Dig_WordBoundary(Line.s, Pos.i, Length.i)
  Protected before.s, after.s
  If Pos > 1
    before = Mid(Line, Pos - 1, 1)
    If Dig_IsWordChar(before)
      ProcedureReturn #False
    EndIf
  EndIf
  after = Mid(Line, Pos + Length, 1)
  If Dig_IsWordChar(after)
    ProcedureReturn #False
  EndIf
  ProcedureReturn #True
EndProcedure

;- ------------------------------------------------------------
;- Palavras reservadas do MSX-BASIC classico (nao podem virar
;- nomes curtos de variavel nem ser tratadas como identificador)
;- Lista identica a badig_msx.py Description (ver
;- docs/reference/badig-msx-module.md)
;- ------------------------------------------------------------

Global NewMap Dig_ReservedKw.b()

; Vocabulario estendido do MSXBAS2ROM (FILE/TEXT, sub-comandos de CMD/SET/
; GET, funcoes como HEAP()/TILE()/etc.) - declarados AQUI (nao em
; BadigEditor.pb) porque DignifiedPreprocessor.pbi precisa compilar sozinho
; em harnesses standalone (editor/tools/DigTestCli.pb, que so XInclui este
; arquivo + MsxTokenizer.pbi). BadigEditor.pb (que XInclui este arquivo bem
; no comeco, antes de qualquer outra coisa) so CONSOME esses mapas
; (FindMapElement, no destaque de sintaxe/autocompletar) e os POPULA de novo
; via FillKeywordMap() no startup - populacao idempotente, sem risco de
; corromper nada rodando duas vezes (aqui, em Dig_InitReservedKw, e la).
Global NewMap KwMsxBas2RomDirective.b()
Global NewMap KwMsxBas2RomStatement.b()
Global NewMap KwMsxBas2RomFunctionPlain.b()

Procedure Dig_AddKwList(Words.s)
  Protected n.i = CountString(Words, " ") + 1, i.i, w.s
  For i = 1 To n
    w = StringField(Words, i, " ")
    ; a checagem de reservada compara so a parte alfabetica (sem $), entao
    ; as entradas com $ (ex: INKEY$) sao guardadas sem o sufixo
    If Right(w, 1) = "$"
      w = Left(w, Len(w) - 1)
    EndIf
    Dig_ReservedKw(w) = #True
  Next
EndProcedure

; Generico (Map por referencia), ao contrario de Dig_AddKwList (que so
; alimenta Dig_ReservedKw() especificamente) - usado abaixo pra povoar
; KwMsxBas2RomDirective/Statement/FunctionPlain, que tambem sao usados pelo
; destaque de sintaxe em BadigEditor.pb. Populado aqui TAMBEM (nao so em
; BadigEditor.pb) porque DignifiedPreprocessor.pbi e XIncluded bem antes -
; harnesses standalone (DigTestCli.exe) que so incluem este arquivo nao tem
; o FillKeywordMap() de BadigEditor.pb disponivel. Idempotente (M(w)=#True
; de novo nao corrompe nada), entao a populacao duplicada em BadigEditor.pb
; convive sem problema quando os dois rodam juntos no .exe completo.
Procedure Dig_FillWordMap(Map M.b(), Words.s)
  Protected n.i = CountString(Words, " ") + 1, i.i
  For i = 1 To n
    M(UCase(StringField(Words, i, " "))) = #True
  Next
EndProcedure

Procedure Dig_InitReservedKw()
  If MapSize(Dig_ReservedKw()) > 0
    ProcedureReturn
  EndIf
  Dig_AddKwList("AS BASE BEEP BLOAD BSAVE CALL CIRCLE CLEAR CLOAD CLOSE CLS CMD COLOR " +
                "CONT COPY CSAVE CSRLIN DEF DEFDBL DEFINT MAXFILES DEFSNG DEFSTR DIM " +
                "DRAW DSKI END EQV ERASE ERR ERROR FIELD FILES FN FOR GET IF INPUT " +
                "INTERVAL IMP IPL KILL LET LFILES LINE LOAD LOCATE LPRINT LSET MAX " +
                "MERGE MOTOR NAME NEW NEXT OFF ON OPEN OUT OUTPUT PAINT POINT POKE " +
                "PRESET PRINT PSET PUT READ RSET SAVE SCREEN SET SOUND STEP STOP " +
                "SWAP TIME TO TROFF TRON USING VPOKE WAIT WIDTH")
  Dig_AddKwList("ATTR$ BIN$ CHR$ DSKO$ HEX$ INKEY$ INPUT$ LEFT$ MID$ MKD$ MKI$ MKS$ " +
                "OCT$ RIGHT$ SPACE$ SPRITE$ STR$ STRING$")
  Dig_AddKwList("ABS ASC ATN CDBL CINT COS CSNG CVD CVI CVS DSKF EOF EXP FIX FPOS " +
                "FRE INP INSTR INT KEY LEN LOC LOF LOG LPOS PAD PDL PEEK PLAY POS " +
                "RND SGN SIN SPC SPRITE SQR STICK STRIG TAB TAN VAL VARPTR VDP VPEEK")
  Dig_AddKwList("RESTORE AUTO RENUM DELETE RESUME ERL ELSE RUN LIST LLIST GOTO " +
                "RETURN THEN GOSUB")
  Dig_AddKwList("AND MOD NOT OR XOR")
  Dig_AddKwList("DATA REM")
  ; Dignified (nao devem ser tratadas como variavel; normalmente ja
  ; removidas/substituidas antes do estagio de renomeio, mas por seguranca)
  Dig_AddKwList("DEFINE DECLARE INCLUDE KEEP ENDIF FUNC RET EXIT TRUE FALSE")

  ; Vocabulario estendido do MSXBAS2ROM - mesmas 3 listas de BadigEditor.pb
  ; (FillKeywordMap), ver comentario de Dig_FillWordMap acima.
  If MapSize(KwMsxBas2RomDirective()) = 0
    Dig_FillWordMap(KwMsxBas2RomDirective(), "FILE TEXT")
    Dig_FillWordMap(KwMsxBas2RomStatement(),
      "KEYCLKOFF CLRKEY RUNASM RUNBAS MUTE RAMTOVRAM VRAMTORAM RAMTORAM RSCTORAM " +
      "DISSCR ENASCR PAGE CLRSCR SETFNT UPDFNTCLR CLIP WRTVRAM WRTFNT WRTCHR " +
      "WRTCLR WRTSCR WRTSPR WRTSPRPAT WRTSPRCLR WRTSPRATR PLYLOAD PLYSONG " +
      "PLYPLAY PLYMUTE PLYSOUND PLYLOOP PLYREPLAY IPOKE " +
      "FROM SCROLL FONT PATTERN FLIP ROTATE DATE " +
      "IRESTORE IREAD IDATA")
    Dig_FillWordMap(KwMsxBas2RomFunctionPlain(),
      "HEAP MSX NTSC TURBO MAKER IPEEK PSG COLLISION RESOURCE RESOURCESIZE " +
      "PLYSTATUS TILE USR0 USR1 USR2 USR3")
  EndIf
EndProcedure

; Quando Dig_ModeIsMsxBas2Rom (setado por Dig_Preprocess), tambem reconhece o
; vocabulario estendido do MSXBAS2ROM (KwMsxBas2RomDirective/Statement/
; FunctionPlain, ver BadigEditor.pb) como reservado - mesmos 3 mapas ja
; usados pelo destaque de sintaxe, consultados direto (sem copia/segunda
; lista), entao qualquer correcao futura de vocabulario beneficia destaque e
; pre-processamento juntos. Le o Global em vez de receber parametro porque
; os 3 call sites (dentro de Dig_CollectHardVar_Piece/Dig_ShortenVars_Piece/
; Dig_ScanLabelRefs_Piece) sao, eles mesmos, chamados via ponteiro de funcao
; de assinatura fixa - nao tem como repassar um parametro extra por ali.
Procedure.b Dig_IsReservedWord(W.s)
  Protected u.s = UCase(W)
  If FindMapElement(Dig_ReservedKw(), u)
    ProcedureReturn #True
  EndIf
  If Dig_ModeIsMsxBas2Rom
    If FindMapElement(KwMsxBas2RomDirective(), u)    : ProcedureReturn #True : EndIf
    If FindMapElement(KwMsxBas2RomStatement(), u)     : ProcedureReturn #True : EndIf
    If FindMapElement(KwMsxBas2RomFunctionPlain(), u) : ProcedureReturn #True : EndIf
  EndIf
  ; USRn / DEFUSRn (n = 1 digito opcional)
  If Left(u, 3) = "USR" And (Len(u) = 3 Or (Len(u) = 4 And Dig_IsDigit(Right(u, 1))))
    ProcedureReturn #True
  EndIf
  If Left(u, 6) = "DEFUSR" And (Len(u) = 6 Or (Len(u) = 7 And Dig_IsDigit(Right(u, 1))))
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

;- ------------------------------------------------------------
;- Segmentacao de uma linha em zonas CODE / STRING / COMMENT / DATA
;- (usada por todos os estagios que precisam "ver" so o codigo real,
;- ignorando literais de string, comentarios classicos e dados DATA)
;- ------------------------------------------------------------

Structure DigSegment
  Kind.s
  StartPos.i
  EndPos.i
EndStructure

Prototype.s Dig_PieceFn(Piece.s, LineNum.i)

Procedure Dig_Segment(Line.s, List Segs.DigSegment())
  ClearList(Segs())
  Protected pos.i = 1, len_.i = Len(Line)
  Protected c.s

  While pos <= len_
    c = Mid(Line, pos, 1)

    If c = Chr(34)
      Protected sStart.i = pos
      pos + 1
      While pos <= len_ And Mid(Line, pos, 1) <> Chr(34)
        pos + 1
      Wend
      If pos <= len_ : pos + 1 : EndIf
      AddElement(Segs()) : Segs()\Kind = "STRING" : Segs()\StartPos = sStart : Segs()\EndPos = pos - 1
      Continue
    EndIf

    If c = "'"
      AddElement(Segs()) : Segs()\Kind = "COMMENT" : Segs()\StartPos = pos : Segs()\EndPos = len_
      pos = len_ + 1
      Continue
    EndIf

    If UCase(Mid(Line, pos, 3)) = "REM" And Dig_WordBoundary(Line, pos, 3)
      AddElement(Segs()) : Segs()\Kind = "COMMENT" : Segs()\StartPos = pos : Segs()\EndPos = len_
      pos = len_ + 1
      Continue
    EndIf

    If UCase(Mid(Line, pos, 4)) = "DATA" And Dig_WordBoundary(Line, pos, 4)
      AddElement(Segs()) : Segs()\Kind = "CODE" : Segs()\StartPos = pos : Segs()\EndPos = pos + 3
      pos + 4
      Protected dStart.i = pos
      While pos <= len_ And Mid(Line, pos, 1) <> ":"
        pos + 1
      Wend
      If pos > dStart
        AddElement(Segs()) : Segs()\Kind = "DATA" : Segs()\StartPos = dStart : Segs()\EndPos = pos - 1
      EndIf
      Continue
    EndIf

    Protected codeStart.i = pos
    While pos <= len_
      c = Mid(Line, pos, 1)
      If c = Chr(34) : Break : EndIf
      If c = "'" : Break : EndIf
      If UCase(Mid(Line, pos, 3)) = "REM" And Dig_WordBoundary(Line, pos, 3) : Break : EndIf
      If UCase(Mid(Line, pos, 4)) = "DATA" And Dig_WordBoundary(Line, pos, 4) : Break : EndIf
      pos + 1
    Wend
    If pos > codeStart
      AddElement(Segs()) : Segs()\Kind = "CODE" : Segs()\StartPos = codeStart : Segs()\EndPos = pos - 1
    EndIf
  Wend
EndProcedure

; Aplica uma funcao de transformacao (por ponteiro) so nos trechos CODE de uma linha,
; devolvendo a linha reconstruida. A funcao recebe o texto do trecho CODE e o numero
; da linha fonte (p/ erros) e devolve o texto transformado.
Procedure.s Dig_MapCodeSegments(Line.s, LineNum.i, *Fn.Dig_PieceFn)
  Protected NewList segs.DigSegment()
  Dig_Segment(Line, segs())
  Protected out.s = ""
  ForEach segs()
    Protected piece.s = Mid(Line, segs()\StartPos, segs()\EndPos - segs()\StartPos + 1)
    If segs()\Kind = "CODE"
      piece = *Fn(piece, LineNum)
    EndIf
    out + piece
  Next
  ProcedureReturn out
EndProcedure

;- ------------------------------------------------------------
;- Remtags (##BB:comando=valor) - so lidos do arquivo principal,
;- nunca de arquivos incluidos via INCLUDE (mesma regra do
;- badig_settings.py original: read_remtags_from_code(self.args.input)).
;- Comandos suportados: EXPORT_FILE, ARGUMENTS, HELP (os mesmos
;- registrados em badig_settings.py - CONVERT_ONLY/TOKENIZE citados
;- em badig_dignified.py nunca chegam a ser registrados como remtag
;- de fato nessa versao do toolchain).
;- ------------------------------------------------------------

Procedure.b Dig_Str2Bool(V.s, Fallback.b)
  Protected u.s = UCase(Trim(V))
  If u = "" : ProcedureReturn Fallback : EndIf
  If u = "TRUE" Or u = "1" Or u = "YES" Or u = "Y" Or u = "T"
    ProcedureReturn #True
  ElseIf u = "FALSE" Or u = "0" Or u = "NO" Or u = "N" Or u = "F"
    ProcedureReturn #False
  EndIf
  ProcedureReturn Fallback
EndProcedure

; Divide Text em tokens separados por espacos/tabs (ignora espacos repetidos).
Procedure Dig_SplitWhitespace(Text.s, List Out.s())
  ClearList(Out())
  Protected pos.i = 1, len_.i = Len(Text), start.i
  While pos <= len_
    While pos <= len_ And (Mid(Text, pos, 1) = " " Or Mid(Text, pos, 1) = Chr(9))
      pos + 1
    Wend
    If pos > len_ : Break : EndIf
    start = pos
    While pos <= len_ And Mid(Text, pos, 1) <> " " And Mid(Text, pos, 1) <> Chr(9)
      pos + 1
    Wend
    AddElement(Out()) : Out() = Mid(Text, start, pos - start)
  Wend
EndProcedure

; Aplica o conteudo do remtag ##BB:arguments=... como se fossem flags de linha
; de comando do badig.py, sobre os globals Dig_* de configuracao (efeito vale
; so para esta chamada de Dig_Preprocess - o chamador nao ve a mudanca, ver
; snapshot/restore em Dig_Preprocess). So reconhece o subconjunto de flags que
; este port nativo realmente suporta (-tl -ls -lp -rh -ss -ca -tr -cp -tg);
; as demais flags do badig.py/badig_msx.py (relatorios, -id, -vb, -asc, -ini,
; -rtg) sao aceitas e ignoradas (consumindo o valor quando a flag original as
; recebe) para nao desalinhar o parsing de flags subsequentes.
Procedure Dig_ApplyArgumentsRemtag(Value.s, LineNum.i)
  Protected NewList toks.s()
  Dig_SplitWhitespace(Value, toks())

  ForEach toks()
    Protected flag.s = LCase(toks())

    Select flag
      Case "-tl"
        If NextElement(toks()) : Dig_TabLength = Val(toks()) : EndIf
      Case "-ls"
        If NextElement(toks()) : Dig_LineStart = Val(toks()) : EndIf
      Case "-lp"
        If NextElement(toks()) : Dig_LineStep = Val(toks()) : EndIf
      Case "-rh"
        Dig_RemHeader = #False ; store_false no argparse original: presenca desliga
      Case "-ss"
        Dig_StripSpaces = #True
      Case "-ca"
        Dig_CapitalizeAll = #True
      Case "-tr"
        Dig_Translate = #True
      Case "-cp"
        If NextElement(toks())
          If LCase(toks()) = "p" : Dig_ConvertPrintCfg = "P" : Else : Dig_ConvertPrintCfg = "?" : EndIf
        EndIf
      Case "-tg"
        If NextElement(toks())
          If LCase(toks()) = "g" : Dig_StripThenGotoCfg = "G" : Else : Dig_StripThenGotoCfg = "T" : EndIf
        EndIf
      ; flags reconhecidas mas sem efeito neste port (relatorios/modo CLI) -
      ; as que recebem valor precisam consumir o token seguinte para nao
      ; desalinhar o parser
      Case "-id", "-vb"
        NextElement(toks())
      Case "-prr", "-lbr", "-lnr", "-var", "-lex", "-par", "-asc", "-ini", "-rtg"
        ; sem valor, nada a consumir
      Default
        ; flag desconhecida - ignorada silenciosamente (mesmo espirito do log
        ; de aviso do original, que nao interrompe a conversao)
    EndSelect
  Next
EndProcedure

; Resolve o caminho do remtag export_file relativo ao diretorio do arquivo
; fonte (Dig_BasePath) - versao simplificada do new_save_file() do
; badig_settings.py original (so caminho relativo/absoluto, sem a logica
; completa de merge de nome+pasta separados).
Procedure.s Dig_ResolveExportFilePath(Value.s)
  Protected v.s = Trim(Value)
  If v = "" : ProcedureReturn "" : EndIf
  If FindString(v, ":") Or Left(v, 1) = "\" Or Left(v, 1) = "/"
    ProcedureReturn v ; ja e absoluto
  EndIf
  If Dig_BasePath = ""
    ProcedureReturn v
  EndIf
  ProcedureReturn Dig_BasePath + v
EndProcedure

Procedure Dig_ApplyRemtag(Key.s, Value.s, LineNum.i)
  Select UCase(Key)
    Case "ARGUMENTS"
      Dig_ApplyArgumentsRemtag(Value, LineNum)
    Case "EXPORT_FILE"
      Dig_ExportFileOverride = Dig_ResolveExportFilePath(Value)
    Case "HELP"
      Dig_RemtagHelpRequested = Dig_Str2Bool(Value, #True)
    Default
      ; remtag nao reconhecido - ignorado (equivalente ao log de aviso do
      ; original, nao e erro fatal)
  EndSelect
EndProcedure

; Reconhece e (se IsMainFile) aplica uma linha "##BB:comando=valor". Devolve
; #True se a linha era um remtag (deve ser descartada do fluxo de codigo,
; igual a qualquer outro comentario), independente de ter sido aplicada.
Procedure.b Dig_TryHandleRemtagLine(Trimmed.s, LineNum.i, IsMainFile.b)
  Protected upperTrim.s = UCase(Trimmed)
  If Left(upperTrim, 5) <> "##BB:"
    ProcedureReturn #False
  EndIf
  Protected rest.s = Mid(Trimmed, 6)
  Protected eqPos.i = FindString(rest, "=")
  If eqPos = 0
    ProcedureReturn #True ; formato invalido - so descarta a linha
  EndIf
  Protected key.s = Trim(Left(rest, eqPos - 1))
  Protected value.s = Mid(rest, eqPos + 1)
  If IsMainFile
    Dig_ApplyRemtag(key, value, LineNum)
  EndIf
  ProcedureReturn #True
EndProcedure

;- ------------------------------------------------------------
;- Estagio 1: comentarios (## / ### / '')
;- ------------------------------------------------------------

; Processa a lista de linhas fonte (ja com tabs expandidos) removendo comentarios.
; Blocos ''..'' viram linhas de comentario classico (mantidas, marcadas como finais).
Procedure Dig_StripComments(List RawLines.s(), List OutLines.s(), List OutIsComment.b(), List OutSrcLine.i(), IsMainFile.b = #True)
  Protected inExclusiveBlock.b = #False  ; ###
  Protected inRegularBlock.b = #False    ; ''
  Protected srcLine.i = 0
  Protected trimmed.s, upperTrim.s

  ClearList(OutLines())
  ClearList(OutIsComment())
  ClearList(OutSrcLine())

  ForEach RawLines()
    srcLine + 1
    trimmed = Trim(RawLines())
    upperTrim = UCase(trimmed)

    If Dig_TryHandleRemtagLine(trimmed, srcLine, IsMainFile)
      Continue
    EndIf

    ; Bloco ### ... ### - o marcador nao precisa estar sozinho na linha (pode
    ; ter conteudo colado antes/depois, ex: "###	Insert ML routines" na
    ; abertura ou "...VRAM=&h1940###" no fechamento) - tudo isso e comentario.
    If inExclusiveBlock
      If Right(RTrim(trimmed), 3) = "###"
        inExclusiveBlock = #False
      EndIf
      Continue
    EndIf

    If Left(upperTrim, 3) = "###"
      Protected afterHHH.s = RTrim(Mid(trimmed, 4))
      If Len(afterHHH) > 3 And Right(afterHHH, 3) = "###"
        Continue ; "### algo ###" numa linha so - nao abre bloco persistente
      EndIf
      inExclusiveBlock = #True
      Continue
    EndIf

    ; Bloco '' ... '' - mesma logica, mas o conteudo (inclusive nas linhas de
    ; abertura/fechamento) vira comentario classico MANTIDO, nao removido.
    If inRegularBlock
      Protected closesHere.b = Bool(Right(RTrim(trimmed), 2) = "''")
      Protected keptContent.s = trimmed
      If closesHere
        keptContent = RTrim(Left(RTrim(trimmed), Len(RTrim(trimmed)) - 2))
      EndIf
      ; So suprime a linha quando ela e o marcador de fechamento sozinho (nada
      ; mais) - uma linha em branco normal dentro do bloco ainda vira um
      ; comentario vazio ("'"), conforme a regra "blank lines are removed
      ; except the ones inside regular block comments" da doc.
      If Not (closesHere And Trim(trimmed) = "''")
        AddElement(OutLines()) : OutLines() = "'" + keptContent
        AddElement(OutIsComment()) : OutIsComment() = #True
        AddElement(OutSrcLine()) : OutSrcLine() = srcLine
      EndIf
      If closesHere
        inRegularBlock = #False
      EndIf
      Continue
    EndIf

    If Left(trimmed, 2) = "''"
      Protected afterOpen.s = Mid(trimmed, 3)
      Protected afterOpenTrim.s = RTrim(afterOpen)
      If Len(afterOpenTrim) > 2 And Right(afterOpenTrim, 2) = "''"
        Protected singleContent.s = RTrim(Left(afterOpenTrim, Len(afterOpenTrim) - 2))
        AddElement(OutLines()) : OutLines() = "'" + singleContent
        AddElement(OutIsComment()) : OutIsComment() = #True
        AddElement(OutSrcLine()) : OutSrcLine() = srcLine
        Continue
      EndIf
      inRegularBlock = #True
      If trimmed <> "''"
        AddElement(OutLines()) : OutLines() = "'" + afterOpen
        AddElement(OutIsComment()) : OutIsComment() = #True
        AddElement(OutSrcLine()) : OutSrcLine() = srcLine
      EndIf
      Continue
    EndIf

    ; "##" e comentario exclusivo em QUALQUER posicao da linha (nao so no
    ; inicio) - trunca dali ate o fim, respeitando strings entre aspas
    Protected hashPos.i = Dig_FindUnquoted(trimmed, "##")
    If hashPos > 0
      trimmed = Trim(Left(trimmed, hashPos - 1))
    EndIf

    If trimmed = ""
      Continue
    EndIf

    AddElement(OutLines()) : OutLines() = trimmed
    AddElement(OutIsComment()) : OutIsComment() = #False
    AddElement(OutSrcLine()) : OutSrcLine() = srcLine
  Next

  If inExclusiveBlock
    Dig_Fail(srcLine, "Bloco de comentario ### nao fechado.")
  EndIf
  If inRegularBlock
    Dig_Fail(srcLine, "Bloco de comentario '' nao fechado.")
  EndIf
EndProcedure

;- ------------------------------------------------------------
;- Estagio 2: toggle rems (#nome) e KEEP
;- ------------------------------------------------------------

Global NewMap Dig_Keeps.b()
Global Dig_KeepAll.b
Global Dig_KeepNone.b

Procedure.b Dig_IsToggleName(W.s)
  ; #nome : letras/numeros/underscore, nao pode comecar com numero
  If Left(W, 1) <> "#" Or Len(W) < 2
    ProcedureReturn #False
  EndIf
  Protected rest.s = Mid(W, 2)
  If Dig_IsDigit(Left(rest, 1))
    ProcedureReturn #False
  EndIf
  Protected i.i
  For i = 1 To Len(rest)
    If Not Dig_IsWordChar(Mid(rest, i, 1))
      ProcedureReturn #False
    EndIf
  Next
  ProcedureReturn #True
EndProcedure

Procedure.b Dig_ShouldKeep(Name.s)
  Protected u.s = UCase(Name)
  If Dig_KeepNone
    ProcedureReturn #False
  EndIf
  If Dig_KeepAll
    ProcedureReturn #True
  EndIf
  ProcedureReturn Bool(FindMapElement(Dig_Keeps(), u))
EndProcedure

Procedure Dig_ApplyKeep(Name.s)
  Protected u.s = UCase(Name)
  If u = "#ALL"
    Dig_KeepAll = #True
  ElseIf u = "#NONE"
    Dig_KeepNone = #True
  Else
    Dig_Keeps(u) = #True
  EndIf
EndProcedure

; Remove linhas "keep #a #b" (registrando) e blocos/linhas marcadas com toggle rem
; nao mantido. Opera sobre as linhas ja sem comentarios.
Procedure Dig_StripToggles(List InLines.s(), List InIsComment.b(), List InSrcLine.i(),
                          List OutLines.s(), List OutIsComment.b(), List OutSrcLine.i())
  Protected trimmed.s, firstWord.s, activeToggle.s, blockMode.b
  Protected i.i

  ClearList(OutLines())
  ClearList(OutIsComment())
  ClearList(OutSrcLine())

  ResetList(InLines())
  ResetList(InIsComment())
  ResetList(InSrcLine())

  Protected skippingToggle.s = ""

  While NextElement(InLines())
    NextElement(InIsComment())
    NextElement(InSrcLine())

    trimmed = InLines()

    If InIsComment()
      If skippingToggle = ""
        AddElement(OutLines()) : OutLines() = trimmed
        AddElement(OutIsComment()) : OutIsComment() = #True
        AddElement(OutSrcLine()) : OutSrcLine() = InSrcLine()
      EndIf
      Continue
    EndIf

    firstWord = StringField(trimmed, 1, " ")

    ; fechamento de bloco de toggle ativo
    If skippingToggle <> "" And UCase(firstWord) = skippingToggle And Trim(Mid(trimmed, Len(firstWord) + 1)) = ""
      skippingToggle = ""
      Continue
    EndIf
    If skippingToggle <> ""
      Continue
    EndIf

    If UCase(firstWord) = "KEEP"
      Protected rest.s = Trim(Mid(trimmed, 5))
      If rest <> ""
        Protected n.i = CountString(rest, " ") + 1
        For i = 1 To n
          Protected tg.s = StringField(rest, i, " ")
          If tg <> ""
            If Not Dig_IsToggleName(tg) And UCase(tg) <> "#ALL" And UCase(tg) <> "#NONE"
              Dig_Fail(InSrcLine(), "Nome de keep invalido: " + tg)
              ProcedureReturn
            EndIf
            Dig_ApplyKeep(tg)
          EndIf
        Next
      EndIf
      Continue
    EndIf

    If Dig_IsToggleName(firstWord)
      Protected afterToggle.s = Trim(Mid(trimmed, Len(firstWord) + 1))
      If afterToggle = ""
        ; forma de bloco: abre ou a linha e so o toggle (bloco de 1+ linhas)
        If Dig_ShouldKeep(firstWord)
          Continue ; mantido: so remove a linha do toggle em si
        Else
          skippingToggle = UCase(firstWord)
          Continue
        EndIf
      Else
        ; forma de linha: toggle no inicio, resto da linha e o conteudo
        If Dig_ShouldKeep(firstWord)
          AddElement(OutLines()) : OutLines() = afterToggle
          AddElement(OutIsComment()) : OutIsComment() = #False
          AddElement(OutSrcLine()) : OutSrcLine() = InSrcLine()
        EndIf
        Continue
      EndIf
    EndIf

    AddElement(OutLines()) : OutLines() = trimmed
    AddElement(OutIsComment()) : OutIsComment() = #False
    AddElement(OutSrcLine()) : OutSrcLine() = InSrcLine()
  Wend

  If skippingToggle <> ""
    Dig_Fail(0, "Toggle rem nao fechado: " + skippingToggle)
  EndIf
EndProcedure

;- ------------------------------------------------------------
;- Estagio 3: juncao de linhas (_ no fim / : no inicio ou fim)
;- ------------------------------------------------------------

Procedure Dig_JoinLines(List InLines.s(), List InIsComment.b(), List InSrcLine.i(),
                       List OutLines.s(), List OutIsComment.b(), List OutSrcLine.i())
  Protected acc.s = "", accSrc.i = 0, accIsComment.b = #False
  Protected pendingJoin.b = #False
  Protected pendingJoinSpace.b = #False
  Protected haveAcc.b = #False
  Protected trimmedAcc.s

  ClearList(OutLines())
  ClearList(OutIsComment())
  ClearList(OutSrcLine())

  ResetList(InLines())
  ResetList(InIsComment())
  ResetList(InSrcLine())

  While NextElement(InLines())
    NextElement(InIsComment())
    NextElement(InSrcLine())

    If InIsComment()
      ; comentarios de bloco '' nunca participam de juncao - fecham qualquer pendencia
      If haveAcc
        AddElement(OutLines()) : OutLines() = acc
        AddElement(OutIsComment()) : OutIsComment() = accIsComment
        AddElement(OutSrcLine()) : OutSrcLine() = accSrc
        haveAcc = #False
        pendingJoin = #False
      EndIf
      AddElement(OutLines()) : OutLines() = InLines()
      AddElement(OutIsComment()) : OutIsComment() = #True
      AddElement(OutSrcLine()) : OutSrcLine() = InSrcLine()
      Continue
    EndIf

    If pendingJoin Or (haveAcc And Left(Trim(InLines()), 1) = ":")
      If pendingJoin And pendingJoinSpace
        acc = acc + " " + Trim(InLines())
      Else
        acc = acc + Trim(InLines())
      EndIf
      pendingJoin = #False
      pendingJoinSpace = #False
    Else
      If haveAcc
        AddElement(OutLines()) : OutLines() = acc
        AddElement(OutIsComment()) : OutIsComment() = accIsComment
        AddElement(OutSrcLine()) : OutSrcLine() = accSrc
      EndIf
      acc = Trim(InLines())
      accSrc = InSrcLine()
      accIsComment = #False
      haveAcc = #True
    EndIf

    Repeat
      trimmedAcc = RTrim(acc)
      If Len(trimmedAcc) >= 1 And Right(trimmedAcc, 1) = "_" And (Len(trimmedAcc) = 1 Or Mid(trimmedAcc, Len(trimmedAcc) - 1, 1) = " ")
        acc = RTrim(Left(trimmedAcc, Len(trimmedAcc) - 1))
        pendingJoin = #True
        pendingJoinSpace = #True
        Break
      ElseIf Len(trimmedAcc) >= 1 And Right(trimmedAcc, 1) = ":"
        acc = trimmedAcc
        pendingJoin = #True
        pendingJoinSpace = #False
        Break
      Else
        acc = trimmedAcc
        Break
      EndIf
    ForEver
  Wend

  If haveAcc
    AddElement(OutLines()) : OutLines() = acc
    AddElement(OutIsComment()) : OutIsComment() = accIsComment
    AddElement(OutSrcLine()) : OutSrcLine() = accSrc
  EndIf
EndProcedure

;- ------------------------------------------------------------
;- Estagio 4: DEFINE
;- ------------------------------------------------------------

Structure DigDefineEntry
  Repl.s
  HasVar.b
  DefaultVal.s
EndStructure

Global NewMap Dig_Defines.DigDefineEntry()

#Dig_VarMarker = Chr(2) + "V" + Chr(2)

; Le o conteudo entre colchetes a partir de Text(Pos)='[' ate o ']' correspondente,
; permitindo UM nivel de aninhamento (para a variavel posicional). Devolve o conteudo
; (sem os colchetes externos) e avanca *NewPos para logo apos o ']' de fechamento.
Procedure.s Dig_ReadBracket(Text.s, Pos.i, *NewPos.Integer)
  Protected depth.i = 1, start.i = Pos + 1, i.i = Pos + 1

  While i <= Len(Text) And depth > 0
    If Mid(Text, i, 1) = "["
      depth + 1
    ElseIf Mid(Text, i, 1) = "]"
      depth - 1
      If depth = 0
        Break
      EndIf
    EndIf
    i + 1
  Wend

  *NewPos\i = i + 1
  ProcedureReturn Mid(Text, start, i - start)
EndProcedure

Procedure.b Dig_ValidIdentName(Name.s)
  If Name = "" Or Dig_IsDigit(Left(Name, 1))
    ProcedureReturn #False
  EndIf
  Protected i.i
  For i = 1 To Len(Name)
    If Not Dig_IsWordChar(Mid(Name, i, 1))
      ProcedureReturn #False
    EndIf
  Next
  ProcedureReturn #True
EndProcedure

Procedure Dig_RegisterDefine(Name.s, Content.s, LineNum.i)
  Protected lname.s = LCase(Name)
  If Not Dig_ValidIdentName(Name)
    Dig_Fail(LineNum, "Nome de define invalido: " + Name)
    ProcedureReturn
  EndIf
  If FindMapElement(Dig_Defines(), lname)
    Dig_Fail(LineNum, "Define duplicado: " + Name)
    ProcedureReturn
  EndIf

  Protected entry.DigDefineEntry
  Protected bracketPos.i = FindString(Content, "[")
  If bracketPos > 0
    Protected np.i
    Protected varDefault.s = Dig_ReadBracket(Content, bracketPos, @np)
    entry\Repl = Left(Content, bracketPos - 1) + #Dig_VarMarker + Mid(Content, np)
    entry\HasVar = #True
    entry\DefaultVal = varDefault
  Else
    entry\Repl = Content
    entry\HasVar = #False
    entry\DefaultVal = ""
  EndIf

  Dig_Defines(lname) = entry
EndProcedure

Procedure Dig_InitBuiltinDefines()
  ; [?](x,y) -> LOCATE x,y:? / LOCATE 0,0:? sem argumento (modulo MSX)
  Protected entry.DigDefineEntry
  entry\Repl = "locate " + #Dig_VarMarker + ":?"
  entry\HasVar = #True
  entry\DefaultVal = "0,0"
  Dig_Defines("?") = entry
EndProcedure

; Expande [nome] ou [nome](arg) uma unica vez a partir da posicao Pos (que deve
; apontar para o '['). Devolve o texto expandido e avanca *NewPos.
Procedure.s Dig_ExpandOneDefine(Text.s, Pos.i, LineNum.i, *NewPos.Integer)
  Protected np.i
  Protected name.s = Dig_ReadBracket(Text, Pos, @np)
  Protected lname.s = LCase(Trim(name))

  If Not FindMapElement(Dig_Defines(), lname)
    Dig_Fail(LineNum, Trim(name) + " define nao definido.")
    *NewPos\i = np
    ProcedureReturn ""
  EndIf

  Protected entry.DigDefineEntry = Dig_Defines()
  Protected argText.s = entry\DefaultVal
  Protected pos2.i = np

  If Mid(Text, pos2, 1) = "("
    Protected depth.i = 1, start.i = pos2 + 1, i.i = pos2 + 1
    While i <= Len(Text) And depth > 0
      If Mid(Text, i, 1) = "(" : depth + 1
      ElseIf Mid(Text, i, 1) = ")" : depth - 1 : If depth = 0 : Break : EndIf
      EndIf
      i + 1
    Wend
    Protected inner.s = Trim(Mid(Text, start, i - start))
    If inner <> ""
      argText = inner
    EndIf
    pos2 = i + 1
  EndIf

  *NewPos\i = pos2

  If entry\HasVar
    ProcedureReturn ReplaceString(entry\Repl, #Dig_VarMarker, argText)
  Else
    ProcedureReturn entry\Repl
  EndIf
EndProcedure

; Expande [nome]/[nome](arg) repetidamente ate estabilizar, para suportar
; defines usados dentro de outros defines (inclusive como argumento, ex:
; [pause]([enter])) - uma unica passada nao pegaria o [enter] recem-inserido.
Procedure.s Dig_ExpandDefinesInCode(Piece.s, LineNum.i)
  Protected iterations.i = 0, changed.b, out.s, pos.i

  Repeat
    changed = #False
    out = ""
    pos = 1
    While pos <= Len(Piece)
      If Mid(Piece, pos, 1) = "[" And Not Dig_HasError
        Protected np.i
        out + Dig_ExpandOneDefine(Piece, pos, LineNum, @np)
        pos = np
        changed = #True
      Else
        out + Mid(Piece, pos, 1)
        pos + 1
      EndIf
    Wend
    Piece = out
    iterations + 1
  Until Not changed Or iterations > 25 Or Dig_HasError

  ProcedureReturn Piece
EndProcedure

; Processa DEFINE (registro) e substitui usos de [nome] nas linhas seguintes.
; "define [n1][c1],[n2][c2]" no inicio de uma linha registra e remove a linha.
Procedure Dig_ProcessDefines(List InLines.s(), List InIsComment.b(), List InSrcLine.i(),
                            List OutLines.s(), List OutIsComment.b(), List OutSrcLine.i())
  Protected trimmed.s, firstWord.s

  ClearList(OutLines()) : ClearList(OutIsComment()) : ClearList(OutSrcLine())
  Dig_InitBuiltinDefines()

  ResetList(InLines()) : ResetList(InIsComment()) : ResetList(InSrcLine())

  While NextElement(InLines())
    NextElement(InIsComment())
    NextElement(InSrcLine())

    trimmed = InLines()

    If InIsComment()
      AddElement(OutLines()) : OutLines() = trimmed
      AddElement(OutIsComment()) : OutIsComment() = #True
      AddElement(OutSrcLine()) : OutSrcLine() = InSrcLine()
      Continue
    EndIf

    firstWord = StringField(trimmed, 1, " ")

    If UCase(firstWord) = "DEFINE"
      Protected rest.s = Trim(Mid(trimmed, 7))
      Protected pos.i = 1
      While pos <= Len(rest)
        If Mid(rest, pos, 1) = "["
          Protected np1.i
          Protected dname.s = Dig_ReadBracket(rest, pos, @np1)
          While Mid(rest, np1, 1) = " "
            np1 + 1
          Wend
          If Mid(rest, np1, 1) <> "["
            Dig_Fail(InSrcLine(), "Define sem conteudo: " + dname)
            ProcedureReturn
          EndIf
          Protected np2.i
          Protected dcontent.s = Dig_ReadBracket(rest, np1, @np2)
          Dig_RegisterDefine(dname, dcontent, InSrcLine())
          If Dig_HasError : ProcedureReturn : EndIf
          pos = np2
          While Mid(rest, pos, 1) = " "
            pos + 1
          Wend
          If Mid(rest, pos, 1) = ","
            pos + 1
          EndIf
        Else
          pos + 1
        EndIf
      Wend
      Continue
    EndIf

    Protected mapped.s = Dig_MapCodeSegments(trimmed, InSrcLine(), @Dig_ExpandDefinesInCode())
    If Dig_HasError : ProcedureReturn : EndIf

    AddElement(OutLines()) : OutLines() = mapped
    AddElement(OutIsComment()) : OutIsComment() = #False
    AddElement(OutSrcLine()) : OutSrcLine() = InSrcLine()
  Wend
EndProcedure

;- ------------------------------------------------------------
;- Estagio 5: DECLARE + reducao de variaveis longas -> curtas
;- ------------------------------------------------------------

Global NewMap Dig_Declares.s()      ; nome longo (minusculo) -> nome curto
Global NewMap Dig_HardShort.b()     ; nomes curtos (<=2) usados literalmente
Global NewMap Dig_HardLong.b()      ; nomes longos marcados com ~ (mantidos)
Global Dig_VarIndex.i = 675          ; 26*26 - 1, contador decrescente (ZZ -> AA)

Procedure.s Dig_ShortNameFor(Index.i)
  Protected h.i = Index / 26, l.i = Index % 26
  ProcedureReturn Chr(97 + h) + Chr(97 + l)
EndProcedure

; Processa linhas "declare a:x, b:y, c, d:z" no inicio de uma linha.
Procedure Dig_ProcessDeclares(List InLines.s(), List InIsComment.b(), List InSrcLine.i(),
                             List OutLines.s(), List OutIsComment.b(), List OutSrcLine.i())
  Protected trimmed.s, firstWord.s

  ClearList(OutLines()) : ClearList(OutIsComment()) : ClearList(OutSrcLine())
  ResetList(InLines()) : ResetList(InIsComment()) : ResetList(InSrcLine())

  While NextElement(InLines())
    NextElement(InIsComment())
    NextElement(InSrcLine())
    trimmed = InLines()

    If InIsComment()
      AddElement(OutLines()) : OutLines() = trimmed
      AddElement(OutIsComment()) : OutIsComment() = #True
      AddElement(OutSrcLine()) : OutSrcLine() = InSrcLine()
      Continue
    EndIf

    firstWord = StringField(trimmed, 1, " ")

    ; INCLUDE e reconhecido/expandido mais adiante (durante a extracao de
    ; labels em Dig_ProcessSource) - aqui so deixa passar sem tratamento,
    ; igual a qualquer outra linha de codigo comum.

    If UCase(firstWord) = "DECLARE"
      Protected rest.s = Trim(Mid(trimmed, 8))
      Protected n.i = CountString(rest, ",") + 1, i.i
      For i = 1 To n
        Protected item.s = Trim(StringField(rest, i, ","))
        If item = "" : Continue : EndIf
        Protected colonPos.i = FindString(item, ":")
        If colonPos > 0
          Protected longName.s = Trim(Left(item, colonPos - 1))
          Protected shortName.s = LCase(Trim(Mid(item, colonPos + 1)))
          If Not Dig_ValidIdentName(longName) Or Len(longName) < 2
            Dig_Fail(InSrcLine(), "Declare invalido: " + item)
            ProcedureReturn
          EndIf
          Dig_Declares(LCase(longName)) = shortName
          If Len(shortName) <= 2
            Dig_HardShort(shortName) = #True
          EndIf
        Else
          If Len(item) <= 2
            Dig_HardShort(LCase(item)) = #True
          Else
            Dig_HardLong(LCase(item)) = #True
          EndIf
        EndIf
      Next
      Continue
    EndIf

    AddElement(OutLines()) : OutLines() = trimmed
    AddElement(OutIsComment()) : OutIsComment() = #False
    AddElement(OutSrcLine()) : OutSrcLine() = InSrcLine()
  Wend
EndProcedure

; Primeiro scan: coleta ~nome (mantidos longos, marcador removido do texto) e
; identificadores curtos (<=2) usados literalmente (para nao colidir na atribuicao automatica).
Procedure.s Dig_CollectHardVar_Piece(Piece.s, LineNum.i)
  Protected out.s = "", pos.i = 1
  While pos <= Len(Piece)
    Protected c.s = Mid(Piece, pos, 1)
    If c = #Dig_Mark
      Protected mEnd.i = FindString(Piece, #Dig_Mark, pos + 1)
      If mEnd = 0 : mEnd = Len(Piece) : Else : mEnd = mEnd + 1 : EndIf
      out + Mid(Piece, pos, mEnd - pos)
      pos = mEnd
      Continue
    EndIf
    If c = "&" And (UCase(Mid(Piece, pos + 1, 1)) = "H" Or UCase(Mid(Piece, pos + 1, 1)) = "O" Or UCase(Mid(Piece, pos + 1, 1)) = "B")
      ; literal hex/octal/binario (&Hff, &O17, &B101) - nao e identificador
      Protected numEnd.i = pos + 2
      While numEnd <= Len(Piece) And Dig_IsWordChar(Mid(Piece, numEnd, 1))
        numEnd + 1
      Wend
      out + Mid(Piece, pos, numEnd - pos)
      pos = numEnd
      Continue
    EndIf
    If c = "~" And Dig_IsAlpha(Mid(Piece, pos + 1, 1))
      Protected start.i = pos + 1, i.i = pos + 1
      While i <= Len(Piece) And Dig_IsWordChar(Mid(Piece, i, 1))
        i + 1
      Wend
      Protected suf.s = Mid(Piece, i, 1)
      If suf = "$" Or suf = "%" Or suf = "!" Or suf = "#"
        i + 1
      EndIf
      Protected nm.s = Mid(Piece, start, i - start)
      Dig_HardLong(LCase(RTrim(RTrim(RTrim(nm, "#"), "!"), "%"))) = #True
      out + Mid(Piece, start, i - start)
      pos = i
      Continue
    ElseIf Dig_IsAlpha(c)
      start = pos
      i = pos
      While i <= Len(Piece) And Dig_IsWordChar(Mid(Piece, i, 1))
        i + 1
      Wend
      Protected word.s = Mid(Piece, start, i - start)
      Protected wsuf.s = Mid(Piece, i, 1)
      If wsuf = "$" Or wsuf = "%" Or wsuf = "!" Or wsuf = "#"
        i + 1
      EndIf
      If Not Dig_IsReservedWord(word) And Len(word) <= 2 And Len(word) >= 1
        Dig_HardShort(LCase(word)) = #True
      EndIf
      out + Mid(Piece, start, i - start)
      pos = i
      Continue
    EndIf
    out + c
    pos + 1
  Wend
  ProcedureReturn out
EndProcedure

; Segundo scan: substitui identificadores longos (>=3, nao reservados, nao ~) pelo
; nome curto declarado ou atribuido automaticamente (ZZ -> AA decrescente).
Procedure.s Dig_ShortenVars_Piece(Piece.s, LineNum.i)
  Protected out.s = "", pos.i = 1
  While pos <= Len(Piece)
    Protected c.s = Mid(Piece, pos, 1)
    If c = #Dig_Mark
      Protected mEnd.i = FindString(Piece, #Dig_Mark, pos + 1)
      If mEnd = 0 : mEnd = Len(Piece) : Else : mEnd = mEnd + 1 : EndIf
      out + Mid(Piece, pos, mEnd - pos)
      pos = mEnd
      Continue
    EndIf
    If c = "&" And (UCase(Mid(Piece, pos + 1, 1)) = "H" Or UCase(Mid(Piece, pos + 1, 1)) = "O" Or UCase(Mid(Piece, pos + 1, 1)) = "B")
      Protected numEnd.i = pos + 2
      While numEnd <= Len(Piece) And Dig_IsWordChar(Mid(Piece, numEnd, 1))
        numEnd + 1
      Wend
      out + Mid(Piece, pos, numEnd - pos)
      pos = numEnd
      Continue
    EndIf
    If Dig_IsAlpha(c)
      Protected start.i = pos, i.i = pos
      While i <= Len(Piece) And Dig_IsWordChar(Mid(Piece, i, 1))
        i + 1
      Wend
      Protected word.s = Mid(Piece, start, i - start)
      Protected suf.s = Mid(Piece, i, 1)
      Protected consumedSuf.s = ""
      If suf = "$" Or suf = "%" Or suf = "!" Or suf = "#"
        consumedSuf = suf
        i + 1
      EndIf

      If Dig_IsReservedWord(word) Or Len(word) <= 2
        out + word + consumedSuf
      ElseIf FindMapElement(Dig_HardLong(), LCase(word))
        out + word + consumedSuf
      Else
        Protected lword.s = LCase(word)
        Protected shortN.s
        If FindMapElement(Dig_Declares(), lword)
          shortN = Dig_Declares()
        Else
          Repeat
            If Dig_VarIndex < 0
              Dig_Fail(LineNum, "Muitas variaveis usadas (max=676): " + word)
              ProcedureReturn out
            EndIf
            shortN = Dig_ShortNameFor(Dig_VarIndex)
            Dig_VarIndex - 1
          Until Not FindMapElement(Dig_HardShort(), shortN)
          Dig_Declares(lword) = shortN
        EndIf
        out + UCase(shortN) + consumedSuf
      EndIf
      pos = i
      Continue
    EndIf
    out + c
    pos + 1
  Wend
  ProcedureReturn out
EndProcedure

Procedure Dig_ProcessVariables(List Lines.s(), List IsComment.b(), List SrcLine.i())
  ; primeiro scan: coleta ~nome e nomes curtos hardcoded, removendo o marcador ~
  ResetList(Lines()) : ResetList(IsComment()) : ResetList(SrcLine())
  While NextElement(Lines())
    NextElement(IsComment()) : NextElement(SrcLine())
    If Not IsComment()
      Lines() = Dig_MapCodeSegments(Lines(), SrcLine(), @Dig_CollectHardVar_Piece())
    EndIf
  Wend
  If Dig_HasError : ProcedureReturn : EndIf

  ; segundo scan: substitui nomes longos
  ResetList(Lines()) : ResetList(IsComment()) : ResetList(SrcLine())
  While NextElement(Lines())
    NextElement(IsComment()) : NextElement(SrcLine())
    If Not IsComment()
      Lines() = Dig_MapCodeSegments(Lines(), SrcLine(), @Dig_ShortenVars_Piece())
      If Dig_HasError : ProcedureReturn : EndIf
    EndIf
  Wend
EndProcedure

;- ------------------------------------------------------------
;- Estagio 5b: proto-funcoes (FUNC / RET / chamadas .nome(args))
;- ------------------------------------------------------------

Global NewMap Dig_FuncParams.s()    ; funcname -> "p1;p2;p3" (nomes dos parametros)
Global NewMap Dig_FuncDefaults.s()  ; funcname -> "d1;d2;d3" (default de cada param, "" = sem default)
Global NewMap Dig_FuncRets.s()      ; funcname -> "e1;e2;e3" (expressoes do RET)
Global Dig_InFunc.s = ""            ; nome (minusculo) da funcao sendo definida agora, "" se nenhuma

; Separa Text em partes por virgulas de nivel superior (ignora virgulas dentro
; de parenteses aninhados ou de literais entre aspas). Reusado para argumentos
; de FUNC, expressoes de RET e argumentos de chamada .nome(args).
Procedure Dig_SplitArgs(Text.s, List Out.s())
  ClearList(Out())
  If Trim(Text) = ""
    ProcedureReturn
  EndIf

  Protected depth.i = 0, inStr.b = #False, start.i = 1, i.i = 1, c.s

  While i <= Len(Text)
    c = Mid(Text, i, 1)
    If inStr
      If c = Chr(34) : inStr = #False : EndIf
    Else
      If c = Chr(34)
        inStr = #True
      ElseIf c = "("
        depth + 1
      ElseIf c = ")"
        depth - 1
      ElseIf c = "," And depth = 0
        AddElement(Out()) : Out() = Trim(Mid(Text, start, i - start))
        start = i + 1
      EndIf
    EndIf
    i + 1
  Wend
  AddElement(Out()) : Out() = Trim(Mid(Text, start, Len(Text) - start + 1))
EndProcedure

; Acha a posicao do ')' que fecha o '(' em Text(OpenPos), respeitando
; parenteses aninhados e literais entre aspas. Devolve 0 se nao fechar.
Procedure.i Dig_FindMatchingParen(Text.s, OpenPos.i)
  Protected depth.i = 1, i.i = OpenPos + 1, inStr.b = #False, c.s
  While i <= Len(Text)
    c = Mid(Text, i, 1)
    If inStr
      If c = Chr(34) : inStr = #False : EndIf
    Else
      If c = Chr(34) : inStr = #True
      ElseIf c = "(" : depth + 1
      ElseIf c = ")"
        depth - 1
        If depth = 0 : ProcedureReturn i : EndIf
      EndIf
    EndIf
    i + 1
  Wend
  ProcedureReturn 0
EndProcedure

; Processa uma linha "func .nome(p1, p2=default, ...)". So chamado quando a
; primeira palavra da linha (ja em maiusculas) e "FUNC".
; Devolve #True se processou com sucesso (linha deve ser descartada do fluxo,
; como um label sozinho na linha).
Procedure.b Dig_HandleFuncDef(Trimmed.s, LineNum.i)
  If Dig_InFunc <> ""
    Dig_Fail(LineNum, "Ja dentro de uma funcao: " + Dig_InFunc)
    ProcedureReturn #False
  EndIf

  Protected rest.s = Trim(Mid(Trimmed, 5))
  If Left(rest, 1) <> "."
    Dig_Fail(LineNum, "Nome de funcao invalido: " + rest)
    ProcedureReturn #False
  EndIf

  Protected parenPos.i = FindString(rest, "(")
  If parenPos = 0
    Dig_Fail(LineNum, "Funcao sem parenteses: " + rest)
    ProcedureReturn #False
  EndIf

  Protected fname.s = LCase(Trim(Mid(rest, 2, parenPos - 2)))
  If Not Dig_ValidIdentName(fname)
    Dig_Fail(LineNum, "Nome de funcao invalido: " + fname)
    ProcedureReturn #False
  EndIf
  If FindMapElement(Dig_FuncParams(), fname)
    Dig_Fail(LineNum, "Funcao duplicada: " + fname)
    ProcedureReturn #False
  EndIf

  Protected closeParen.i = Dig_FindMatchingParen(rest, parenPos)
  If closeParen = 0
    Dig_Fail(LineNum, "Parenteses nao fechados na funcao: " + fname)
    ProcedureReturn #False
  EndIf

  If Trim(Mid(rest, closeParen + 1)) <> ""
    ; "pode ter qualquer coisa depois" (DIFFERENCES.md) nao esta implementado
    ; nesta v1 - erro explicito em vez de descartar o conteudo silenciosamente
    Dig_Fail(LineNum, "Conteudo apos 'func .nome(...)' na mesma linha ainda nao e suportado (v1): " + fname)
    ProcedureReturn #False
  EndIf

  Protected NewList args.s()
  Dig_SplitArgs(Mid(rest, parenPos + 1, closeParen - parenPos - 1), args())

  Protected paramList.s = "", defaultList.s = ""
  ForEach args()
    Protected argText.s = args()
    Protected eqPos.i = FindString(argText, "=")
    Protected pname.s, pdefault.s
    If eqPos > 0
      pname = Trim(Left(argText, eqPos - 1))
      pdefault = Trim(Mid(argText, eqPos + 1))
    Else
      pname = Trim(argText)
      pdefault = ""
    EndIf
    If Not Dig_ValidIdentName(RTrim(RTrim(RTrim(RTrim(pname, "#"), "!"), "%"), "$"))
      Dig_Fail(LineNum, "Argumento de funcao invalido: " + argText)
      ProcedureReturn #False
    EndIf
    If paramList <> "" : paramList + ";" : defaultList + ";" : EndIf
    paramList + pname
    defaultList + pdefault
  Next

  Dig_FuncParams(fname) = paramList
  Dig_FuncDefaults(fname) = defaultList
  Dig_FuncRets(fname) = ""
  Dig_InFunc = fname

  ProcedureReturn #True
EndProcedure

; Acha a posicao do ULTIMO ':' de nivel superior em Text (fora de literais
; entre aspas) - devolve 0 se nao houver nenhum. Usado pra achar "ret ..."
; colado no final de uma linha logica que Dig_JoinLines ja fundiu com a(s)
; linha(s) anterior(es) via ':' de continuacao (ex.: "gosub {x}:" seguido de
; "ret y" no fonte vira uma linha so' "gosub {x}:ret y" antes de chegar aqui -
; sem isso, "ret" deixa de ser a primeira palavra da linha e a deteccao de
; RET abaixo nunca dispara, deixando Dig_InFunc preso e estourando "Ja dentro
; de uma funcao" no proximo FUNC. Ver `others/menu.dmx` linha 161).
Procedure.i Dig_FindLastTopLevelColon(Text.s)
  Protected inStr.b = #False, i.i, c.s, lastPos.i = 0
  For i = 1 To Len(Text)
    c = Mid(Text, i, 1)
    If inStr
      If c = Chr(34) : inStr = #False : EndIf
    Else
      If c = Chr(34)
        inStr = #True
      ElseIf c = ":"
        lastPos = i
      EndIf
    EndIf
  Next
  ProcedureReturn lastPos
EndProcedure

; Processa uma linha "ret [e1, e2, ...]". Devolve o texto que substitui a
; linha (sempre so a palavra RETURN - as expressoes ficam guardadas para
; serem injetadas nos pontos de chamada).
Procedure.s Dig_HandleFuncRet(Trimmed.s, LineNum.i)
  If Dig_InFunc = ""
    Dig_Fail(LineNum, "RET sem FUNC correspondente.")
    ProcedureReturn ""
  EndIf

  Protected rest.s = Trim(Mid(Trimmed, 4))
  Protected NewList rets.s()
  Dig_SplitArgs(rest, rets())

  Protected retList.s = ""
  ForEach rets()
    If retList <> "" : retList + ";" : EndIf
    retList + rets()
  Next
  Dig_FuncRets(Dig_InFunc) = retList
  Dig_InFunc = ""

  ProcedureReturn "RETURN"
EndProcedure

; Tenta reconhecer "var1, var2 = " logo antes da posicao atual do fim de
; *OutStr\s (usado antes de uma chamada .nome(...) para capturar retornos).
; Em caso de sucesso, MODIFICA *OutStr\s removendo esse prefixo e preenche
; CaptureVars(); em caso de falha deixa tudo intacto e a lista vazia.
Procedure Dig_TryExtractCaptureVars(*OutStr.String, List CaptureVars.s())
  ClearList(CaptureVars())
  Protected s.s = *OutStr\s
  Protected i.i = Len(s)

  While i >= 1 And Mid(s, i, 1) = " "
    i - 1
  Wend
  If i < 1 Or Mid(s, i, 1) <> "="
    ProcedureReturn
  EndIf
  Protected beforeEq.s = Mid(s, i - 1, 1)
  If beforeEq = "<" Or beforeEq = ">" Or beforeEq = "="
    ProcedureReturn
  EndIf
  i - 1

  Protected scanPos.i = i
  While scanPos >= 1
    Protected c.s = Mid(s, scanPos, 1)
    If c = " " Or c = "," Or Dig_IsWordChar(c) Or c = "$" Or c = "%" Or c = "!" Or c = "#"
      scanPos - 1
    Else
      Break
    EndIf
  Wend

  Protected startBoundary.i = scanPos + 1
  Protected candidate.s = Mid(s, startBoundary, i - startBoundary + 1)
  If Trim(candidate) = ""
    ProcedureReturn
  EndIf

  Protected n.i = CountString(candidate, ",") + 1, k.i
  For k = 1 To n
    Protected piece.s = Trim(StringField(candidate, k, ","))
    If piece = "" Or Not Dig_IsAlpha(Left(piece, 1))
      ProcedureReturn
    EndIf
    Protected pi.i
    For pi = 2 To Len(piece)
      Protected pc.s = Mid(piece, pi, 1)
      If Not (Dig_IsWordChar(pc) Or pc = "$" Or pc = "%" Or pc = "!" Or pc = "#")
        ProcedureReturn
      EndIf
    Next
  Next

  For k = 1 To n
    AddElement(CaptureVars())
    CaptureVars() = Trim(StringField(candidate, k, ","))
  Next

  *OutStr\s = Left(s, startBoundary - 1)
EndProcedure

; Monta o texto de substituicao para uma chamada .nome(args), incluindo
; atribuicao de argumentos, o GOSUB (marcador a resolver depois) e atribuicao
; dos retornos capturados, evitando "X=X" quando o valor ja e o mesmo.
Procedure.s Dig_BuildFuncCallReplacement(FuncName.s, List ArgTexts.s(), List CaptureVars.s(), LineNum.i)
  If Not FindMapElement(Dig_FuncParams(), FuncName)
    Dig_Fail(LineNum, "Funcao nao definida: ." + FuncName)
    ProcedureReturn ""
  EndIf

  Protected paramList.s = Dig_FuncParams()
  Protected defaultList.s = Dig_FuncDefaults(FuncName)
  Protected retList.s = Dig_FuncRets(FuncName)

  Protected nParams.i = 0
  If paramList <> "" : nParams = CountString(paramList, ";") + 1 : EndIf
  Protected nArgs.i = ListSize(ArgTexts())

  If nArgs > nParams
    Dig_Fail(LineNum, "Chamada com argumentos demais: ." + FuncName)
    ProcedureReturn ""
  EndIf

  Protected result.s = "", k.i
  ResetList(ArgTexts())
  For k = 1 To nParams
    Protected pname.s = StringField(paramList, k, ";")
    Protected pdefault.s = StringField(defaultList, k, ";")
    Protected callVal.s = ""
    If k <= nArgs
      NextElement(ArgTexts())
      callVal = ArgTexts()
    EndIf

    If callVal <> ""
      If Trim(callVal) <> Trim(pname)
        result + pname + "=" + callVal + ":"
      EndIf
    ElseIf pdefault <> ""
      If Trim(pdefault) <> Trim(pname)
        result + pname + "=" + pdefault + ":"
      EndIf
    EndIf
  Next

  result + "GOSUB " + #Dig_Mark + "G" + Dig_FuncLabelName(Dig_CurrentPrefix, FuncName) + #Dig_Mark

  Protected nRets.i = 0
  If retList <> "" : nRets = CountString(retList, ";") + 1 : EndIf
  Protected nCaps.i = ListSize(CaptureVars())
  ResetList(CaptureVars())
  For k = 1 To nCaps
    NextElement(CaptureVars())
    If k <= nRets
      Protected rexpr.s = StringField(retList, k, ";")
      If Trim(rexpr) <> Trim(CaptureVars())
        result + ":" + CaptureVars() + "=" + rexpr
      EndIf
    EndIf
  Next

  ProcedureReturn result
EndProcedure

; Varre uma linha INTEIRA (nao um segmento CODE isolado - precisa ver a linha
; toda porque os argumentos da chamada podem conter literais de string, o que
; quebraria o casamento de parenteses se so enxergasse um pedaco) procurando
; chamadas .nome(args), com captura opcional de retorno "var1,var2 = .nome(args)"
; imediatamente antes. Tem sua propria consciencia de string/comentario/DATA
; (nao usa Dig_MapCodeSegments) para poder olhar a linha completa com seguranca.
Procedure.s Dig_FuncCalls_Piece(Line.s, LineNum.i)
  Protected out.s = "", pos.i = 1, inStr.b = #False, c.s

  While pos <= Len(Line)
    c = Mid(Line, pos, 1)

    If c = Chr(34)
      If inStr : inStr = #False : Else : inStr = #True : EndIf
      out + c
      pos + 1
      Continue
    EndIf

    If Not inStr
      ; comentario ('  ou REM) - copia o resto da linha sem processar
      If c = "'" Or (UCase(Mid(Line, pos, 3)) = "REM" And Dig_WordBoundary(Line, pos, 3))
        out + Mid(Line, pos)
        Break
      EndIf

      ; DATA - copia ate o proximo ':' sem processar (conteudo literal)
      If UCase(Mid(Line, pos, 4)) = "DATA" And Dig_WordBoundary(Line, pos, 4)
        Protected dEnd.i = FindString(Line, ":", pos + 4)
        If dEnd = 0 : dEnd = Len(Line) + 1 : EndIf
        out + Mid(Line, pos, dEnd - pos)
        pos = dEnd
        Continue
      EndIf

      If c = "." And Dig_IsAlpha(Mid(Line, pos + 1, 1))
        Protected np.i = pos + 1
        While np <= Len(Line) And Dig_IsWordChar(Mid(Line, np, 1))
          np + 1
        Wend
        If Mid(Line, np, 1) = "("
          Protected fname.s = LCase(Mid(Line, pos + 1, np - pos - 1))
          Protected closeParen.i = Dig_FindMatchingParen(Line, np)
          If closeParen = 0
            Dig_Fail(LineNum, "Parenteses nao fechados na chamada: ." + fname)
            ProcedureReturn out
          EndIf

          Protected NewList callArgs.s()
          Dig_SplitArgs(Mid(Line, np + 1, closeParen - np - 1), callArgs())

          Protected outWrap.String
          outWrap\s = out
          Protected NewList captureVars.s()
          Dig_TryExtractCaptureVars(@outWrap, captureVars())
          out = outWrap\s

          out + Dig_BuildFuncCallReplacement(fname, callArgs(), captureVars(), LineNum)
          If Dig_HasError
            ProcedureReturn out
          EndIf

          pos = closeParen + 1
          Continue
        EndIf
      EndIf
    EndIf

    out + c
    pos + 1
  Wend

  ProcedureReturn out
EndProcedure

;- ------------------------------------------------------------
;- Estagio 6: labels, loop labels, EXIT
;- Marcadores inseridos no texto (resolvidos apos a numeracao):
;-   Chr(2)+"J"+nome+Chr(2)   = referencia de salto para o label "nome"
;-   Chr(2)+"S"+Chr(2)        = referencia de salto para a propria linha ({@})
;-   Chr(2)+"B"+nome+Chr(2)   = volta de loop (GOTO para o label de abertura)
;-   Chr(2)+"X"+nome+Chr(2)   = saida de loop (GOTO para a linha apos o fechamento)
;- ------------------------------------------------------------

Structure DigLogLine
  Text.s
  LabelNames.s   ; nomes de label (separados por ";") que apontam para esta linha
  SrcLine.i
  LineNumber.i
  IsComment.b
  IsResourceDirective.b ; #True so em modo MSXBAS2ROM: linha "FILE .../TEXT ..." -
                        ; nao recebe numero de linha nem consome um passo de
                        ; numeracao, ver Dig_IsResourceDirectiveLine()/Dig_Preprocess
EndStructure

; Diretiva de recurso do MSXBAS2ROM ("FILE <arquivo>"/"TEXT <string>") - de
; acordo com a documentacao oficial (resource-directives.md), essas linhas
; NAO tem numero de linha (ficam antes do codigo numerado, sua ORDEM de
; aparicao define o indice do recurso usado por "SCREEN LOAD 0"/"CMD RESTORE
; 1"/etc.) - diferente de qualquer outro statement classico ou do proprio
; vocabulario estendido (CMD .../SET .../etc., que SAO statements numerados
; normais). So chamada quando Dig_ModeIsMsxBas2Rom.
Procedure.b Dig_IsResourceDirectiveLine(Text.s)
  Protected firstWord.s = UCase(StringField(Trim(Text), 1, " "))
  ProcedureReturn Bool(firstWord = "FILE" Or firstWord = "TEXT")
EndProcedure

Global Dim Dig_LoopStack.s(255)
Global Dig_LoopStackTop.i = -1
Global NewMap Dig_LabelLine.i()
Global NewMap Dig_LoopExit.i()   ; nome do loop -> linha para onde EXIT deve saltar

Procedure.s Dig_ReadIdent(Text.s, Pos.i, *NewPos.Integer)
  Protected start.i = Pos, i.i = Pos
  While i <= Len(Text) And Dig_IsWordChar(Mid(Text, i, 1))
    i + 1
  Wend
  *NewPos\i = i
  ProcedureReturn Mid(Text, start, i - start)
EndProcedure

; Devolve a proxima posicao em Text a partir de Pos que nao seja espaco/tab -
; usado pelos tres pontos que reconhecem sintaxe de label ("{nome}"/"nome{")
; pra tolerar espaco/tab colado nas chaves (ex. "{ nome }"), ja que fonte real
; de Basic Dignified (programas dos anos 80 convertidos por usuarios) usa
; esse estilo com espaco por legibilidade - bug real encontrado 2026-08-20
; com o programa "Hyper Copy" (Marcelo Fontolan, 1988): "gosub { apresentacao
; }" falhava com "Label mal formado" porque Dig_ReadIdent(Piece, pos+1, @np)
; via o espaco logo depois de "{" e devolvia nome vazio na hora. O lexer real
; do badig.py original (Python) tokeniza "{"/identificador/"}" como tokens
; SEPARADOS num unico regex combinado (ver docs/reference/dignified-core.md,
; "scanner por maximal munch") - espaco entre tokens e insignificante la,
; entao esse é o comportamento certo a replicar, nao uma coincidencia do
; port ter ficado mais rigido.
Procedure.i Dig_SkipSpaces(Text.s, Pos.i)
  Protected p.i = Pos
  While p <= Len(Text) And (Mid(Text, p, 1) = " " Or Mid(Text, p, 1) = Chr(9))
    p + 1
  Wend
  ProcedureReturn p
EndProcedure

; Processa referencias de jump {nome}, fechamento de loop } e EXIT dentro do
; trecho de codigo de uma linha (labels de abertura ja foram extraidos antes).
Procedure.s Dig_ScanLabelRefs_Piece(Piece.s, LineNum.i)
  Protected out.s = "", pos.i = 1

  While pos <= Len(Piece)
    Protected c.s = Mid(Piece, pos, 1)

    If c = "{"
      Protected np.i
      Protected name.s
      Protected innerPos.i = Dig_SkipSpaces(Piece, pos + 1)
      If Mid(Piece, innerPos, 1) = "@"
        name = "@"
        np = innerPos + 1
      Else
        name = Dig_ReadIdent(Piece, innerPos, @np)
      EndIf
      np = Dig_SkipSpaces(Piece, np)
      If Mid(Piece, np, 1) <> "}" Or name = ""
        Dig_Fail(LineNum, "Label mal formado.")
        ProcedureReturn out
      EndIf
      If name = "@"
        out + #Dig_Mark + "S" + #Dig_Mark
      Else
        out + #Dig_Mark + "J" + Dig_CurrentPrefix + LCase(name) + #Dig_Mark
      EndIf
      pos = np + 1
      Continue
    EndIf

    If c = "}"
      If Dig_LoopStackTop < 0
        Dig_Fail(LineNum, "Fechamento de loop sem abertura.")
        ProcedureReturn out
      EndIf
      Protected loopName.s = Dig_LoopStack(Dig_LoopStackTop)
      Dig_LoopStackTop - 1
      If Trim(out) <> ""
        out + ":"
      EndIf
      out + "GOTO " + #Dig_Mark + "B" + loopName + #Dig_Mark
      pos + 1
      Continue
    EndIf

    If UCase(Mid(Piece, pos, 4)) = "EXIT" And Dig_WordBoundary(Piece, pos, 4)
      If Dig_LoopStackTop < 0
        Dig_Fail(LineNum, "EXIT fora de loop.")
        ProcedureReturn out
      EndIf
      Protected exitLoop.s = Dig_LoopStack(Dig_LoopStackTop)
      out + "GOTO " + #Dig_Mark + "X" + exitLoop + #Dig_Mark
      pos + 4
      Continue
    EndIf

    out + c
    pos + 1
  Wend

  ProcedureReturn out
EndProcedure

; Extrai a declaracao de label no inicio da linha (se houver): "{nome}resto" ou
; "nome{resto". Devolve o nome do label extraido ("" se nao houver) e o texto restante.
Procedure.s Dig_ExtractLeadingLabel(Line.s, *LabelOut.String)
  *LabelOut\s = ""

  If Left(Line, 1) = "{"
    Protected np.i
    Protected innerPos.i = Dig_SkipSpaces(Line, 2)
    Protected name.s = Dig_ReadIdent(Line, innerPos, @np)
    np = Dig_SkipSpaces(Line, np)
    If Mid(Line, np, 1) = "}" And name <> "" And Not Dig_IsDigit(Left(name, 1))
      *LabelOut\s = Dig_CurrentPrefix + LCase(name)
      ProcedureReturn Trim(Mid(Line, np + 1))
    EndIf
  EndIf

  If Dig_IsAlpha(Left(Line, 1))
    ; Diferente de "{nome}" (referencia/definicao, delimitado dos dois lados,
    ; espaco interno e inofensivo de tolerar - ver Dig_SkipSpaces acima):
    ; aqui NAO tolera espaco entre o nome e "{" de proposito. Um rotulo de
    ; loop e "primeira palavra da linha imediatamente seguida de {", sem
    ; delimitador do outro lado - tolerar espaco faria QUALQUER instrucao
    ; classica cujo argumento comece com "{" (ex. "restore {label}", RESTORE
    ; do MSX-BASIC + referencia Dignified, nada a ver com loop) virar uma
    ; abertura de loop por engano, usando a propria palavra-chave como nome
    ; do loop - bug real encontrado ao vivo 2026-08-20 rodando a suite de
    ; regressao (dist/sample/teste.dmx tem "restore {character_shapes}" E
    ; "restore {ml_routines}", virando "Label duplicado: restore" depois de
    ; tolerar o espaco aqui por engano numa tentativa anterior deste fix).
    Protected np2.i
    Protected name2.s = Dig_ReadIdent(Line, 1, @np2)
    If Mid(Line, np2, 1) = "{" And name2 <> ""
      ; Checagem de limite antes de escrever no array Dim'd de tamanho fixo -
      ; sem isso, mais de ArraySize(Dig_LoopStack())+1 labels de loop
      ; aninhados corrompe heap silenciosamente em vez de falhar limpo (como
      ; todo outro limite estrutural deste arquivo: profundidade de include,
      ; contagem de variaveis, tamanho de linha).
      If Dig_LoopStackTop >= ArraySize(Dig_LoopStack())
        Dig_Fail(0, "Labels de loop aninhados demais (limite: " + Str(ArraySize(Dig_LoopStack()) + 1) + ")")
        ProcedureReturn ""
      EndIf
      *LabelOut\s = Dig_CurrentPrefix + LCase(name2)
      Dig_LoopStackTop + 1
      Dig_LoopStack(Dig_LoopStackTop) = Dig_CurrentPrefix + LCase(name2)
      ProcedureReturn Trim(Mid(Line, np2 + 1))
    EndIf
  EndIf

  ProcedureReturn Line
EndProcedure

;- ------------------------------------------------------------
;- Estagio 7: TRUE/FALSE e operadores compostos
;- ------------------------------------------------------------

Procedure.s Dig_BoolOps_Piece(Piece.s, LineNum.i)
  Protected out.s = "", pos.i = 1

  While pos <= Len(Piece)
    Protected c.s = Mid(Piece, pos, 1), c2.s = Mid(Piece, pos, 2)

    If c2 = "++" Or c2 = "--" Or c2 = "+=" Or c2 = "-=" Or c2 = "*=" Or c2 = "/=" Or c2 = "^="
      ; localiza a variavel imediatamente antes (ja no "out" construido, pulando
      ; espacos entre o nome e o operador)
      Protected varEnd.i = Len(out)
      While varEnd >= 1 And Mid(out, varEnd, 1) = " "
        varEnd - 1
      Wend
      Protected varStart.i = varEnd
      While varStart >= 1 And Dig_IsWordChar(Mid(out, varStart, 1))
        varStart - 1
      Wend
      Protected varName.s = Mid(out, varStart + 1, varEnd - varStart)

      If c2 = "++"
        out = Left(out, varStart) + varName + "=" + varName + "+1"
      ElseIf c2 = "--"
        out = Left(out, varStart) + varName + "=" + varName + "-1"
      Else
        Protected opChar.s = Left(c2, 1)
        Protected np.i = pos + 2
        While Mid(Piece, np, 1) = " "
          np + 1
        Wend
        Protected valStart.i = np
        While np <= Len(Piece) And Mid(Piece, np, 1) <> ":" And Not (UCase(Mid(Piece, np, 4)) = "THEN" And Dig_WordBoundary(Piece, np, 4)) And Not (UCase(Mid(Piece, np, 4)) = "ELSE" And Dig_WordBoundary(Piece, np, 4))
          np + 1
        Wend
        Protected valExpr.s = RTrim(Mid(Piece, valStart, np - valStart))
        out = Left(out, varStart) + varName + "=" + varName + opChar + valExpr
        pos = np
        Continue
      EndIf
      pos + 2
      Continue
    EndIf

    If UCase(Mid(Piece, pos, 5)) = "ENDIF" And Dig_WordBoundary(Piece, pos, 5)
      ; ENDIF e puramente cosmetico no Dignified - descartado sem processar,
      ; independente de onde aparece (regra da linguagem)
      pos + 5
      Continue
    EndIf

    If UCase(Mid(Piece, pos, 4)) = "TRUE" And Dig_WordBoundary(Piece, pos, 4)
      out + "-1"
      pos + 4
      Continue
    EndIf
    If UCase(Mid(Piece, pos, 5)) = "FALSE" And Dig_WordBoundary(Piece, pos, 5)
      out + "0"
      pos + 5
      Continue
    EndIf

    out + c
    pos + 1
  Wend

  ProcedureReturn out
EndProcedure

;- ------------------------------------------------------------
;- Tokenizacao generica em atomos (palavra/espaco/outro), usada
;- pelos passos de -cp / -tg / -ca / strip_spaces abaixo. Opera
;- sobre um trecho CODE (ja sem strings/comentarios/DATA).
;- ------------------------------------------------------------

Procedure Dig_TokenizeAtoms(Piece.s, List Atoms.s(), List AtomKind.s())
  ClearList(Atoms()) : ClearList(AtomKind())
  Protected pos.i = 1, len_.i = Len(Piece), c.s

  While pos <= len_
    c = Mid(Piece, pos, 1)

    If c = " " Or c = Chr(9)
      Protected sStart.i = pos
      While pos <= len_ And (Mid(Piece, pos, 1) = " " Or Mid(Piece, pos, 1) = Chr(9))
        pos + 1
      Wend
      AddElement(Atoms()) : Atoms() = Mid(Piece, sStart, pos - sStart)
      AddElement(AtomKind()) : AtomKind() = "SPACE"
      Continue
    EndIf

    If Dig_IsWordChar(c)
      Protected wStart.i = pos
      While pos <= len_ And Dig_IsWordChar(Mid(Piece, pos, 1))
        pos + 1
      Wend
      AddElement(Atoms()) : Atoms() = Mid(Piece, wStart, pos - wStart)
      AddElement(AtomKind()) : AtomKind() = "WORD"
      Continue
    EndIf

    AddElement(Atoms()) : Atoms() = c
    AddElement(AtomKind()) : AtomKind() = "OTHER"
    pos + 1
  Wend
EndProcedure

; Converte "?" <-> "PRINT" no inicio de instrucao (comeco do trecho, apos ":",
; ou apos "THEN"/"ELSE") conforme Dig_ConvertPrintCfg ("?" ou "P" = forma final
; desejada). Port de badig_msx.py pass_5 (bloco "Convert ? to print or vice versa").
Procedure.s Dig_ConvertPrint_Piece(Piece.s, LineNum.i)
  If Dig_ConvertPrintCfg = ""
    ProcedureReturn Piece
  EndIf

  Protected out.s = "", pos.i = 1, len_.i = Len(Piece), c.s
  Protected atStmtStart.b = #True

  While pos <= len_
    c = Mid(Piece, pos, 1)

    If c = " " Or c = Chr(9)
      out + c
      pos + 1
      Continue
    EndIf

    If c = ":"
      out + c
      pos + 1
      atStmtStart = #True
      Continue
    EndIf

    If atStmtStart And c = "?"
      If Dig_ConvertPrintCfg = "?"
        out + "?"
      Else
        out + "PRINT"
      EndIf
      pos + 1
      atStmtStart = #False
      Continue
    EndIf

    If Dig_IsWordChar(c)
      Protected wStart.i = pos
      While pos <= len_ And Dig_IsWordChar(Mid(Piece, pos, 1))
        pos + 1
      Wend
      Protected word.s = Mid(Piece, wStart, pos - wStart)
      Protected wordU.s = UCase(word)

      If atStmtStart And wordU = "PRINT"
        If Dig_ConvertPrintCfg = "?"
          out + "?"
        Else
          out + "PRINT"
        EndIf
      Else
        out + word
      EndIf

      atStmtStart = Bool(wordU = "THEN" Or wordU = "ELSE")
      Continue
    EndIf

    out + c
    pos + 1
    atStmtStart = #False
  Wend

  ProcedureReturn out
EndProcedure

; Remove THEN quando imediatamente seguido de GOTO (modo "T") ou remove GOTO
; quando imediatamente precedido de THEN/ELSE (modo "G"), conforme
; Dig_StripThenGotoCfg. Port de badig_msx.py pass_5 (blocos "Strip THEN before
; GOTO" / "Strip GOTO after THEN/ELSE").
Procedure.s Dig_StripThenGoto_Piece(Piece.s, LineNum.i)
  If Dig_StripThenGotoCfg = ""
    ProcedureReturn Piece
  EndIf

  Protected NewList atoms.s() : Protected NewList kinds.s()
  Dig_TokenizeAtoms(Piece, atoms(), kinds())

  Protected n.i = ListSize(atoms())
  If n = 0
    ProcedureReturn Piece
  EndIf

  Dim A.s(n - 1) : Dim K.s(n - 1) : Dim Skip.b(n - 1)
  Protected idx.i = 0
  ForEach atoms()
    A(idx) = atoms()
    idx + 1
  Next
  idx = 0
  ForEach kinds()
    K(idx) = kinds()
    idx + 1
  Next

  Protected i.i, j.i, p.i, wu.s

  For i = 0 To n - 1
    If K(i) = "WORD"
      wu = UCase(A(i))

      If Dig_StripThenGotoCfg = "T" And wu = "THEN"
        j = i + 1
        While j <= n - 1 And K(j) = "SPACE"
          j + 1
        Wend
        If j <= n - 1 And K(j) = "WORD" And UCase(A(j)) = "GOTO"
          Skip(i) = #True
          If i + 1 <= n - 1 And K(i + 1) = "SPACE"
            Skip(i + 1) = #True
          EndIf
        EndIf

      ElseIf Dig_StripThenGotoCfg = "G" And wu = "GOTO"
        p = i - 1
        While p >= 0 And K(p) = "SPACE"
          p - 1
        Wend
        If p >= 0 And K(p) = "WORD" And (UCase(A(p)) = "THEN" Or UCase(A(p)) = "ELSE")
          Skip(i) = #True
          If i + 1 <= n - 1 And K(i + 1) = "SPACE"
            Skip(i + 1) = #True
          EndIf
        EndIf
      EndIf
    EndIf
  Next

  Protected out.s = ""
  For i = 0 To n - 1
    If Not Skip(i)
      out + A(i)
    EndIf
  Next

  ProcedureReturn out
EndProcedure

; Maiusculiza todo o trecho CODE (identificadores/keywords) - chamado via
; Dig_MapCodeSegments, que ja deixa de fora strings/REM/DATA, entao aqui basta
; UCase() no trecho inteiro. Port de badig.py generate() ("capitalise_all
; aplicado por ultimo, sobre tudo que nao e literal").
Procedure.s Dig_CapitalizeAll_Piece(Piece.s, LineNum.i)
  If Not Dig_CapitalizeAll
    ProcedureReturn Piece
  EndIf
  ProcedureReturn UCase(Piece)
EndProcedure

; Atomo WORD e "puramente numerico" (so digitos)? Usado por Dig_StripSpaces_Piece
; para distinguir "SCREEN" (letras) de "2" (numero): um digito nunca estende o
; casamento de uma palavra-chave classica (o tokenizador para em "SCREEN" e
; retoma o numero em seguida), entao "SCREEN 2"/"STEP 10" podem virar
; "SCREEN2"/"STEP10" sem ambiguidade - so identificador-identificador
; ("PRINT A") e numero-numero (colariam num unico literal) precisam do espaco.
Procedure.b Dig_AtomIsNumeric(A.s)
  Protected i.i
  If Len(A) = 0
    ProcedureReturn #False
  EndIf
  For i = 1 To Len(A)
    If Not Dig_IsDigit(Mid(A, i, 1))
      ProcedureReturn #False
    EndIf
  Next
  ProcedureReturn #True
EndProcedure

; O tokenizador (Tok_TokenizeLineBody/MsxTokenizer.pbi) casa palavras-chave por
; "maior prefixo primeiro" em QUALQUER posicao, sem exigir fronteira de palavra
; (e por isso "FORI=1TO10" tokeniza igual a "FOR I=1 TO 10" no MSX real, e
; "PRINT"+"A" vira PRINT+A normalmente) - entao colar dois atomos de letras nao
; e perigoso por si so. O perigo real e mais estreito: durante a varredura de
; identificador, o tokenizador para assim que o restante do texto casar com
; QUALQUER palavra-chave (ver loop "isVar" em Tok_TokenizeLineBody) - entao um
; espaco so precisa sobreviver quando colar os dois atomos faz uma
; palavra-chave nascer exatamente na fronteira (ex.: "X"+"OR"->"XOR", ou
; "ERR"+"OR"->"ERROR", que e ELA MESMA uma palavra-chave distinta e mais longa
; que "ERR"). Varre todo inicio dentro de Left cujo casamento avanca alem do
; fim de Left (ou seja, so dispara quando o match cruza para dentro de Right -
; uma palavra-chave inteiramente contida em Left, sem cruzar a fronteira, ja
; teria o mesmo problema mesmo sem remover o espaco, entao nao e desta funcao).
#Dig_MaxReservedWordLen = 10

Procedure.b Dig_BoundaryFormsKeyword(Left.s, Right.s)
  Protected merged.s = UCase(Left) + UCase(Right)
  Protected leftLen.i = Len(Left)
  Protected totalLen.i = Len(merged)
  Protected p.i, l.i, endPos.i

  For p = 1 To leftLen
    For l = 1 To #Dig_MaxReservedWordLen
      endPos = p + l - 1
      If endPos > totalLen
        Break
      EndIf
      If endPos > leftLen And Dig_IsReservedWord(Mid(merged, p, l))
        ProcedureReturn #True
      EndIf
    Next l
  Next p

  ProcedureReturn #False
EndProcedure

; Remove espacos "cosmeticos" de um trecho CODE, preservando o espaco entre
; duas palavras adjacentes numericas (senao "1" " " "2" colaria em "12") ou
; entre duas palavras de letras quando colar cria uma palavra-chave na
; fronteira (ver Dig_BoundaryFormsKeyword); palavra-chave junto de numero
; ("SCREEN 2", "STEP 10") ou duas palavras de letras "seguras" ("FOR ZZ",
; "GOTO 100" nao se aplica aqui pois 100 e numero, mas "FOR ZZ"->"FORZZ" sim)
; perdem o espaco.
; Reinterpretacao pragmatica do -ss original (que remove espacos token a
; token no nivel do lexer) - nao e garantido byte-a-byte identico.
Procedure.s Dig_StripSpaces_Piece(Piece.s, LineNum.i)
  If Not Dig_StripSpaces
    ProcedureReturn Piece
  EndIf

  Protected NewList atoms.s() : Protected NewList kinds.s()
  Dig_TokenizeAtoms(Piece, atoms(), kinds())

  Protected n.i = ListSize(atoms())
  If n = 0
    ProcedureReturn Piece
  EndIf

  Dim A.s(n - 1) : Dim K.s(n - 1)
  Protected idx.i = 0
  ForEach atoms()
    A(idx) = atoms()
    idx + 1
  Next
  idx = 0
  ForEach kinds()
    K(idx) = kinds()
    idx + 1
  Next

  Protected out.s = "", i.i, leftNumeric.b, rightNumeric.b
  For i = 0 To n - 1
    If K(i) = "SPACE"
      If i > 0 And K(i - 1) = "WORD" And i < n - 1 And K(i + 1) = "WORD"
        leftNumeric = Dig_AtomIsNumeric(A(i - 1))
        rightNumeric = Dig_AtomIsNumeric(A(i + 1))
        If leftNumeric And rightNumeric
          out + " "
        ElseIf Not leftNumeric And Not rightNumeric And Dig_BoundaryFormsKeyword(A(i - 1), A(i + 1))
          out + " "
        EndIf
      EndIf
    Else
      out + A(i)
    EndIf
  Next

  ProcedureReturn out
EndProcedure

;- ------------------------------------------------------------
;- Traducao Unicode -> ASCII nativo MSX (-tr). Tabela extraida de
;- badig/msx/badig_msx.py (c_replacements/c_original/c_translat)
;- via scratchpad/extract_charset.py - validada (128 chars unicos,
;- c_translat sequencial 0x80..0xFF, sem overlap com c_replacements).
;- c_original[i] (1-based) -> Chr(&H80 + i - 1) via Dig_TransOriginal.
;- ------------------------------------------------------------

Global Dig_TransOriginal.s = "ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ¢£¥₧ƒáíóúñÑªº¿⌐¬½¼¡«»ÃãĨĩÕõŨũĲĳ¾∽◇‰¶§▂▚▆▔◾▇▎▞▊▕▉▨▧▼▲▶◀⧗⧓▘▗▝▖▒Δǂω█▄▌▐▀αβΓπΣσμτΦθΩδ∞φ∈∩≡±≥≤⌠⌡÷≈°∙‐√ⁿ²❚■"

; Mesma ordem/simbolos das 31 chaves do dict c_replacements de badig_msx.py
; (ordem de Dig_TransReplacement abaixo) - reaproveitada por CharMapGui.pbi
; pra nao retranscrever a lista uma segunda vez.
Global Dig_TransReplacementOrder.s = "☺☻♥♦♣♠·◘○◙♂♀♪♬☼┿┴┬┤├┼│─┌┐└┘╳╱╲╂"

; c_replacements de badig_msx.py: cada um destes 31 simbolos (carinhas/naipes/
; linhas tipo CP437, os "graficos" MSX de codigo 1-31) vira, no ASCII gerado,
; a sequencia de DOIS bytes Chr(1) + <letra> - NAO o simbolo em si nem so a
; letra. Chr(1) e o prefixo de escape que o driver de tela do MSX usa pra
; imprimir um dos 31 "graficos" especiais sem colidir com os codigos de
; controle de verdade (cursor etc.) que ocupam a mesma faixa 1-31; a letra
; que segue seleciona QUAL grafico - NAO é simplesmente "A + (posicao-1)":
; confirmado byte a byte contra c_replacements no Python de referencia
; (basic-dignified/msx/badig_msx.py) que as ultimas entradas nao seguem a
; sequencia alfabetica estrita (╳ -> "]" e ╱ -> "\" estao trocados em relacao
; a ordem alfabetica "esperada"), entao cada letra fica hardcoded abaixo
; exatamente como no original, em vez de calculada por formula.
;
; Confirmado rodando o badig.py de referencia de verdade (nao so lendo o
; fonte): "☺" converte pra bytes 01 41 ("\x01A"), nao pro byte 0x01 sozinho
; nem pra letra "A" sozinha. BUG HISTORICO deste port: a versao anterior
; desta funcao so devolvia a letra (ex. "A"), sem o Chr(1) na frente - Chr(1)
; e um caractere de controle invisivel, entao sumia sem deixar rastro visual
; tanto no source Python quanto neste arquivo .pbi ao serem lidos num
; visualizador de texto normal, so aparecendo numa inspecao dos BYTES crus
; dos dois arquivos lado a lado - foi assim que a discrepancia foi achada.
; Sem esse Chr(1), o -tr desses 31 simbolos gerava so a letra pura, nunca o
; grafico MSX de verdade.
Procedure.s Dig_TransReplacement(C.s)
  Select C
    Case "☺" : ProcedureReturn Chr(1) + "A"
    Case "☻" : ProcedureReturn Chr(1) + "B"
    Case "♥" : ProcedureReturn Chr(1) + "C"
    Case "♦" : ProcedureReturn Chr(1) + "D"
    Case "♣" : ProcedureReturn Chr(1) + "E"
    Case "♠" : ProcedureReturn Chr(1) + "F"
    Case "·" : ProcedureReturn Chr(1) + "G"
    Case "◘" : ProcedureReturn Chr(1) + "H"
    Case "○" : ProcedureReturn Chr(1) + "I"
    Case "◙" : ProcedureReturn Chr(1) + "J"
    Case "♂" : ProcedureReturn Chr(1) + "K"
    Case "♀" : ProcedureReturn Chr(1) + "L"
    Case "♪" : ProcedureReturn Chr(1) + "M"
    Case "♬" : ProcedureReturn Chr(1) + "N"
    Case "☼" : ProcedureReturn Chr(1) + "O"
    Case "┿" : ProcedureReturn Chr(1) + "P"
    Case "┴" : ProcedureReturn Chr(1) + "Q"
    Case "┬" : ProcedureReturn Chr(1) + "R"
    Case "┤" : ProcedureReturn Chr(1) + "S"
    Case "├" : ProcedureReturn Chr(1) + "T"
    Case "┼" : ProcedureReturn Chr(1) + "U"
    Case "│" : ProcedureReturn Chr(1) + "V"
    Case "─" : ProcedureReturn Chr(1) + "W"
    Case "┌" : ProcedureReturn Chr(1) + "X"
    Case "┐" : ProcedureReturn Chr(1) + "Y"
    Case "└" : ProcedureReturn Chr(1) + "Z"
    Case "┘" : ProcedureReturn Chr(1) + "["
    Case "╳" : ProcedureReturn Chr(1) + "]"
    Case "╱" : ProcedureReturn Chr(1) + "\"
    Case "╲" : ProcedureReturn Chr(1) + "^"
    Case "╂" : ProcedureReturn Chr(1) + "_"
  EndSelect
  ProcedureReturn C
EndProcedure

; Converte texto com caracteres Unicode especiais (graficos/acentos/gregas) para
; os codigos nativos MSX (0x80-0xFF) equivalentes. Porta byte-a-byte trans_char()
; de badig/msx/badig_msx.py (c_replacements aplicado primeiro, depois a tabela
; posicional c_original/c_translat). Aplicado sobre a linha final inteira (nao so
; trechos STRING/COMMENT/DATA): trechos CODE nunca contem esses caracteres porque
; identificadores/numeros/operadores sao restritos a ASCII pelo resto do pipeline.
Procedure.s Dig_TransChar(Text.s)
  If Not Dig_Translate
    ProcedureReturn Text
  EndIf

  Protected out.s = "", pos.i = 1, len_.i = Len(Text), c.s, p.i
  While pos <= len_
    c = Mid(Text, pos, 1)
    c = Dig_TransReplacement(c)
    p = FindString(Dig_TransOriginal, c)
    If p > 0
      out + Chr($7F + p)
    Else
      out + c
    EndIf
    pos + 1
  Wend
  ProcedureReturn out
EndProcedure

;- ------------------------------------------------------------
;- Funcao por-arquivo (recursiva para INCLUDE)
;- ------------------------------------------------------------

; Le um arquivo de texto inteiro (BOM-aware) - usado para carregar INCLUDE.
Procedure.s Dig_ReadTextFile(Path.s, LineNum.i)
  Protected fnum.i = ReadFile(#PB_Any, Path, #PB_File_BOM)
  If Not fnum
    Dig_Fail(LineNum, "Nao foi possivel abrir o arquivo de INCLUDE: " + Path)
    ProcedureReturn ""
  EndIf
  Protected content.s = ""
  While Not Eof(fnum)
    content + ReadString(fnum, #PB_File_IgnoreEOL) + Chr(13) + Chr(10)
  Wend
  CloseFile(fnum)
  ProcedureReturn content
EndProcedure

; Resolve o caminho de um INCLUDE "arquivo" relativo ao diretorio do arquivo
; que contem a instrucao (OwnBasePath, ja com separador final) - caminho
; absoluto (com ":" ou iniciando com barra) e usado como esta.
Procedure.s Dig_ResolveIncludePath(RawArg.s, OwnBasePath.s)
  If FindString(RawArg, ":") Or Left(RawArg, 1) = "\" Or Left(RawArg, 1) = "/"
    ProcedureReturn RawArg
  EndIf
  ProcedureReturn OwnBasePath + RawArg
EndProcedure

; Processa o texto-fonte de UM arquivo (principal ou incluido) ate o ponto
; logo antes da numeracao de linha (que so faz sentido para a arvore inteira
; ja mesclada) - devolve em OutLogLines a lista de "linhas logicas" desse
; arquivo, com nomes de label/funcao ja com o prefixo de namespace (Prefix)
; aplicado. Chamada recursivamente para cada INCLUDE encontrado, com um
; Prefix novo e unico por instancia - variaveis (Dig_Declares/HardShort/
; HardLong/VarIndex) continuam compartilhadas globalmente (nunca tocadas
; aqui); defines/toggles/funcoes/loop-labels sao isolados por chamada
; (salvos/restaurados ao redor desta execucao) - ver docs/SPEC.md modulo 3g.
Procedure Dig_ProcessSource(SourceText.s, Prefix.s, OwnBasePath.s, IsMainFile.b, List OutLogLines.DigLogLine())
  Protected NewMap savedDefines.DigDefineEntry()
  CopyMap(Dig_Defines(), savedDefines())
  ClearMap(Dig_Defines())

  ; CopyMap() com mapa de origem VAZIO e elemento de 1-2 bytes (.b()/.w()/.a())
  ; trava (read error at address 0) no PureBasic 6.40 instalado - confirmado via
  ; repro isolado fora deste arquivo (mapas .i()/.s() nao sao afetados). Dig_Keeps
  ; comeca vazio sempre que o arquivo nao usa nenhum toggle rem (#nome), ou seja,
  ; no caminho comum. Contorno: so chamar CopyMap quando ha algo a copiar; source
  ; vazio so precisa que o destino fique vazio, que e o que ClearMap ja faz.
  Protected NewMap savedKeeps.b()
  If MapSize(Dig_Keeps())
    CopyMap(Dig_Keeps(), savedKeeps())
  EndIf
  Protected savedKeepAll.b = Dig_KeepAll
  Protected savedKeepNone.b = Dig_KeepNone
  ClearMap(Dig_Keeps())
  Dig_KeepAll = #False
  Dig_KeepNone = #False

  Protected NewMap savedFuncParams.s()
  Protected NewMap savedFuncDefaults.s()
  Protected NewMap savedFuncRets.s()
  CopyMap(Dig_FuncParams(), savedFuncParams())
  CopyMap(Dig_FuncDefaults(), savedFuncDefaults())
  CopyMap(Dig_FuncRets(), savedFuncRets())
  Protected savedInFunc.s = Dig_InFunc
  ClearMap(Dig_FuncParams())
  ClearMap(Dig_FuncDefaults())
  ClearMap(Dig_FuncRets())
  Dig_InFunc = ""

  Protected savedPrefix.s = Dig_CurrentPrefix
  Dig_CurrentPrefix = Prefix

  Protected loopTopAtEntry.i = Dig_LoopStackTop

  ClearList(OutLogLines())

  Protected text.s = ReplaceString(SourceText, Chr(13) + Chr(10), Chr(10))
  text = ReplaceString(text, Chr(13), Chr(10))
  ; Trim() do PureBasic so remove espacos, nao tabs - expande tabs para espacos
  ; aqui para que indentacao com TAB nao quebre a deteccao de DEFINE/DECLARE/
  ; KEEP/labels no inicio de linha (todos comparam a primeira "palavra" apos Trim)
  text = ReplaceString(text, Chr(9), Space(Dig_TabLength))

  Protected NewList raw.s()
  Protected lc.i = CountString(text, Chr(10)) + 1, li.i
  For li = 1 To lc
    AddElement(raw())
    raw() = StringField(text, li, Chr(10))
  Next

  Protected NewList l1.s() : Protected NewList l1c.b() : Protected NewList l1s.i()
  Dig_StripComments(raw(), l1(), l1c(), l1s(), IsMainFile)
  If Dig_HasError : ProcedureReturn : EndIf

  Protected NewList l2.s() : Protected NewList l2c.b() : Protected NewList l2s.i()
  Dig_StripToggles(l1(), l1c(), l1s(), l2(), l2c(), l2s())
  If Dig_HasError : ProcedureReturn : EndIf

  Protected NewList l3.s() : Protected NewList l3c.b() : Protected NewList l3s.i()
  Dig_JoinLines(l2(), l2c(), l2s(), l3(), l3c(), l3s())
  If Dig_HasError : ProcedureReturn : EndIf

  Protected NewList l4.s() : Protected NewList l4c.b() : Protected NewList l4s.i()
  Dig_ProcessDefines(l3(), l3c(), l3s(), l4(), l4c(), l4s())
  If Dig_HasError : ProcedureReturn : EndIf

  Protected NewList l5.s() : Protected NewList l5c.b() : Protected NewList l5s.i()
  Dig_ProcessDeclares(l4(), l4c(), l4s(), l5(), l5c(), l5s())
  If Dig_HasError : ProcedureReturn : EndIf

  ; labels: extrai declaracao no inicio de cada linha, monta lista de "linhas
  ; logicas" deste arquivo (INCLUDE passa por aqui como uma linha comum - so
  ; e expandido/substituido depois, na secao de splicing abaixo)
  Protected NewList logLines.DigLogLine()
  Protected pendingLabels.s = ""

  ResetList(l5()) : ResetList(l5c()) : ResetList(l5s())
  While NextElement(l5())
    NextElement(l5c()) : NextElement(l5s())

    If l5c()
      AddElement(logLines())
      logLines()\Text = l5()
      logLines()\IsComment = #True
      logLines()\SrcLine = l5s()
      If pendingLabels <> ""
        logLines()\LabelNames = pendingLabels
        pendingLabels = ""
      EndIf
      Continue
    EndIf

    Protected firstWordU.s = UCase(StringField(l5(), 1, " "))

    If firstWordU = "FUNC"
      If Dig_HandleFuncDef(l5(), l5s())
        Protected synthLabel.s = Dig_FuncLabelName(Dig_CurrentPrefix, Dig_InFunc)
        If pendingLabels = ""
          pendingLabels = synthLabel
        Else
          pendingLabels + ";" + synthLabel
        EndIf
      EndIf
      If Dig_HasError : ProcedureReturn : EndIf
      Continue
    EndIf

    ; RET normalmente e a primeira (e unica) palavra da linha, mas pode vir
    ; colado no final de uma linha ja unida por Dig_JoinLines via ':' de
    ; continuacao (idioma classico "GOSUB {x}:RETURN" numa linha BASIC so) -
    ; ver Dig_FindLastTopLevelColon acima. Se nao houver ':' de nivel
    ; superior, retPrefix fica "" e o comportamento e identico ao de antes.
    Protected retColonPos.i = Dig_FindLastTopLevelColon(l5())
    Protected retTail.s = l5()
    Protected retPrefix.s = ""
    If retColonPos > 0
      retPrefix = Left(l5(), retColonPos)
      retTail = Trim(Mid(l5(), retColonPos + 1))
    EndIf

    If UCase(StringField(retTail, 1, " ")) = "RET"
      Protected retText.s = Dig_HandleFuncRet(retTail, l5s())
      If Dig_HasError : ProcedureReturn : EndIf
      AddElement(logLines())
      logLines()\Text = retPrefix + retText
      logLines()\IsComment = #False
      logLines()\SrcLine = l5s()
      If pendingLabels <> ""
        logLines()\LabelNames = pendingLabels
        pendingLabels = ""
      EndIf
      Continue
    EndIf

    Protected labelOut.String
    Protected rest.s = Dig_ExtractLeadingLabel(l5(), @labelOut)
    If Dig_HasError : ProcedureReturn : EndIf
    Protected thisLabel.s = labelOut\s

    If rest = "" And thisLabel <> ""
      ; label sozinho na linha: nao consome numero proprio, passa para a proxima
      If pendingLabels = ""
        pendingLabels = thisLabel
      Else
        pendingLabels + ";" + thisLabel
      EndIf
      Continue
    EndIf

    AddElement(logLines())
    logLines()\Text = rest
    logLines()\IsComment = #False
    logLines()\SrcLine = l5s()
    If thisLabel <> ""
      If pendingLabels <> ""
        pendingLabels + ";" + thisLabel
      Else
        pendingLabels = thisLabel
      EndIf
    EndIf
    If pendingLabels <> ""
      logLines()\LabelNames = pendingLabels
      pendingLabels = ""
    EndIf
  Wend

  If pendingLabels <> ""
    Dig_Fail(0, "Label no final do arquivo sem linha de destino: " + pendingLabels)
    ProcedureReturn
  EndIf

  If Dig_InFunc <> ""
    Dig_Fail(0, "Funcao sem RET: " + Dig_InFunc)
    ProcedureReturn
  EndIf

  ; chamadas de proto-funcao .nome(args) - resolvidas antes de labels/EXIT
  ; (mesma ordem do original: funcoes antes de labels no Pass 2)
  ForEach logLines()
    If Not logLines()\IsComment
      logLines()\Text = Dig_FuncCalls_Piece(logLines()\Text, logLines()\SrcLine)
      If Dig_HasError : ProcedureReturn : EndIf
    EndIf
  Next

  ; scan de referencias de label / loop / exit no codigo de cada linha
  ForEach logLines()
    If Not logLines()\IsComment
      logLines()\Text = Dig_MapCodeSegments(logLines()\Text, logLines()\SrcLine, @Dig_ScanLabelRefs_Piece())
      If Dig_HasError : ProcedureReturn : EndIf
    EndIf
  Next

  If Dig_LoopStackTop <> loopTopAtEntry
    Dig_Fail(0, "Loop label nao fechado: " + Dig_LoopStack(Dig_LoopStackTop))
    ProcedureReturn
  EndIf

  ; INCLUDE: expande cada linha "INCLUDE "arquivo"" recursivamente,
  ; substituindo-a pelas linhas logicas ja processadas do arquivo incluido
  ; (que ja passou pelo seu proprio FuncCalls_Piece/ScanLabelRefs_Piece dentro
  ; da chamada recursiva abaixo - nao devem ser reprocessadas aqui de novo).
  Protected NewList splicedLines.DigLogLine()
  ForEach logLines()
    If logLines()\IsComment Or UCase(StringField(Trim(logLines()\Text), 1, " ")) <> "INCLUDE"
      AddElement(splicedLines())
      splicedLines()\Text = logLines()\Text
      splicedLines()\LabelNames = logLines()\LabelNames
      splicedLines()\SrcLine = logLines()\SrcLine
      splicedLines()\IsComment = logLines()\IsComment
      Continue
    EndIf

    Protected incArg.s = Trim(Mid(Trim(logLines()\Text), 8))
    If Len(incArg) < 2 Or Left(incArg, 1) <> Chr(34) Or Right(incArg, 1) <> Chr(34)
      Dig_Fail(logLines()\SrcLine, "INCLUDE mal formado (esperado INCLUDE " + Chr(34) + "arquivo" + Chr(34) + "): " + logLines()\Text)
      ProcedureReturn
    EndIf
    Protected incPath.s = Dig_ResolveIncludePath(Mid(incArg, 2, Len(incArg) - 2), OwnBasePath)
    Protected incKey.s = UCase(incPath)

    If ListSize(Dig_IncludeStack()) >= #Dig_MaxIncludeDepth
      Dig_Fail(logLines()\SrcLine, "INCLUDE excede profundidade maxima (" + Str(#Dig_MaxIncludeDepth) + "): " + incPath)
      ProcedureReturn
    EndIf
    ForEach Dig_IncludeStack()
      If Dig_IncludeStack() = incKey
        Dig_Fail(logLines()\SrcLine, "INCLUDE circular detectado: " + incPath)
        ProcedureReturn
      EndIf
    Next

    Protected incContent.s = Dig_ReadTextFile(incPath, logLines()\SrcLine)
    If Dig_HasError : ProcedureReturn : EndIf

    Dig_IncludeCounter + 1
    Protected childPrefix.s = Dig_CurrentPrefix + "__inc" + Str(Dig_IncludeCounter) + "$"
    Protected childBasePath.s = GetPathPart(incPath)

    AddElement(Dig_IncludeStack()) : Dig_IncludeStack() = incKey
    Protected NewList childLogLines.DigLogLine()
    Dig_ProcessSource(incContent, childPrefix, childBasePath, #False, childLogLines())
    DeleteElement(Dig_IncludeStack())
    Dig_CurrentPrefix = Prefix ; a chamada recursiva ja restaura o dela, isto e so defensivo
    If Dig_HasError : ProcedureReturn : EndIf

    Protected pendingFromInclude.s = logLines()\LabelNames
    Protected firstChild.b = #True
    ForEach childLogLines()
      AddElement(splicedLines())
      splicedLines()\Text = childLogLines()\Text
      splicedLines()\SrcLine = childLogLines()\SrcLine
      splicedLines()\IsComment = childLogLines()\IsComment
      splicedLines()\LabelNames = childLogLines()\LabelNames
      If firstChild And pendingFromInclude <> ""
        If splicedLines()\LabelNames <> ""
          splicedLines()\LabelNames = pendingFromInclude + ";" + splicedLines()\LabelNames
        Else
          splicedLines()\LabelNames = pendingFromInclude
        EndIf
      EndIf
      firstChild = #False
    Next

    If firstChild And pendingFromInclude <> ""
      ; arquivo incluido nao gerou nenhuma linha - o label pendente ficaria sem alvo
      Dig_Fail(logLines()\SrcLine, "Label aponta para INCLUDE vazio: " + pendingFromInclude)
      ProcedureReturn
    EndIf
  Next

  CopyList(splicedLines(), OutLogLines())

  ; restaura o estado isolado deste arquivo antes de devolver ao chamador
  CopyMap(savedDefines(), Dig_Defines())
  ; mesmo contorno do CopyMap(Dig_Keeps()...) no topo desta Procedure - ver
  ; comentario la (mapa .b() de origem vazia trava o CopyMap no PB 6.40 instalado)
  If MapSize(savedKeeps())
    CopyMap(savedKeeps(), Dig_Keeps())
  Else
    ClearMap(Dig_Keeps())
  EndIf
  Dig_KeepAll = savedKeepAll
  Dig_KeepNone = savedKeepNone
  CopyMap(savedFuncParams(), Dig_FuncParams())
  CopyMap(savedFuncDefaults(), Dig_FuncDefaults())
  CopyMap(savedFuncRets(), Dig_FuncRets())
  Dig_InFunc = savedInFunc
  Dig_CurrentPrefix = savedPrefix
EndProcedure

;- ------------------------------------------------------------
;- Funcao principal (orquestra o merge final da arvore inteira)
;- ------------------------------------------------------------

Procedure.s Dig_Preprocess(SourceText.s, BasePath.s = "", IsMsxBas2Rom.b = #False)
  Dig_HasError = #False
  Dig_ErrorMsg = ""
  Dig_ErrorLine = 0
  Dig_ModeIsMsxBas2Rom = IsMsxBas2Rom

  Dig_InitReservedKw()

  ClearMap(Dig_Declares())
  ClearMap(Dig_HardShort())
  ClearMap(Dig_HardLong())
  Dig_VarIndex = 675
  Dig_LoopStackTop = -1
  Dig_CurrentPrefix = ""
  Dig_IncludeCounter = 0
  ClearList(Dig_IncludeStack())
  Dig_BasePath = BasePath
  Dig_ExportFileOverride = ""
  Dig_RemtagHelpRequested = #False

  Protected NewList logLines.DigLogLine()
  Dig_ProcessSource(SourceText, "", Dig_BasePath, #True, logLines())
  If Dig_HasError : ProcedureReturn "" : EndIf

  ; TRUE/FALSE + operadores compostos - aplicado uma unica vez, sobre a
  ; arvore inteira ja mesclada (arquivo principal + todos os includes), igual
  ; ao pass_5 do original (so roda depois do merge completo dos includes)
  ForEach logLines()
    If Not logLines()\IsComment
      logLines()\Text = Dig_MapCodeSegments(logLines()\Text, logLines()\SrcLine, @Dig_BoolOps_Piece())
    EndIf
  Next

  ; variaveis longas -> curtas (Dig_Declares/HardShort/HardLong/VarIndex nunca
  ; sao tocados por Dig_ProcessSource - ja saem compartilhados entre arquivo
  ; principal e includes por natureza, sem nenhum tratamento extra aqui)
  Protected NewList varLines.s() : Protected NewList varComment.b() : Protected NewList varSrc.i()
  ForEach logLines()
    AddElement(varLines()) : varLines() = logLines()\Text
    AddElement(varComment()) : varComment() = logLines()\IsComment
    AddElement(varSrc()) : varSrc() = logLines()\SrcLine
  Next
  Dig_ProcessVariables(varLines(), varComment(), varSrc())
  If Dig_HasError : ProcedureReturn "" : EndIf

  ResetList(logLines()) : ResetList(varLines())
  While NextElement(logLines())
    NextElement(varLines())
    logLines()\Text = varLines()
  Wend

  ; remove linhas de conteudo vazio (podem sobrar de defines que expandiram para nada)
  Protected NewList finalLines.DigLogLine()
  Protected carryLabels.s = ""
  ForEach logLines()
    If Not logLines()\IsComment And Trim(logLines()\Text) = "" And logLines()\LabelNames = ""
      Continue
    EndIf
    AddElement(finalLines())
    finalLines()\Text = logLines()\Text
    finalLines()\IsComment = logLines()\IsComment
    finalLines()\SrcLine = logLines()\SrcLine
    finalLines()\LabelNames = logLines()\LabelNames
    If Dig_ModeIsMsxBas2Rom And Not logLines()\IsComment And Dig_IsResourceDirectiveLine(logLines()\Text)
      finalLines()\IsResourceDirective = #True
    EndIf
  Next

  If ListSize(finalLines()) = 0
    Dig_Fail(0, "Programa vazio.")
    ProcedureReturn ""
  EndIf

  ; numeracao de linha + registro de labels
  ClearMap(Dig_LabelLine())
  Protected lineNum.i = Dig_LineStart
  Protected headerLineNum.i = 0
  If Dig_RemHeader
    headerLineNum = lineNum
    lineNum + Dig_LineStep
  EndIf

  ForEach finalLines()
    ; diretiva de recurso (FILE/TEXT) nao recebe numero nem consome um passo
    ; de numeracao - a linha de codigo seguinte fica com o numero que teria
    ; se a diretiva nao existisse (ver Dig_IsResourceDirectiveLine acima)
    If finalLines()\IsResourceDirective
      Continue
    EndIf
    finalLines()\LineNumber = lineNum
    If finalLines()\LabelNames <> ""
      Protected nLbl.i = CountString(finalLines()\LabelNames, ";") + 1, k.i
      For k = 1 To nLbl
        Protected lblName.s = StringField(finalLines()\LabelNames, k, ";")
        If FindMapElement(Dig_LabelLine(), lblName)
          Dig_Fail(finalLines()\SrcLine, "Label duplicado: " + lblName)
          ProcedureReturn ""
        EndIf
        Dig_LabelLine(lblName) = lineNum
      Next
    EndIf
    lineNum + Dig_LineStep
  Next

  ; pre-scan: localiza cada marcador de "volta de loop" (B) para saber em que
  ; linha o "}" de fechamento acabou (o alvo do EXIT e a linha seguinte a essa)
  ClearMap(Dig_LoopExit())
  ForEach finalLines()
    Protected bScanPos.i = 1
    Repeat
      Protected bPos.i = FindString(finalLines()\Text, #Dig_Mark + "B", bScanPos)
      If bPos = 0 : Break : EndIf
      Protected bClose.i = FindString(finalLines()\Text, #Dig_Mark, bPos + 2)
      If bClose = 0 : Break : EndIf
      Protected bName.s = Mid(finalLines()\Text, bPos + 2, bClose - (bPos + 2))
      Dig_LoopExit(bName) = finalLines()\LineNumber + Dig_LineStep
      bScanPos = bClose + 1
    ForEver
  Next

  ; resolve marcadores Chr(2)...Chr(2)
  Protected out.s = ""
  If Dig_RemHeader
    out + Str(headerLineNum) + " ' Converted with Basic Dignified (native PureBasic port)" + Chr(13) + Chr(10)
  EndIf

  ForEach finalLines()
    Protected lineText.s = finalLines()\Text

    Protected resolved.s = "", pos.i = 1
    While pos <= Len(lineText)
      If Mid(lineText, pos, 1) = #Dig_Mark
        Protected closePos.i = FindString(lineText, #Dig_Mark, pos + 1)
        If closePos = 0
          Dig_Fail(finalLines()\SrcLine, "Marcador interno nao fechado.")
          ProcedureReturn ""
        EndIf
        Protected code.s = Mid(lineText, pos + 1, closePos - pos - 1)
        Protected kind.s = Left(code, 1)
        Protected refName.s = Mid(code, 2)
        Select kind
          Case "S"
            resolved + Str(finalLines()\LineNumber)
          Case "J", "B"
            If Not FindMapElement(Dig_LabelLine(), refName)
              Dig_Fail(finalLines()\SrcLine, "Label nao existe: " + refName)
              ProcedureReturn ""
            EndIf
            resolved + Str(Dig_LabelLine())
          Case "G"
            ; refName ja e o nome completo (prefixo de namespace + "__func_" +
            ; nome), construido por Dig_FuncLabelName() nos dois lados
            ; (registro do label e emissao do marcador GOSUB) - ver Dig_ProcessSource.
            If Not FindMapElement(Dig_LabelLine(), refName)
              Dig_Fail(finalLines()\SrcLine, "Funcao nao existe: " + refName)
              ProcedureReturn ""
            EndIf
            resolved + Str(Dig_LabelLine())
          Case "X"
            If Not FindMapElement(Dig_LoopExit(), refName)
              Dig_Fail(finalLines()\SrcLine, "Loop exit sem fechamento: " + refName)
              ProcedureReturn ""
            EndIf
            resolved + Str(Dig_LoopExit())
        EndSelect
        pos = closePos + 1
        Continue
      EndIf
      resolved + Mid(lineText, pos, 1)
      pos + 1
    Wend

    ; colapsa ':' duplicados
    While FindString(resolved, "::")
      resolved = ReplaceString(resolved, "::", ":")
    Wend
    resolved = Trim(resolved)

    ; ajustes finais equivalentes ao pass_5/generate() do badig_msx.py original -
    ; operam sobre a linha classica ja resolvida (labels/variaveis/loops prontos)
    resolved = Dig_MapCodeSegments(resolved, finalLines()\SrcLine, @Dig_ConvertPrint_Piece())
    resolved = Dig_MapCodeSegments(resolved, finalLines()\SrcLine, @Dig_StripThenGoto_Piece())
    resolved = Dig_TransChar(resolved)
    resolved = Dig_MapCodeSegments(resolved, finalLines()\SrcLine, @Dig_CapitalizeAll_Piece())
    resolved = Dig_MapCodeSegments(resolved, finalLines()\SrcLine, @Dig_StripSpaces_Piece())

    Protected finalLine.s
    If finalLines()\IsResourceDirective
      finalLine = resolved ; FILE/TEXT: sem numero de linha, ver Dig_IsResourceDirectiveLine
    Else
      finalLine = Str(finalLines()\LineNumber) + " " + resolved
    EndIf
    ; Limite real do MSX-BASIC (linha tokenizada, incluindo numero de linha):
    ; 255 caracteres - pedido explicito do usuario 2026-08-20 pra confirmar
    ; que isso realmente avisa (ja existia, so a mensagem nao informava o
    ; tamanho de verdade nem deixava claro qual e o limite exato).
    If Len(finalLine) > 255
      Dig_Fail(finalLines()\SrcLine, "Linha gerada tem " + Str(Len(finalLine)) +
               " caracteres - o maximo que o MSX-BASIC suporta e 255.")
      ProcedureReturn ""
    EndIf

    out + finalLine + Chr(13) + Chr(10)
  Next

  ProcedureReturn out
EndProcedure
