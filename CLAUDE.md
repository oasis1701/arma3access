# Arma 3 Blind Assist Project

## Project Goal
Make Arma 3 accessible to blind players through NVDA screen reader integration.
Enable blind players to command squads, explore maps via audio, and play the game.

## Progress Tracking
**See `progress.md` for current status and next steps.**
Update `progress.md` briefly when completing milestones or changing direction.

## Key Paths

### Setup
Copy `local.env.example` to `local.env` and set your machine-specific paths.
`local.env` is gitignored and never committed. Read it at the start of a session
to get `ARMA3_DIR`, `ARMA3_MISSION_DIR`, and `ARMA3_LOG_DIR`.

### Project Directory (Source - edit files here)
This repo root. All source files are version controlled here.

**IMPORTANT:** Always edit files in the repo, then deploy to the game folder.

### NVDA Controller Client SDK
`nvda controllerClient/x64/`
- nvdaController.h (header)
- nvdaControllerClient.lib (link library)
- nvdaControllerClient.dll (runtime)

## Architecture

### NVDA Bridge
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

### Observer Mode Architecture (IMPORTANT)

The core concept: Blind players enjoy Arma by letting AI control their soldier while they listen and give orders.

**The Problem:**
- Arma 3 requires a `player` object - the game always needs a unit the human "controls"
- We want AI to control the soldier so blind players can command it
- If AI controls the soldier, what does `player` point to?

**The Solution - Ghost Unit:**
```
Before Observer Mode:
  player = Your Soldier (you control it directly)

After Observer Mode:
  player = Ghost Unit (invisible, does nothing)
  Your Soldier = AI-controlled (BA_originalUnit - receives your orders)
  Camera = Attached to observed unit (BA_observedUnit - can be any unit)
```

We use `selectPlayer ghostUnit` to transfer control. The original soldier becomes AI-controlled.

**Why Ghost Must Follow Your Soldier:**

Many mission scripts check `player` for position, side, variables, and triggers:
```sqf
player distance objective < 50    // Position check
side player == west               // Side check
player getVariable "money"        // Variable access
player in thisList                // Trigger area
```

If ghost was at `[0,0,0]` with wrong side, **missions would break**. So we:
1. Create ghost as hidden soldier (same side class: B_/O_/I_Soldier)
2. Position ghost at BA_originalUnit location (sync every 0.5s)
3. Sync variables bidirectionally between ghost and original unit

**Key Global Variables:**
| Variable | Purpose |
|----------|---------|
| `BA_originalUnit` | Your soldier (AI-controlled, receives orders) |
| `BA_ghostUnit` | The invisible `player` object |
| `BA_observedUnit` | Unit camera is attached to (can differ from original) |
| `BA_ghostGroup` | Group containing ghost (for correct side) |

**Critical Implementation Notes:**
- Ghost uses `hideObjectGlobal true` + `enableSimulation false` + `disableAI "ALL"`
- Do NOT use `setCaptive true` - it changes `side player` to civilian!
- Ghost group created with `createGroup [side, true]` for correct side
- Switching observed unit (Ctrl+Tab) does NOT move the ghost - ghost always follows BA_originalUnit

### Vehicle Commands Pattern (IMPORTANT)

When issuing orders to vehicles (helicopters, jets, tanks, etc.), the player may command them in two ways:
1. **G key** - Select a different group to command (sets `BA_selectedOrderGroup`)
2. **Ctrl+Tab** - Switch to observe a unit in that vehicle (changes `BA_observedUnit`)

**The Problem:** If you get the vehicle from `BA_observedUnit`, it breaks when using G key (player is on foot, not in the vehicle).

**The Solution:** Always get the vehicle from the **group leader**, not the observed unit:
```sqf
// WRONG - breaks with G key selection
private _vehicle = vehicle BA_observedUnit;

// CORRECT - works for both G key AND Ctrl+Tab
private _groupLeader = leader _group;  // _group already handles BA_selectedOrderGroup
private _vehicle = vehicle _groupLeader;
```

