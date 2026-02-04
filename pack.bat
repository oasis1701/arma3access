@echo off
setlocal enabledelayedexpansion

REM ============================================
REM Blind Assist PBO Packer
REM Reads paths from local.env
REM ============================================

REM Load local.env
if not exist "local.env" (
    echo ERROR: local.env not found!
    echo Copy local.env.example to local.env and set your paths.
    pause
    exit /b 1
)

REM Parse local.env (handles KEY=VALUE format)
for /f "usebackq tokens=1,* delims==" %%a in ("local.env") do (
    REM Skip comments and empty lines
    set "line=%%a"
    if not "!line:~0,1!"=="#" (
        if not "%%a"=="" (
            set "%%a=%%b"
        )
    )
)

REM Derive Arma 3 Tools path from ARMA3_DIR (same parent folder)
for %%i in ("%ARMA3_DIR%") do set "STEAM_COMMON=%%~dpi"
set "ARMA3_TOOLS=%STEAM_COMMON%Arma 3 Tools"

REM Verify paths exist
if not exist "%ARMA3_DIR%" (
    echo ERROR: ARMA3_DIR not found: %ARMA3_DIR%
    pause
    exit /b 1
)

if not exist "%ARMA3_TOOLS%\CfgConvert\CfgConvert.exe" (
    echo ERROR: Arma 3 Tools not found at: %ARMA3_TOOLS%
    echo Please install Arma 3 Tools from Steam.
    pause
    exit /b 1
)

echo.
echo === Blind Assist PBO Packer ===
echo ARMA3_DIR: %ARMA3_DIR%
echo ARMA3_TOOLS: %ARMA3_TOOLS%
echo Destination: %ARMA3_DIR%\Addons (always loaded)
echo.

REM Step 1: Convert config.cpp to text (resolves #include directives)
echo [1/4] Converting config.cpp to text...
cd /d "%~dp0blind_assist"
del /q config.txt 2>nul
del /q config.bin 2>nul
"%ARMA3_TOOLS%\CfgConvert\CfgConvert.exe" -txt -dst config.txt config.cpp
if errorlevel 1 (
    echo ERROR: CfgConvert text conversion failed!
    pause
    exit /b 1
)

REM Step 2: Convert text to binary
echo [2/4] Converting to binary config...
"%ARMA3_TOOLS%\CfgConvert\CfgConvert.exe" -bin -dst config.bin config.txt
if errorlevel 1 (
    echo ERROR: CfgConvert binary conversion failed!
    pause
    exit /b 1
)

REM Step 3: Delete old PBO
echo [3/4] Removing old PBO...
del /q "%ARMA3_DIR%\Addons\blind_assist.pbo" 2>nul

REM Step 4: Pack with FileBank
echo [4/4] Packing PBO...
cd /d "%~dp0"
"%ARMA3_TOOLS%\FileBank\FileBank.exe" -property prefix=blind_assist -dst "%ARMA3_DIR%\Addons" blind_assist
if errorlevel 1 (
    echo ERROR: FileBank packing failed!
    pause
    exit /b 1
)

echo.
echo === SUCCESS ===
echo PBO created: %ARMA3_DIR%\Addons\blind_assist.pbo
echo.

REM Show file size
for %%A in ("%ARMA3_DIR%\Addons\blind_assist.pbo") do echo Size: %%~zA bytes

echo.
pause
