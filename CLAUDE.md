# Arma 3 Blind Assist Project

## Project Goal
Make Arma 3 accessible to blind players through NVDA screen reader integration.
Enable blind players to command squads, explore maps via audio, and play the game.

## Progress Tracking
**See `progress.md` for current status and next steps.**
Update `progress.md` briefly when completing milestones or changing direction.

## Key Paths

### Project Directory
D:\arma3 access\

### Arma 3 Installation
F:\Steam\steamapps\common\Arma 3\

### Test Mission
F:\Steam\steamapps\common\Arma 3\Missions\AutoTest2.Stratis\

### Arma 3 Log Files
C:\Users\rhadi\AppData\Local\Arma 3\

### NVDA Controller Client SDK
D:\arma3 access\nvda controllerClient\x64\
- nvdaController.h (header)
- nvdaControllerClient.lib (link library)
- nvdaControllerClient.dll (runtime)

## Architecture

```
Arma 3 SQF Scripts
    | (callExtension)
    v
nvda_arma3_bridge_x64.dll (we create)
    |
    v
nvdaControllerClient.dll (NVDA SDK)
    |
    v
NVDA Screen Reader
```

## Build Instructions

### For Claude Sessions (Recommended)

Build the bridge DLL:
```bash
powershell -Command "& { cmd /c '\"C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat\" x64 && cd /d \"D:\arma3 access\bridge\" && cl /LD /EHsc /O2 /Fe:nvda_arma3_bridge_x64.dll nvda_arma3_bridge.cpp nvdaControllerClient.lib' }"
```

Deploy to Arma 3:
```bash
cp "D:/arma3 access/bridge/nvda_arma3_bridge_x64.dll" "F:/Steam/steamapps/common/Arma 3/" && cp "D:/arma3 access/nvda controllerClient/x64/nvdaControllerClient.dll" "F:/Steam/steamapps/common/Arma 3/"
```

Verify deployment:
```bash
ls -la "F:/Steam/steamapps/common/Arma 3/"*nvda*
```

### For Manual Use (Developer Command Prompt)

Open "Developer Command Prompt for VS 2022" and run:
```cmd
cd "D:\arma3 access\bridge"
build.bat
deploy.bat
```

## Test Command (in Arma 3 debug console)
```sqf
"nvda_arma3_bridge" callExtension "speak:Hello world"
```

## Bridge DLL Commands

| Command | Description | Example |
|---------|-------------|---------|
| `test` | Check if NVDA is running | `"nvda_arma3_bridge" callExtension "test"` |
| `speak:text` | Speak text via NVDA | `"nvda_arma3_bridge" callExtension "speak:Hello"` |
| `cancel` | Cancel current speech | `"nvda_arma3_bridge" callExtension "cancel"` |
| `braille:text` | Send to braille display | `"nvda_arma3_bridge" callExtension "braille:Hello"` |

## Important Notes
- DLL name must end with `_x64` for 64-bit Arma 3
- nvdaControllerClient.dll must be in Arma 3 directory alongside bridge DLL
- enableDebugConsole=1 is set in test mission's description.ext
- NVDA must be running for speech to work

## Project Structure

```
D:\arma3 access\
├── CLAUDE.md                       (this file - project context)
├── progress.md                     (current status - update this!)
├── bridge/
│   ├── nvda_arma3_bridge.cpp       (main source)
│   ├── build.bat                   (compile script)
│   └── deploy.bat                  (copy to Arma 3)
├── addon/
│   ├── fn_speak.sqf                (speak wrapper)
│   ├── fn_cancel.sqf               (cancel speech)
│   ├── fn_test.sqf                 (test NVDA connection)
│   └── CfgFunctions.hpp            (function definitions)
└── test_mission/
    └── init.sqf                    (test the bridge)
```