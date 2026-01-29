/*
 * Function: BA_fnc_initScanner
 * Initializes the object scanner system with categories and state variables.
 *
 * Categories:
 *   1. Infantry - Men units (alive and dead)
 *   2. Vehicles - Cars, armor, aircraft, ships
 *   3. Logistics - Ammo, weapons, items, containers
 *   4. Cover - Fortifications, walls, military structures
 *   5. Hazards - Mines, explosives, wrecks
 *   6. Objectives - Intel, flags
 *   7. World - Furniture, signs, civilian structures
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
BA_scannerCategoryIndex = 0;     // Current category (0-6)
BA_scannerObjectIndex = 0;       // Current object in category
BA_scannedObjects = [];          // Array of objects in current category/range

// Category definitions
// Each category has a name and array of Arma 3 class types to search for
BA_scannerCategories = [
    // 0: Infantry - All human units including dead bodies
    [
        "Infantry",
        [
            "Men", "MenRecon", "MenSniper", "MenSupport", "MenDiver", "MenStory",
            "MenTanoan", "MenUrban", "Afroamerican", "Asian", "European",
            "CAManBase", "Man"
        ]
    ],

    // 1: Vehicles - All vehicle types (StaticWeapon for turrets/mortars, not Static which catches fences)
    [
        "Vehicles",
        [
            "Car", "Armored", "Air", "Ship", "Submarine", "Submerged",
            "Autonomous", "Support", "StaticWeapon", "Tank", "APC", "Truck",
            "Helicopter", "Plane", "Boat"
        ]
    ],

    // 2: Logistics - Supplies, weapons, equipment
    [
        "Logistics",
        [
            "Ammo", "WeaponsPrimary", "WeaponsSecondary", "WeaponsHandguns",
            "WeaponAccessories", "Items", "ItemsVests", "ItemsHeadgear",
            "ItemsUniforms", "Backpacks", "Container", "Cargo", "Small_items",
            "SupplyBox", "ReammoBox", "WeaponHolderSimulated", "GroundWeaponHolder"
        ]
    ],

    // 3: Cover - Defensive positions and structures
    [
        "Cover",
        [
            "Fortifications", "Structures_Military", "Structures_Walls",
            "Structures_Fences", "Ruins", "Tents", "Bunker", "Wall",
            "Fence", "Sandbag", "HBarrier"
        ]
    ],

    // 4: Hazards - Dangerous objects
    [
        "Hazards",
        [
            "Mines", "mines", "Explosives", "Wreck", "Wreck_sub",
            "MineBase", "TimeBombCore", "DirectionalBombBase"
        ]
    ],

    // 5: Objectives - Mission-relevant objects
    [
        "Objectives",
        [
            "Intel", "Flag", "IntelItem", "Documents", "FlagCarrier"
        ]
    ],

    // 6: World - Environmental objects
    [
        "World",
        [
            "Furniture", "Market", "Lamps", "Signs", "Structures_Town",
            "Structures_Village", "Structures_Commercial", "Structures_Industrial",
            "Structures_Cultural", "Structures_Infrastructure", "Building",
            "House", "Strategic"
        ]
    ]
];

// Log initialization
diag_log "Blind Assist: Scanner system initialized.";
