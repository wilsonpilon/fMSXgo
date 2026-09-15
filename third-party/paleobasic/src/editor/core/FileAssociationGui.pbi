;
; ------------------------------------------------------------
;  "Configurar -> Associacoes de arquivo...": permite marcar que arquivos
;  .msxproject abrem direto no PaleoBasic quando o usuario da 2 cliques
;  neles no Windows Explorer, em vez de precisar abrir o editor primeiro e
;  usar "Arquivo -> Abrir projeto...". So Windows (associacao de arquivo e
;  puramente registro do Windows) - guardado com CompilerIf onde importa.
;
;  So .msxproject por enquanto (unico tipo de arquivo "de projeto" que faz
;  sentido abrir direto assim); se um dia fizer sentido associar outra
;  extensao, o padrao aqui (FileAssoc_Apply/FileAssoc_Remove/FileAssoc_IsOurs
;  parametrizados por extensao+ProgId) ja da pra reusar.
;
;  Grava em HKEY_CURRENT_USER\Software\Classes (nao HKEY_CLASSES_ROOT, que
;  precisaria de admin) - e o jeito padrao de registrar associacao so pro
;  usuario atual, sem elevar privilegios. O lado "abrir o projeto de
;  verdade quando passado na linha de comando" fica no inicio de
;  BadigEditor.pb (Programa principal), nao aqui - este arquivo so cuida do
;  registro do Windows.
;
;  RegCreateKeyExW/RegSetValueExW/RegOpenKeyExW/RegQueryValueExW/
;  RegCloseKey/RegDeleteTreeW (Advapi32.lib) e SHChangeNotify (Shell32.lib)
;  nao vem pre-declarados por este pbcompiler (confirmado tentando usa-los
;  direto e tambem tentando CreateRegistryKey()/etc. da lib Registry do PB -
;  nenhuma das duas existe nesta instalacao) - importados manualmente aqui,
;  mesmo idioma ja usado em App_GetProcAddressOrdinal() (BadigEditor.pb,
;  perto do dark mode) pra decorar o nome em builds x86 (stdcall decorado,
;  "_Nome@bytes" = numero de argumentos x 4, todos ponteiro/DWORD nesta
;  lista) vs. x64 (sem decoracao). Confirmado compilando e testando de
;  verdade (RegCreateKeyExW+SetValueExW gravando uma chave de teste e
;  conferindo com Get-ItemProperty do PowerShell) nesta maquina, que e x64 -
;  o ramo x86 do CompilerSelect nao foi exercido de verdade, so calculado.
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  Import "Advapi32.lib"
    CompilerSelect #PB_Compiler_Processor
      CompilerCase #PB_Processor_x86
        FileAssoc_RegCreateKeyExW(hKey.i, SubKey.p-unicode, Reserved.l, Class.i, Options.l, Sam.l, SecAttr.i, *Result.Integer, Disposition.i) As "_RegCreateKeyExW@36"
        FileAssoc_RegSetValueExW(hKey.i, ValueName.p-unicode, Reserved.l, ValType.l, *Data, DataLen.l) As "_RegSetValueExW@24"
        FileAssoc_RegOpenKeyExW(hKey.i, SubKey.p-unicode, Options.l, Sam.l, *Result.Integer) As "_RegOpenKeyExW@20"
        FileAssoc_RegQueryValueExW(hKey.i, ValueName.p-unicode, Reserved.i, *ValType.Long, *Data, *DataLen.Long) As "_RegQueryValueExW@24"
        FileAssoc_RegCloseKey(hKey.i) As "_RegCloseKey@4"
        FileAssoc_RegDeleteTreeW(hKey.i, SubKey.p-unicode) As "_RegDeleteTreeW@8"
      CompilerDefault
        FileAssoc_RegCreateKeyExW(hKey.i, SubKey.p-unicode, Reserved.l, Class.i, Options.l, Sam.l, SecAttr.i, *Result.Integer, Disposition.i) As "RegCreateKeyExW"
        FileAssoc_RegSetValueExW(hKey.i, ValueName.p-unicode, Reserved.l, ValType.l, *Data, DataLen.l) As "RegSetValueExW"
        FileAssoc_RegOpenKeyExW(hKey.i, SubKey.p-unicode, Options.l, Sam.l, *Result.Integer) As "RegOpenKeyExW"
        FileAssoc_RegQueryValueExW(hKey.i, ValueName.p-unicode, Reserved.i, *ValType.Long, *Data, *DataLen.Long) As "RegQueryValueExW"
        FileAssoc_RegCloseKey(hKey.i) As "RegCloseKey"
        FileAssoc_RegDeleteTreeW(hKey.i, SubKey.p-unicode) As "RegDeleteTreeW"
    CompilerEndSelect
  EndImport

  Import "Shell32.lib"
    CompilerSelect #PB_Compiler_Processor
      CompilerCase #PB_Processor_x86
        FileAssoc_SHChangeNotify(EventId.l, Flags.l, Item1.i, Item2.i) As "_SHChangeNotify@16"
      CompilerDefault
        FileAssoc_SHChangeNotify(EventId.l, Flags.l, Item1.i, Item2.i) As "SHChangeNotify"
    CompilerEndSelect
  EndImport

  #FileAssoc_SHCNE_ASSOCCHANGED = $08000000
  #FileAssoc_SHCNF_IDLIST       = $0000
