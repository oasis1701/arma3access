# Arma 3 Blind Assist - Progress

## Phase 1: NVDA Bridge - COMPLETE
Bridge DLL connects Arma 3 to NVDA screen reader via `callExtension`.
- Commands: `speak:text`, `cancel`, `braille:text`, `test`
- Test: `"nvda_arma3_bridge" callExtension "speak:Hello"`

## Phase 2: Observer Mode - COMPLETE
AI controls soldier while player observes through first-person camera.
- **Ctrl+O** - Toggle observer mode
- **Tab / Shift+Tab** - Cycle units in group
- **Ctrl+Tab / Ctrl+Shift+Tab** - Cycle between groups
- NVDA announces: Side, Group, Unit type on switch

### Game Compatibility (2026-01-30)
Ghost unit (hidden soldier) follows original soldier's position for mission compatibility:
- Distance checks work (`player distance objective < 50`)
- Variable access works (`player getVariable "money"`)
- Trigger areas work (`player in thisList`)
- Side checks work (`side player == west`)
- Variables sync bidirectionally between ghost and original unit
- Camera still follows observed unit (can be different via Ctrl+Tab)
- Ghost uses side-appropriate soldier class (B_/O_/I_/C_) with:
  - `hideObjectGlobal`, `allowDamage false`, `setCaptive`, `disableAI ALL`, `enableSimulation false`
- **Limitation**: `player in vehicle` checks fail (ghost not physically seated)

### Edge Case Monitoring (2026-01-30)
Automatic detection and announcements for soldier states the ghost doesn't experience:
- **Unconsciousness**: "Warning. Soldier is unconscious." (explosions, ACE3 medical)
- **Captivity**: "Warning. Soldier is captive. Cannot issue orders." (ACE3/Antistasi handcuffs)
- **Vehicle changes**: "Dismounted." or "Now in [vehicle]." (ejection, mount/dismount)
- **Inventory rescue**: Items given to `player` (ghost) are transferred to soldier on exit

## Phase 3: Virtual Cursor - COMPLETE
Explore map positions from observed unit.
- **Alt/Shift/Ctrl + Arrows** - Move cursor 10/100/1000m
- **I** - Detailed scan (terrain, objects, units, bearing)
- **Home/Backspace** - Snap cursor to unit
- Announces: Grid, terrain, altitude, nearby units/objects

## Phase 4: Order Menu - COMPLETE
Context-sensitive commands based on unit type. Press **O** to open.
- **Up/Down** - Navigate menu
- **Enter** - Issue order at cursor position
- **Escape** - Cancel

## Phase 4.5: Group Selection Menu - COMPLETE
Select which group receives orders WITHOUT moving camera or cursor.
- **G** - Open/close group selection menu
- **Up/Down** - Navigate groups
- **Enter** - Select group for orders
- **Escape** - Cancel
- Orders go to selected group until camera switches (then resets)
- Announces: Callsign, leader name, unit count (e.g., "Alpha 1-1, Sergeant Miller, 4 infantry")

## Phase 4 Status: Working Commands

### Infantry (Working)
| Command | Status |
|---------|--------|
| Move | WORKING |
| Sneak | WORKING |
| Assault | WORKING |
| Garrison | WORKING |
| Hold Fire | WORKING |
| Fire at Will | WORKING |

### Infantry (Disabled - Need Fixing)
| Command | Issue |
|---------|-------|
| Stop | SQF syntax error with doStop |
| Hold Position | SQF syntax error |
| Watch | SQF syntax error with doWatch forEach |
| Mount Nearest | forEach syntax issue |
| Dismount | forEach syntax issue |

### Helicopter Commands - COMPLETE (2026-01-31)
Full suite of 12 helicopter orders implemented:

| Command | Description |
|---------|-------------|
| Move | Fly to cursor at current altitude (combat mode) |
| Land | Land near cursor position |
| Stop | Cancel orders, hover in place |
| Altitude 50m | Nap of earth / terrain masking |
| Altitude 150m | Default tactical altitude |
| Altitude 300m | Safe transit altitude |
| Loiter 300m | Orbit cursor at 300m radius (counter-clockwise) |
| Loiter 600m | Orbit cursor at 600m radius |
| Loiter 900m | Orbit cursor at 900m radius |
| Hunt Enemies | Roam and destroy all enemies found |
| Attack Area | Attack targets near cursor, stay in area |
| Attack and Return | Attack cursor area briefly, return to start |

