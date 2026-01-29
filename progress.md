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
- **Left/Right** - Switch between categories (Geography, Tactical, NATO)
- **Up/Down** - Navigate items within category
- **Enter** - Move cursor to selected landmark
- **Escape** - Cancel

### Categories
| Category | Location Types |
|----------|----------------|
| Geography | Capital, City, Village, Airport, Marine, Hill, Mountain, Rocky Area, Viewpoint |
| Tactical | Strategic Point, Strongpoint, Border Crossing, Safety Zone, Camp, Historical Site, Cultural Property |
| NATO | BLUFOR/OPFOR/Independent markers (Infantry, Armor, Air, Artillery, HQ, etc.) |

### Announcements
- Opening: "Landmarks. Geography category, 5 items. 1. Agia Marina, Village, 1520 meters northeast."
- Navigation: "2. Girna, Village, 2340 meters east."
- Category switch: "Tactical category, 3 items. 1. ..."
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

## Next: Phase 7 - Potential Features
- Formation changes
- Waypoint queue management
- Combat status announcements
- Audio beacons for orientation