**Helicopter-specific notes:**
- Use `AWARE` behavior (not `COMBAT`) to respect `flyInHeight` altitude commands
- Use `RED` combat mode for weapons free while maintaining steady flight
- After landing, `BA_flyHeight` is set to 0; flight commands check `if (_flyHeight < 30)` and default to 150m
- Landing uses waypoint statements: `_wp setWaypointStatements ["true", "(vehicle this) land 'LAND'"]`

## Build Instructions

### For Claude Sessions (Recommended)

Build the bridge DLL:
```bash
powershell -Command "& { cmd /c '\"C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat\" x64 && cd /d \"%CD%\bridge\" && cl /LD /EHsc /O2 /Fe:nvda_arma3_bridge_x64.dll nvda_arma3_bridge.cpp nvdaControllerClient.lib' }"
```

Deploy DLLs to Arma 3 (paths from `local.env`):
```bash
cp "bridge/nvda_arma3_bridge_x64.dll" "$ARMA3_DIR/" && cp "nvda controllerClient/x64/nvdaControllerClient.dll" "$ARMA3_DIR/"
```

Deploy SQF scripts to test mission:
```bash
cp "blind_assist/"*.sqf "$ARMA3_MISSION_DIR/blind_assist/"
```

Verify DLL deployment:
```bash
ls -la "$ARMA3_DIR/"*nvda*
```

### For Manual Use (Developer Command Prompt)

Open "Developer Command Prompt for VS 2022" and run:
```cmd
cd bridge
build.bat
deploy.bat
```

## Adding New Features (IMPORTANT)

When creating new SQF functions, you must update multiple files:

### 1. Function Registration (BOTH files!)
New functions must be added to TWO config files:

| File | Purpose |
|------|---------|
| `CfgFunctions.hpp` | Dev mission (description.ext includes this) |
| `CfgFunctions_Addon.hpp` | PBO build (config.cpp includes this) |

**Example:** Adding `fn_myNewFeature.sqf`:
```cpp
// Add to BOTH files in the appropriate class:
class myNewFeature {};
```

### 2. Initialization (fn_autoInit.sqf)
If your feature needs initialization, add the call to TWO places in `fn_autoInit.sqf`:

1. **Main init block** (around line 17-27) - runs on fresh mission start
2. **"Loaded" event handler** (around line 30-42) - runs when loading saved games

```sqf
// Add to BOTH places:
[] call BA_fnc_initMyNewFeature;
```

**Why both?** `postInit` only runs on fresh mission starts. The "Loaded" handler ensures
Blind Assist re-initializes when players load a saved game.

### 3. Deployment Checklist
After making changes:
1. Deploy to dev mission: `cp blind_assist/*.sqf "$ARMA3_MISSION_DIR/blind_assist/"`
2. Also deploy hpp: `cp blind_assist/CfgFunctions.hpp "$ARMA3_MISSION_DIR/blind_assist/"`
3. Test in dev mission
4. Rebuild PBO: `pack_ci.bat` (non-interactive version for Claude)
5. Test with PBO (both fresh start AND loading a save)

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
./                                  (repo root - all edits here, git controlled)
├── CLAUDE.md                       (this file - project context)
├── local.env.example               (copy to local.env, set your paths)
├── progress.md                     (current status - update this!)
├── bridge/
│   ├── nvda_arma3_bridge.cpp       (main source)
│   ├── build.bat                   (compile script)
│   └── deploy.bat                  (copy to Arma 3)
├── blind_assist/                   (SQF scripts - deploy to test mission)
│   ├── fn_speak.sqf                (speak wrapper)
│   ├── fn_cancel.sqf               (cancel speech)
│   ├── fn_*.sqf                    (all function scripts)
│   └── CfgFunctions.hpp            (function definitions)
└── test_mission/
    └── init.sqf                    (test the bridge)

$ARMA3_MISSION_DIR/                     (DEPLOY TARGET - don't edit here)
├── blind_assist/                   (copy of repo blind_assist/)
├── description.ext                 (mission config)
└── init.sqf                        (mission init)
```

**Workflow:** Edit in repo → Deploy to test mission → Test in Arma 3