@echo off
REM Deploy NVDA-Arma 3 Bridge to Arma 3 directory

set ARMA3_DIR=F:\Steam\steamapps\common\Arma 3

echo Deploying NVDA-Arma 3 Bridge...

REM Check if Arma 3 directory exists
if not exist "%ARMA3_DIR%" (
    echo ERROR: Arma 3 directory not found at:
    echo   %ARMA3_DIR%
    echo.
    echo Please edit this script and set the correct path.
    exit /b 1
)

REM Check if bridge DLL exists
if not exist nvda_arma3_bridge_x64.dll (
    echo ERROR: nvda_arma3_bridge_x64.dll not found!
    echo Please run build.bat first.
    exit /b 1
)

REM Copy bridge DLL
echo Copying nvda_arma3_bridge_x64.dll...
copy /Y nvda_arma3_bridge_x64.dll "%ARMA3_DIR%\" >nul
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to copy bridge DLL
    exit /b 1
)

REM Copy NVDA runtime DLL
echo Copying nvdaControllerClient.dll...
copy /Y "..\nvda controllerClient\x64\nvdaControllerClient.dll" "%ARMA3_DIR%\" >nul
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to copy NVDA runtime DLL
    exit /b 1
)

echo.
echo DEPLOYMENT SUCCESSFUL!
echo.
echo Files copied to: %ARMA3_DIR%
echo   - nvda_arma3_bridge_x64.dll
echo   - nvdaControllerClient.dll
echo.
echo To test in Arma 3:
echo   1. Start NVDA
echo   2. Start Arma 3
echo   3. Load a mission (or use AutoTest2.Stratis)
echo   4. Open debug console (press Escape, then click Debug Console)
echo   5. Enter: "nvda_arma3_bridge" callExtension "speak:Hello world"
echo   6. Click "Local Exec"
echo   7. You should hear NVDA speak "Hello world"