**Technical notes:**
- Altitude persists per-helicopter via `BA_flyHeight` variable (default 150m)
- All loiter uses CIRCLE_L for gunship operations (weapons face inward)
- Move and Loiter set combat mode - helicopter actively engages

### Other Unit Types (Jet, Vehicle, Artillery, Static)
Only **Move** available. All other commands removed due to broken syntax.
Add new commands one at a time, verifying against Arma 3 Wiki before adding.

### Unit Types & Commands

| Type | Commands |
|------|----------|
| **Infantry** | Move, Stop, Hold Position, Sneak, Assault, Garrison, Watch, Hold Fire, Fire at Will, Mount Nearest, Dismount |
| **Helicopter** | Move, Land, Stop, Altitude (50/150/300m), Loiter (300/600/900m), Hunt Enemies, Attack Area, Attack and Return |
| **Jet** | Fly Low/Medium/High, Loiter, Attack Run, Bomb Run, RTB |
| **Armed Vehicle** | Move, Offroad, Hold Position, Watch, Hold Fire, Fire at Will, Unload, Engine Off |
| **Transport** | Move, Offroad, Unload, Engine Off |
| **Artillery** | Fire HE, Fire Smoke, Move |
| **Static Weapon** | Watch, Hold Fire, Open Fire |

### Debug Mode
```sqf
BA_debugMode = true;  // Enable debug output to systemChat
```

---

## Phase 5: Landmarks Menu - COMPLETE
Discover nearby map locations from the virtual cursor position.
- **L** - Open/close landmarks menu
- **Left/Right** - Switch between categories (Geography, Tactical, NATO, Extras, Markers, Tasks)
- **Up/Down** - Navigate items within category
- **Enter** - Move cursor to selected landmark
- **Escape** - Cancel

### Categories
| Category | Location Types |
|----------|----------------|
| Geography | Capital, City, Village, Airport, Marine, Hill, Mountain, Rocky Area, Viewpoint |
| Tactical | Strategic Point, Strongpoint, Border Crossing, Safety Zone, Camp, Historical Site, Cultural Property |
| NATO | BLUFOR/OPFOR/Independent markers (Infantry, Armor, Air, Artillery, HQ, etc.) |
| Extras | Hill, Flag |
| Markers | Mission-placed map markers |
| Tasks | Mission objectives with destinations (new/active only, checks both player and original unit in observer mode) |

### Announcements
- Opening: "Landmarks. Geography category, 5 items. 1. Agia Marina, Village, 1520 meters northeast."
- Navigation: "2. Girna, Village, 2340 meters east."
- Category switch: "Tactical category, 3 items. 1. ..."
- Tasks: "1. Destroy the Radar, active, 450 meters northwest."
- Selection: "Cursor moved to Agia Marina."

---

## Phase 6: Object Scanner - COMPLETE
Comprehensive object scanner with category-based filtering and adjustable range.
Searches from virtual cursor position; auto-refreshes when cursor moves.

### Scanner Controls
| Key | Action |
|-----|--------|
| **U** | Cycle range: 10 → 50 → 100 → 500 → 1000 meters |
| **Ctrl+PageUp** | Previous category |
| **Ctrl+PageDown** | Next category |
| **PageUp** | Previous object (cursor stays) |
| **PageDown** | Next object (cursor stays) |
| **J** | Jump cursor to selected object |

### Categories (7 total)
1. **Infantry** - All men units, including dead bodies
2. **Vehicles** - Cars, armor, aircraft, ships, static weapons
3. **Logistics** - Ammo, weapons, items, containers, backpacks
4. **Cover** - Fortifications, walls, military structures, ruins
5. **Hazards** - Mines, explosives, wrecks
6. **Objectives** - Intel items, flags
7. **World** - Furniture, signs, civilian structures

### Announcements
- Range change: "Scanner range: 500 meters. 12 Infantry."
- Category change: "Vehicles, 3 objects"
- Object: "CSAT Rifleman, 50 meters north, enemy"
- Dead bodies: "dead NATO Medic, 30 meters southwest, friendly"
- Vehicles: "Ifrit, 200 meters east, empty"
- Jump: "Jumped to CSAT Rifleman."

---

## Phase 7: Road Exploration Mode - COMPLETE
Snap to and follow roads using the virtual cursor system.
Toggle with **R** key while in observer mode.

