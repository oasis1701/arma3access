@echo off
REM Build script for NVDA-Arma 3 Bridge DLL
REM Run this from "Developer Command Prompt for VS 2022"

echo Building NVDA-Arma 3 Bridge DLL...

REM Check if we're in a VS Developer Command Prompt
where cl >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ERROR: cl.exe not found!
    echo Please run this from "Developer Command Prompt for VS 2022"
    echo.
    echo You can find it in Start Menu under:
    echo   Visual Studio 2022 ^> Developer Command Prompt for VS 2022
    exit /b 1
)

REM Copy NVDA SDK files if not present
if not exist nvdaController.h (
    echo Copying NVDA SDK header...
    copy "..\nvda controllerClient\x64\nvdaController.h" . >nul
)

if not exist nvdaControllerClient.lib (
    echo Copying NVDA SDK import library...
    copy "..\nvda controllerClient\x64\nvdaControllerClient.lib" . >nul
)

REM Compile the DLL
echo Compiling...
cl /LD /EHsc /O2 /Fe:nvda_arma3_bridge_x64.dll nvda_arma3_bridge.cpp nvdaControllerClient.lib /link /DEF:

if %ERRORLEVEL% neq 0 (
    echo.
    echo BUILD FAILED!
    exit /b 1
)

echo.
echo BUILD SUCCESSFUL!
echo.
echo Output: nvda_arma3_bridge_x64.dll
echo.
echo Next steps:
echo   1. Run deploy.bat to copy files to Arma 3
echo   2. Or manually copy:
echo      - nvda_arma3_bridge_x64.dll to Arma 3 folder
echo      - nvdaControllerClient.dll to Arma 3 folder
