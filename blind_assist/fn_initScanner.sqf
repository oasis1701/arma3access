/*
 * Function: BA_fnc_initScanner
 * Initializes the object scanner system with categories and state variables.
 *
 * Categories (14 total):
 *   0. Friendly Infantry      - alive friendly men
 *   1. Friendly Vehicles      - alive crewed friendly vehicles
 *   2. Enemy Infantry         - alive enemy men
 *   3. Enemy Vehicles         - alive crewed enemy vehicles
 *   4. Destroyed Friendly Vehicles - destroyed vehicles with friendly dead crew
 *   5. Destroyed Enemy Vehicles    - destroyed vehicles with enemy dead crew
 *   6. Empty Vehicles         - alive vehicles with no crew
 *   7. Dead Friendly Infantry - dead friendly men
 *   8. Dead Enemy Infantry    - dead enemy men
 *   9. Logistics              - ammo, weapons, items, containers
 *  10. Cover                  - fortifications, walls, military structures
 *  11. Hazards                - mines, explosives, wrecks
 *  12. Objectives             - intel, flags
 *  13. World                  - furniture, signs, civilian structures
 *
 * Each category: [name, classTypes, filterTag]
 *   filterTag "" means no filtering (include all matches)
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_initScanner;
 */

// Scanner state variables
BA_scannerRange = 500;           // Current scan range in meters
BA_scannerCategoryIndex = 0;     // Current category (0-13)
BA_scannerObjectIndex = 0;       // Current object in category
BA_scannedObjects = [];          // Array of objects in current category/range

// Shared type arrays
private _infantryTypes = [
    "Men", "MenRecon", "MenSniper", "MenSupport", "MenDiver", "MenStory",
    "MenTanoan", "MenUrban", "Afroamerican", "Asian", "European",
    "CAManBase", "Man"
];

private _vehicleTypes = [
    "Car", "Armored", "Air", "Ship", "Submarine", "Submerged",
    "Autonomous", "Support", "StaticWeapon", "Tank", "APC", "Truck",
    "Helicopter", "Plane", "Boat"
];

// Category definitions: [name, classTypes, filterTag]
BA_scannerCategories = [
    // 0: Friendly Infantry - alive friendly men
    ["Friendly Infantry", _infantryTypes, "friendly_infantry"],

    // 1: Friendly Vehicles - alive crewed friendly vehicles
    ["Friendly Vehicles", _vehicleTypes, "friendly_vehicles"],

    // 2: Enemy Infantry - alive enemy men
    ["Enemy Infantry", _infantryTypes, "enemy_infantry"],

    // 3: Enemy Vehicles - alive crewed enemy vehicles
    ["Enemy Vehicles", _vehicleTypes, "enemy_vehicles"],

    // 4: Destroyed Friendly Vehicles
    ["Destroyed Friendly Vehicles", _vehicleTypes, "destroyed_friendly_vehicles"],

    // 5: Destroyed Enemy Vehicles
    ["Destroyed Enemy Vehicles", _vehicleTypes, "destroyed_enemy_vehicles"],

    // 6: Empty Vehicles - alive with no crew
    ["Empty Vehicles", _vehicleTypes, "empty_vehicles"],

    // 7: Dead Friendly Infantry
    ["Dead Friendly Infantry", _infantryTypes, "dead_friendly_infantry"],

    // 8: Dead Enemy Infantry
    ["Dead Enemy Infantry", _infantryTypes, "dead_enemy_infantry"],

    // 9: Logistics - Supplies, weapons, equipment
    [
        "Logistics",
        [
            "Ammo", "WeaponsPrimary", "WeaponsSecondary", "WeaponsHandguns",
            "WeaponAccessories", "Items", "ItemsVests", "ItemsHeadgear",
            "ItemsUniforms", "Backpacks", "Container", "Cargo", "Small_items",
            "SupplyBox", "ReammoBox", "WeaponHolderSimulated", "GroundWeaponHolder"
        ],
        ""
    ],

    // 10: Cover - Defensive positions and structures
    [
        "Cover",
        [
            "Fortifications", "Structures_Military", "Structures_Walls",
            "Structures_Fences", "Ruins", "Tents", "Bunker", "Wall",
            "Fence", "Sandbag", "HBarrier"
        ],
        ""
    ],

    // 11: Hazards - Dangerous objects
    [
        "Hazards",
        [
            "Mines", "mines", "Explosives", "Wreck", "Wreck_sub",
            "MineBase", "TimeBombCore", "DirectionalBombBase"
        ],
        ""
    ],

    // 12: Objectives - Mission-relevant objects
    [
        "Objectives",
        [
            "Intel", "Flag", "IntelItem", "Documents", "FlagCarrier"
        ],
        ""
    ],

    // 13: World - Environmental objects
    [
        "World",
        [
            "Furniture", "Market", "Lamps", "Signs", "Structures_Town",
            "Structures_Village", "Structures_Commercial", "Structures_Industrial",
            "Structures_Cultural", "Structures_Infrastructure", "Building",
            "House", "Strategic"
        ],
        ""
    ]
];

// Log initialization
diag_log "Blind Assist: Scanner system initialized (14 categories).";
