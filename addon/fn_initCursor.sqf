/*
 * Function: BA_fnc_initCursor
 * Initializes cursor variables for map exploration.
 * Called from initObserverMode.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_initCursor;
 */

// Initialize cursor position (world coordinates)
BA_cursorPos = [0, 0, 0];

// Cursor is active when in observer mode
BA_cursorActive = false;

// Terrain type mapping for human-readable names
// Includes generic GDT types and Stratis-specific surfaces
// Road exploration mode variables
BA_roadModeEnabled = false;        // Toggle state for road exploration mode
BA_currentRoad = objNull;          // Current road segment being followed
BA_roadDirection = 0;              // 0 = toward endPos (positive bearing), 1 = toward begPos (negative bearing)
BA_lastRoadInfo = [];              // Cached getRoadInfo result for current road

// Terrain type mapping for human-readable names
// Includes generic GDT types and Stratis-specific surfaces
BA_terrainTypes = createHashMapFromArray [
    // Generic GDT types
    ["#gdt_grass", "Grass"],
    ["#gdt_dirt", "Dirt"],
    ["#gdt_sand", "Sand"],
    ["#gdt_rock", "Rock"],
    ["#gdt_concrete", "Concrete"],
    ["#gdt_asphalt", "Road"],
    ["#gdt_gravel", "Gravel"],
    ["#gdt_forest", "Forest"],
    ["#gdt_water", "Water"],
    ["#gdt_beach", "Beach"],
    ["#gdt_mud", "Mud"],
    ["#gdt_dry_grass", "Dry grass"],
    ["#gdt_lino", "Floor"],
    ["#gdt_metal", "Metal"],
    ["#gdt_wood", "Wood"],
    ["#gdt_stone", "Stone"],
    // Stratis surfaces (lowercase, as returned by surfaceType after toLower)
    ["#stratisdrygrass", "Dry grass"],
    ["#stratisgreengrass", "Grass"],
    ["#stratisgrass", "Grass"],
    ["#stratisdirt", "Dirt"],
    ["#stratisrock", "Rock"],
    ["#stratissand", "Sand"],
    ["#stratisbeach", "Beach"],
    ["#stratisconcrete", "Concrete"],
    ["#stratisforest", "Forest"],
    ["#stratisasphalt", "Road"],
    ["#stratisgravel", "Gravel"],
    ["#stratismud", "Mud"],
    ["#stratiswater", "Water"],
    ["#stratisseabed", "Seabed"],
    ["#stratisrubble", "Rubble"],
    // Altis surfaces
    ["#altisdrygrass", "Dry grass"],
    ["#altisgreengrass", "Grass"],
    ["#altisgrass", "Grass"],
    ["#altisdirt", "Dirt"],
    ["#altisrock", "Rock"],
    ["#altissand", "Sand"],
    ["#altisbeach", "Beach"],
    ["#altisconcrete", "Concrete"],
    ["#altisforest", "Forest"],
    ["#altisasphalt", "Road"],
    // Generic without underscore
    ["#gdtforest", "Forest"],
    ["#gdtgrass", "Grass"],
    ["#gdtrock", "Rock"],
    ["#gdtdirt", "Dirt"],
    ["#gdtsand", "Sand"],
    ["#gdtbeach", "Beach"],
    ["#gdtconcrete", "Concrete"],
    ["#gdtasphalt", "Road"]
];