CompilerEndIf

#FileAssoc_Extension = ".msxproject"
#FileAssoc_ProgId    = "PaleoBasic.Project"

; Caminho do .exe atual entre aspas, pronto pra entrar num valor de registro
; ("comando" ou "DefaultIcon") - ProgramFilename() ja devolve caminho absoluto.
Procedure.s FileAssoc_ExeQuoted()
  ProcedureReturn Chr(34) + ProgramFilename() + Chr(34)
EndProcedure

CompilerIf #PB_Compiler_OS = #PB_OS_Windows

  ; Le o valor (default) de uma chave HKEY_CURRENT_USER\<SubKey> - "" se a
  ; chave/valor nao existir. Usado so pra status na tela (nao precisa de
  ; tratamento elaborado de buffer: 2048 caracteres cobre qualquer comando
  ; real com folga).
  Procedure.s FileAssoc_ReadDefaultValue(SubKey.s)
    Protected hKey.i, Result.s = ""
    Protected ValType.l, DataLen.l
    Protected *Buffer = AllocateMemory(2048)
    If Not *Buffer
      ProcedureReturn ""
    EndIf

    If FileAssoc_RegOpenKeyExW(#HKEY_CURRENT_USER, SubKey, 0, #KEY_READ, @hKey) = #ERROR_SUCCESS
      DataLen = 2048
      If FileAssoc_RegQueryValueExW(hKey, "", 0, @ValType, *Buffer, @DataLen) = #ERROR_SUCCESS And ValType = #REG_SZ
        Result = PeekS(*Buffer, -1, #PB_Unicode)
      EndIf
      FileAssoc_RegCloseKey(hKey)
    EndIf

    FreeMemory(*Buffer)
    ProcedureReturn Result
  EndProcedure

  Procedure.b FileAssoc_WriteDefaultValue(SubKey.s, Value.s)
    Protected hKey.i, Disposition.l
    If FileAssoc_RegCreateKeyExW(#HKEY_CURRENT_USER, SubKey, 0, 0, #REG_OPTION_NON_VOLATILE, #KEY_WRITE, 0, @hKey, @Disposition) <> #ERROR_SUCCESS
      ProcedureReturn #False
    EndIf
    FileAssoc_RegSetValueExW(hKey, "", 0, #REG_SZ, @Value, (Len(Value) + 1) * SizeOf(Character))
    FileAssoc_RegCloseKey(hKey)
    ProcedureReturn #True
  EndProcedure

  ; #True se .msxproject ja aponta pro ProgId desta instalacao E o comando
  ; registrado desse ProgId aponta pro .exe atual (mesma pasta/instalacao -
  ; permite detectar "associado, mas com um .exe que foi movido/renomeado"
  ; como um caso a parte, tratado na tela como "desatualizado").
  Procedure.b FileAssoc_IsOurs()
    If FileAssoc_ReadDefaultValue("Software\Classes\" + #FileAssoc_Extension) <> #FileAssoc_ProgId
      ProcedureReturn #False
    EndIf
    Protected Command.s = FileAssoc_ReadDefaultValue("Software\Classes\" + #FileAssoc_ProgId + "\shell\open\command")
    ProcedureReturn Bool(FindString(Command, FileAssoc_ExeQuoted()) = 1)
  EndProcedure

  ; #True se .msxproject aponta pro nosso ProgId, mas com um comando que NAO
  ; e o .exe atual (instalacao movida/renomeada desde que a associacao foi
  ; criada) - usado so pra mensagem de status ser mais precisa.
  Procedure.b FileAssoc_IsOursButStale()
    If FileAssoc_ReadDefaultValue("Software\Classes\" + #FileAssoc_Extension) <> #FileAssoc_ProgId
      ProcedureReturn #False
    EndIf
    ProcedureReturn Bool(Not FileAssoc_IsOurs())
  EndProcedure

  Procedure FileAssoc_Apply()
    FileAssoc_WriteDefaultValue("Software\Classes\" + #FileAssoc_Extension, #FileAssoc_ProgId)
    FileAssoc_WriteDefaultValue("Software\Classes\" + #FileAssoc_ProgId, "Projeto PaleoBasic (MSX)")
    FileAssoc_WriteDefaultValue("Software\Classes\" + #FileAssoc_ProgId + "\DefaultIcon", FileAssoc_ExeQuoted() + ",0")
    FileAssoc_WriteDefaultValue("Software\Classes\" + #FileAssoc_ProgId + "\shell\open\command",
                                FileAssoc_ExeQuoted() + " " + Chr(34) + "%1" + Chr(34))
    FileAssoc_SHChangeNotify(#FileAssoc_SHCNE_ASSOCCHANGED, #FileAssoc_SHCNF_IDLIST, 0, 0)
  EndProcedure

  ; So remove a associacao de ".msxproject" (e o ProgId inteiro) se ela
  ; ainda for nossa - nunca mexe numa associacao de outro programa, mesmo
  ; que o usuario desmarque a caixa achando que "desligou algo que nunca
  ; ligou" (ex.: reabriu a tela sem nunca ter marcado antes).
  Procedure FileAssoc_Remove()
    If FileAssoc_ReadDefaultValue("Software\Classes\" + #FileAssoc_Extension) = #FileAssoc_ProgId
      FileAssoc_RegDeleteTreeW(#HKEY_CURRENT_USER, "Software\Classes\" + #FileAssoc_Extension)
    EndIf
    FileAssoc_RegDeleteTreeW(#HKEY_CURRENT_USER, "Software\Classes\" + #FileAssoc_ProgId)
    FileAssoc_SHChangeNotify(#FileAssoc_SHCNE_ASSOCCHANGED, #FileAssoc_SHCNF_IDLIST, 0, 0)
  EndProcedure

CompilerEndIf

Procedure FileAssoc_UpdateStatus(G_Status.i, G_Checkbox.i)
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    If GetGadgetState(G_Checkbox) = 1
      If FileAssoc_IsOursButStale()
        SetGadgetText(G_Status, "Associado, mas apontando pra uma copia diferente do PaleoBasic.exe - desmarque e marque de novo pra atualizar.")
      Else
        SetGadgetText(G_Status, "Arquivos " + #FileAssoc_Extension + " abrem no PaleoBasic com 2 cliques.")
      EndIf
    Else
      SetGadgetText(G_Status, "Arquivos " + #FileAssoc_Extension + " abrem com o programa padrao do Windows.")
    EndIf
  CompilerElse
    SetGadgetText(G_Status, "Associacao de arquivo so esta disponivel no Windows.")
  CompilerEndIf
EndProcedure

Procedure FileAssoc_OpenWindow(ParentWindow)
  Protected WinW = 520, WinH = 220
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Configurar - Associacoes de arquivo",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  TextGadget(#PB_Any, 24, 20, WinW - 48, 40,
             "Escolha quais tipos de arquivo abrem direto no PaleoBasic ao dar 2 cliques neles no Windows Explorer.")

  Protected G_Checkbox = CheckBoxGadget(#PB_Any, 24, 72, WinW - 48, 22,
                                        "Projeto MSX (" + #FileAssoc_Extension + ")")
  Protected G_Status = TextGadget(#PB_Any, 24, 104, WinW - 48, 40, "")

  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    SetGadgetState(G_Checkbox, Bool(FileAssoc_IsOurs() Or FileAssoc_IsOursButStale()))
  CompilerElse
    DisableGadget(G_Checkbox, #True)
  CompilerEndIf
  FileAssoc_UpdateStatus(G_Status, G_Checkbox)

  Protected G_Close = ThemedButton(WinW - 24 - 110, WinH - 56, 110, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  Protected Event, Quit = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_Checkbox
            CompilerIf #PB_Compiler_OS = #PB_OS_Windows
              If GetGadgetState(G_Checkbox) = 1
                FileAssoc_Apply()
              Else
                FileAssoc_Remove()
              EndIf
            CompilerEndIf
            FileAssoc_UpdateStatus(G_Status, G_Checkbox)

          Case G_Close
            Quit = #True
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