### Road Mode Controls
| Key | Action |
|-----|--------|
| **R** | Toggle road mode on/off |
| **Ctrl+R** | Open intersection menu (shows all roads at position) |
| **Alt+Up** | Follow road northward (toward more northerly endpoint) |
| **Alt+Down** | Follow road southward (toward more southerly endpoint) |
| **Alt+Right** | Follow road eastward (toward more easterly endpoint) |
| **Alt+Left** | Follow road westward (toward more westerly endpoint) |
| **Alt+Arrow** (off-road) | Search for road in that direction (200m range) |
| **Shift+Arrow** | Turn at intersection (compass direction) |

### Intersection Menu (Ctrl+R)
| Key | Action |
|-----|--------|
| **Up/Down** | Navigate roads |
| **Enter** | Select road and start following |
| **Escape** | Cancel |

Each road shows: direction, type, length, and destination (continues/ends/intersection)

### Road Types Detected
| Type | Description |
|------|-------------|
| Main road | Major paved roads, highways |
| Road | Standard paved roads |
| Dirt track | Unpaved dirt roads |
| Footpath | Pedestrian trails |
| Bridge | Detected and announced with length |

### Announcements
- Toggle: "Road mode on." / "Road mode off."
- Snap: "Snapped to main road, 45 meters east. Heading northeast." (includes jump distance/direction)
- Follow: "Main road. 12 meters northeast." (includes actual travel direction)
- Type change: "Road becomes dirt track."
- Bridge: "Bridge. 45 meters east."
- Intersection: "Intersection. Roads north, east, south, southwest." (all available directions)
- Turn: "Turned east onto dirt track."
- End: "Road ends." (stays on road for turn-around)
- Not found: "No road within range."
- Menu open: "Intersection menu. 4 roads. 1: Northeast, main road, 85 meters, continues."
- Menu select: "Selected east onto dirt track."

### Technical Notes
- Uses multi-method road detection: `roadAt`, `roadsConnectedTo`, and `nearRoads` combined
- `nearRoads` finds roads by CENTER point, not endpoints, so 50m radius is needed for long segments
- Endpoint filtering uses 15m tolerance to ensure roads with endpoints at target position are found
- Uses exact road endpoints for intersection detection (not calculated positions)
- Dead-end handling: stays on road at dead end, allows turn-around without re-snap bouncing
- This approach eliminates false "Road ends" announcements caused by `nearRoads` missing nearby segments

---

## Dev Sandbox - COMPLETE
Pre-placed assets at Stratis Air Base for testing all accessibility features.

### Assets Available
| Asset | Composition | Location |
|-------|-------------|----------|
| Infantry Squad Alpha | Leader, 2x Rifleman, Autorifleman, Medic, AT | North of runway |
| Infantry Squad Bravo | Leader, 2x Rifleman, Marksman, Engineer, Grenadier | 50m east of Alpha |
| Ghost Hawk Helicopter | UH-80 with pilot | West side of runway |
| Wipeout Jet | A-164 with pilot | East side of runway |
| Marshall APC | With crew of 3 | Center of base |
| Mortar Team | 2 soldiers + Mk6 Mortar | Behind infantry |

### Debug Console Commands
```sqf
// Spawn enemies at designated zone (300m north)
["infantry", 6] call BA_fnc_spawnEnemies;
["armor", 2] call BA_fnc_spawnEnemies;
["mixed", 8] call BA_fnc_spawnEnemies;

// Clear all spawned enemies
[] call BA_fnc_clearEnemies;

// Respawn dead friendly units
[] call BA_fnc_resetAssets;
```

### Speech Feedback
- Spawn: "Spawned 6 infantry enemies, 300 meters north"
- Clear: "Cleared 8 enemies"
- Reset: "Reset complete. 2 units respawned" or "All units alive, no reset needed"
- Approach asset: "Infantry Squad Alpha - 6 units" / "Ghost Hawk Helicopter - ready"

### Navigation
- **Ctrl+Tab** cycles between all group leaders (squads, heli, jet, APC, mortar)
- **Tab** cycles members within each group
- Walk near an asset to hear its announcement

---

## AI Status Feedback System - COMPLETE (Revised)
Rich unit state information for blind players - Tab through units to assess their status.

### Philosophy
Instead of unreliable automatic order completion detection, give players rich unit state
information and let them judge for themselves when orders are complete.

### Group Menu (G key)
Simple format with straggler count:
- "Alpha 1-1, Sergeant Miller, 4 infantry"
- "Alpha 1-1, Sergeant Miller, 4 infantry, 2 stragglers"

