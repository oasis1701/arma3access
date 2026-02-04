@echo off
setlocal enabledelayedexpansion

REM ============================================
REM Blind Assist PBO Packer (CI/Non-interactive)
REM Same as pack.bat but without pause
REM ============================================

REM Load local.env
if not exist "local.env" (
    echo ERROR: local.env not found!
    exit /b 1
)

REM Parse local.env
for /f "usebackq tokens=1,* delims==" %%a in ("local.env") do (
    set "line=%%a"
    if not "!line:~0,1!"=="#" (
        if not "%%a"=="" (
            set "%%a=%%b"
        )
    )
)

REM Derive Arma 3 Tools path
for %%i in ("%ARMA3_DIR%") do set "STEAM_COMMON=%%~dpi"
set "ARMA3_TOOLS=%STEAM_COMMON%Arma 3 Tools"

REM Verify paths
if not exist "%ARMA3_DIR%" (
    echo ERROR: ARMA3_DIR not found: %ARMA3_DIR%
    exit /b 1
)

if not exist "%ARMA3_TOOLS%\CfgConvert\CfgConvert.exe" (
    echo ERROR: Arma 3 Tools not found at: %ARMA3_TOOLS%
    exit /b 1
)

echo [1/4] Converting config.cpp to text...
cd /d "%~dp0blind_assist"
del /q config.txt 2>nul
del /q config.bin 2>nul
"%ARMA3_TOOLS%\CfgConvert\CfgConvert.exe" -txt -dst config.txt config.cpp
if errorlevel 1 (
    echo ERROR: CfgConvert text conversion failed!
    exit /b 1
)

echo [2/4] Converting to binary config...
"%ARMA3_TOOLS%\CfgConvert\CfgConvert.exe" -bin -dst config.bin config.txt
if errorlevel 1 (
    echo ERROR: CfgConvert binary conversion failed!
    exit /b 1
)

echo [3/4] Removing old PBO...
del /q "%ARMA3_DIR%\Addons\blind_assist.pbo" 2>nul

echo [4/4] Packing PBO...
cd /d "%~dp0"
"%ARMA3_TOOLS%\FileBank\FileBank.exe" -property prefix=blind_assist -dst "%ARMA3_DIR%\Addons" blind_assist
if errorlevel 1 (
    echo ERROR: FileBank packing failed!
    exit /b 1
)

echo.
echo === SUCCESS ===
echo PBO: %ARMA3_DIR%\Addons\blind_assist.pbo
for %%A in ("%ARMA3_DIR%\Addons\blind_assist.pbo") do echo Size: %%~zA bytes

exit /b 0
