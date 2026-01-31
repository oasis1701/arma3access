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

### Other Unit Types (Helicopter, Jet, Vehicle, Artillery, Static)
Only **Move** available. All other commands removed due to broken syntax.
Add new commands one at a time, verifying against Arma 3 Wiki before adding.

### Unit Types & Commands

| Type | Commands |
|------|----------|
| **Infantry** | Move, Stop, Hold Position, Sneak, Assault, Garrison, Watch, Hold Fire, Fire at Will, Mount Nearest, Dismount |
| **Helicopter** | Fly Low/Medium/High, Land, Hover, Loiter CAS, Attack Run |
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

## Next: Phase 8 - Potential Features
- Formation changes
- Waypoint queue management
- Combat status announcements
- Audio beacons for orientation