**Straggler detection**: Unit >50m from leader OR `moveToFailed` (stuck on terrain)

### Unit Switching (Tab/Ctrl+Tab) - Enhanced

**Infantry announcements** include stance, alert, movement, and context:
- "Blufor. Alpha 1. Rifleman. John Smith. Crouched. Combat. Moving."
- "Blufor. Alpha 1. Rifleman. John Smith. Prone. Combat. Ready. Inside building."
- "Blufor. Alpha 1. Rifleman. John Smith. Standing. Aware. Moving. 85 meters from leader."
- "Blufor. Alpha 1. Rifleman. John Smith. Crouched. Combat. Ready. Targeting enemy."

| Status | Values |
|--------|--------|
| Stance | Standing, Crouched, Prone |
| Alert | Relaxed, Safe, Aware, Combat, Stealth |
| Movement | Ready, Moving, Stuck |
| Context | Inside building, X meters from leader, Targeting enemy |

**Vehicle crew announcements** (skip stance/movement - doesn't apply):
- "Blufor. Condor. Helicopter Pilot. Mike Ross. In Ghost Hawk."
- "Blufor. Condor. Helicopter Crew. In Ghost Hawk."

### Fixed: Vehicle Announcement Bugs
- No more false "Dismounted" spam when Tab-switching between units
- Vehicle name now announced when switching to crew members

---

## Phase 8: Audio Aiming Assist - COMPLETE (2026-02-02)
Real-time audio feedback to help blind players aim at enemies.

### Key Binding
| Key | Action |
|-----|--------|
| **End** | Toggle aim assist on/off |

Works in both observer mode (AI aims) and manual mode (player aims).

### Audio Feedback
| Audio Parameter | Meaning |
|-----------------|---------|
| **Stereo Pan** | Left ear = turn left, Right ear = turn right |
| **Pitch** | Low (300 Hz) = aim up, High (800 Hz) = aim down |
| **Sine Wave** | Tracking enemy |
| **Square Wave** | Locked on target (harsh/buzzy tone) |
| **Silence** | No visible enemy, or enemy behind you |

### Speech Announcements
| Event | Announcement |
|-------|--------------|
| **Target acquired** | "Targeting CSAT Rifleman, 50 meters." |
| **Target changed** | "Targeting Ifrit, 120 meters." |
| **Target lost** | "Target lost." |

### Target Acquisition
- Range: 500 meters maximum
- Requires line of sight (no tone through walls)
- Only targets known enemies (`knowsAbout > 0.5`)
- Targets nearest visible hostile first
- Supports: Infantry, Cars, Tanks, Helicopters, Planes

### Technical Details
- Update rate: 20 Hz (50ms intervals)
- Uses miniaudio library for real-time audio synthesis
- DLL commands: `aim_start`, `aim_update:pan,pitch,locked`, `aim_stop`
- Mute signal: pitch = -1 (enemy behind or no target)

### DLL Test Commands (Debug Console)
```sqf
"nvda_arma3_bridge" callExtension "aim_start"           // Initialize
"nvda_arma3_bridge" callExtension "aim_update:0.8,550,0" // Pan right, center pitch
"nvda_arma3_bridge" callExtension "aim_update:0,750,0"   // High pitch (aim up)
"nvda_arma3_bridge" callExtension "aim_update:0,550,1"   // Locked (square wave)
"nvda_arma3_bridge" callExtension "aim_stop"            // Stop
```

---

## Phase 9: Audio Terrain Radar - COMPLETE (2026-02-03)
Spatial awareness via audio tones. 45 rays sweep 90° in front (±45° from center).

### Controls
| Key | Action |
|-----|--------|
| **Ctrl+W** | Toggle radar (manual mode only) |
| **Ctrl+Shift+W** | Toggle debug logging |

### Audio Feedback
| Material | Frequency | Waveform |
|----------|-----------|----------|
| Grass/dirt/sand | 200 Hz | Sine |
| Concrete/rock | 400 Hz | Square |
| Wood | 300 Hz | Triangle |
| Metal | 600 Hz | Sawtooth |
| Water | 150 Hz | Sine+harmonic |
| Human | 800 Hz | Pulse |
| Glass | 700 Hz | Sine+harmonic |
| Unknown | 350 Hz | Sine |

- **Stereo pan** = direction (-45° left to +45° right)
- **Volume** = distance (loud at 0.5m, quiet at 100m)
- **Silence** = nothing detected in that direction

---

## Phase 10: Focus Mode - COMPLETE (2026-02-03)
Accessibility features (cursor, scanner, landmarks) without observer mode.
Allows exploration while keeping direct control of the soldier.

### Controls
| Key | Action |
|-----|--------|
| **~ (Backtick)** | Toggle focus mode on/off |
| **WASD** | Auto-exits focus mode (movement) |
| **ESC** | Exit focus mode |

### Features Available in Focus Mode
- Virtual cursor movement (Alt/Shift/Ctrl + arrows)
- Landmarks menu (L key)
- Object scanner (PageUp/Down, Ctrl+PageUp/Down, U, J)
- Road exploration (R key, Ctrl+R)
- Status announcements (Alt+1-9, Alt+0)
- Detailed scan (I key)
- Snap cursor to self (Home/Backspace)

### Features NOT Available (Observer-only)
- Group selection menu (G) - requires observer mode
- Orders menu (O) - requires selected group
- Unit/group cycling (Tab) - conflicts with Arma default

### Technical Notes
- Uses transparent dialog overlay (`BA_FocusModeDialog`) to block engine inputs
- This prevents L from toggling flashlight, R from reloading, arrows from turning soldier
- Dialog's `enableSimulation = true` keeps game world running normally
- Mouse cursor becomes visible while dialog open (minimal impact for blind players)
- Dialog's `onUnload` cleans up state as safety net
- Focus mode cursor anchors to `player` position (observer uses `BA_observedUnit`)
- Entering observer mode (Ctrl+O) auto-exits focus mode
- Focus mode cannot be toggled while in observer mode (not needed - full features available)

---

## Addon Packaging - COMPLETE (2026-02-03)
Self-contained addon structure for distribution as PBO.

### Files Created
| File | Purpose |
|------|---------|
| `blind_assist/config.cpp` | Master addon config - includes CfgPatches, CfgFunctions, dialogs |
| `blind_assist/$PBOPREFIX$` | Addon root marker - contains `blind_assist` |
| `blind_assist/CfgFunctions_Addon.hpp` | PBO function paths (`\blind_assist`) |

### Two Workflows Supported
| Workflow | CfgFunctions File | Path Style |
|----------|-------------------|------------|
| **Development** | `CfgFunctions.hpp` | `file = "blind_assist"` (mission-relative) |
| **Distribution** | `CfgFunctions_Addon.hpp` | `file = "\blind_assist"` (absolute addon path) |

### PBO Packing Instructions
Using Arma 3 Tools (AddonBuilder):
```
Source: D:\arma3 access\blind_assist\
Output: blind_assist.pbo
Prefix: blind_assist (from $PBOPREFIX$ file)
```

### Usage as Addon
1. Pack `blind_assist/` folder into `blind_assist.pbo`
2. Place in `Arma 3\@BlindAssist\addons\blind_assist.pbo`
3. Launch with `-mod=@BlindAssist`
4. Works with ANY mission - no description.ext edits needed

---

## Phase 11: Direction Snap - COMPLETE (2026-02-03)
Compass direction snapping for blind manual gameplay.
Cycles through 8 cardinal directions with smooth interpolation.

### Controls
| Key | Action |
|-----|--------|
| **Delete** | Cycle counter-clockwise (left) |
| **Page Down** | Cycle clockwise (right) |

**Note:** Only works in manual mode (NOT observer or focus mode).
In observer/focus mode, Page Down is used for scanner navigation.

### 8 Cardinal Directions
North (0°) → Northeast (45°) → East (90°) → Southeast (135°) →
South (180°) → Southwest (225°) → West (270°) → Northwest (315°)

### Behavior
- Finds closest cardinal direction to current facing
- Snaps to next direction in chosen rotation
- Smooth interpolation over 0.15 seconds (smoothstep easing)
- Levels view both horizontally and vertically (looks at horizon)
- Announces target direction via TTS (e.g., "northeast")

### Technical Notes
- Uses `setDir` for body direction + `setVectorDir [sin, cos, 0]` for level view
- Smoothstep formula: `t*t*(3-2*t)` for natural easing
- Angle wraparound handled correctly (315° → 0°, 0° → 315°)
- EachFrame handler provides precise timing
- Cancels in-progress interpolation if key pressed again quickly

---

## Phase 12: Player Waypoint Navigation - COMPLETE (2026-02-03)
Audio beacon guidance to navigate to cursor position.
Uses Arma 3's pathfinding to route through doors and around obstacles.

### Controls
| Key | Action |
|-----|--------|
| **Y** | Set waypoint at cursor position |
| **Ctrl+Y** | Clear active waypoint |

**Requires:** Cursor active (Focus Mode or Observer Mode).

### Audio Beacon
| Audio Aspect | Meaning |
|--------------|---------|
| **Stereo Pan** | Left ear = turn left, Right ear = turn right |
| **Frequency** | 400 Hz (off-center) → 460 Hz (on-target) |
| **Pulse Rate** | Slow (2 Hz) far off → Fast (15 Hz) near → Steady when facing |
| **Waveform** | Triangle wave with 4000 Hz low-pass filter |

Beacon is mutually exclusive with aim assist - only one plays at a time.

### Distance Announcements
Announces when crossing thresholds: 500m, 300m, 200m, 150m, 100m, 75m, 50m, 30m, 20m, 10m.
- Initial: "Waypoint set. 127 meters."
- Progress: "100 meters." ... "50 meters." ... "10 meters."
- Arrival: "Arrived at waypoint." (< 3m from destination)

### Path Deviation
- If player strays >15m from calculated path, announces "Recalculating route."
- 5-second cooldown between recalculations
- If pathfinding fails: "Route blocked. Try a different waypoint."

### Technical Notes
- Uses async `calculatePath ["man", "safe", destination, callback]`
- Path includes waypoints through doors, around obstacles
- 10 Hz update loop (EachFrame with rate limiting)
- Breadcrumb radius: 5m (advance to next path point)
- Arrival radius: 3m (waypoint reached)
- Local marker created at destination (yellow objective marker)

### DLL Commands
```sqf
"nvda_arma3_bridge" callExtension "beacon_start"        // Start beacon
"nvda_arma3_bridge" callExtension "beacon_update:0.5"   // Pan right
"nvda_arma3_bridge" callExtension "beacon_update:-0.3"  // Pan left
"nvda_arma3_bridge" callExtension "beacon_stop"         // Stop beacon
```

---

## Phase 13: Automatic Enemy Detection - COMPLETE (2026-02-05)
Real-time announcements when enemies are spotted by your soldier.

### Features
- **Automatic**: No key press needed - announces as soon as soldier detects enemy
- **Realistic detection**: Uses `nearTargets` - only announces enemies your soldier knows about
- **Re-announcement**: If enemy leaves awareness and returns, announces again
- **All modes**: Works in observer mode, focus mode, and normal play

### Announcement Format
```
"[distance] meters, [unit type], [direction]"
```
Examples:
- "50 meters, Rifleman, northeast"
- "200 meters, Tank, south"
- "120 meters, CSAT Autorifleman, west"

### Detection Criteria
Enemies are announced when:
- Your soldier sees them
- Your soldier hears them
- Your side has spotted them (shared intel)

Enemies are NOT announced when:
- They're hidden and undetected
- They're behind you and silent
- Your soldier has no awareness of them

### Technical Notes
- Update rate: 2 Hz (every 0.5 seconds)
- Range: 2000m (limited by `nearTargets`, not a magic detection bubble)
- Tracks announced enemies to avoid spam
- Removes enemies from tracking when they leave awareness
- Uses same unit reference as Alt+5 status check

---

## Phase 14: Chat Reader - COMPLETE (2026-02-05)
Automatic NVDA announcements for incoming Side Chat and Command Chat messages.

### Features
- **Automatic**: No key press needed - announces incoming radio messages
- **Side Chat (Channel 1)**: Game announcements like "Sector Lost", "Objective Updated"
- **Command Chat (Channel 2)**: Commander strategic messages
- **Visual preserved**: Messages still display on screen normally

### Announcement Format
```
"Radio: [Name] says, [message]"
```
Examples:
- "Radio: HQ says, Sector Alpha captured."
- "Radio: Command says, Reinforcements inbound."
- "Radio: Sergeant Miller says, Enemy contact!"

### Channel Reference
| Channel | ID | Announced |
|---------|----|----|
| Global | 0 | No |
| Side | 1 | Yes |
| Command | 2 | Yes |
| Group | 3 | No (spammy) |
| Vehicle | 4 | No |
| Direct | 5 | No |

### Use Cases
- **Warlords**: "We are attacking Mike-26", "Sector lost"
- **Combat Patrol**: Objective updates, completion messages
- **Custom missions**: Any scripted sideChat announcements

---

