/*
 * Function: BA_fnc_initLandmarksMenu
 * Initializes the Landmarks Menu system state variables.
 *
 * The landmarks menu allows blind users to discover nearby map locations
 * from the virtual cursor position, organized by category.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_initLandmarksMenu;
 */

// Landmarks menu state variables
BA_landmarksMenuActive = false;      // Is menu currently open?
BA_landmarksCategoryIndex = 0;       // Current category (0=Geography, 1=Tactical, 2=NATO, 3=Extras)
BA_landmarksItemIndex = [0, 0, 0, 0];   // Current item index per category
BA_landmarksItems = [[], [], [], []];    // Cached landmarks per category [geo, tac, nato, extras]

// Category definitions
BA_landmarksCategories = [
    ["Geography", [
        "NameCityCapital",
        "NameCity",
        "NameVillage",
        "Airport",
        "NameMarine",
        "RockArea",
        "ViewPoint",
        "Name",
        "NameLocal"
    ]],
    ["Tactical", [
        "Strategic",
        "StrongpointArea",
        "BorderCrossing",
        "SafetyZone",
        "HandDrawnCamp",
        "HistoricalSite",
        "CulturalProperty",
        "CivilDefense",
        "DangerousForces"
    ]],
    ["NATO", []],  // NATO types detected dynamically by prefix
    ["Extras", [
        "Hill",
        "Flag"
    ]]
];

// Search configuration
BA_landmarksSearchRadius = -1;       // -1 = entire map (set to worldSize at runtime)
BA_landmarksMaxPerCategory = 50;     // Maximum items per category

systemChat "Blind Assist: Landmarks Menu initialized. Press L in observer mode.";
