@echo off
REM Compilar teste.asm usando Nestor80
REM Script para compilar o programa Assembly de SCREEN 2 para MSX

REM Detectar Nestor80
if not exist "d:\msx\bin\N80.exe" (
    echo Erro: Nestor80 nao encontrado em nestor80\N80\bin\Release\net6.0\
    exit /b 1
)

echo Compilando teste.asm...
d:\msx\bin\N80.exe sample\teste.asm -o sample\teste.bin

if %ERRORLEVEL% equ 0 (
    echo.
    echo Sucesso! Arquivo gerado: sample\teste.bin
    echo.
    echo Use no MSX-BASIC:
    echo   10 CLEAR 200,^&HC000
    echo   20 BLOAD "TESTE.BIN",R
    echo   30 CALL ^&HC000
) else (
    echo Erro na compilacao!
    exit /b 1
)
