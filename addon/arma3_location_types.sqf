/*
 * Arma 3 Location Types Reference
 *
 * Complete list of all location types discovered on Stratis.
 * This file is for REFERENCE ONLY - not used by code.
 * Active configuration is in fn_initLandmarksMenu.sqf
 */

// =============================================================================
// COMPLETE LIST (from Stratis map query)
// =============================================================================

BA_allLocationTypes = [
    // Geography - Settlements & Named Areas
    "NameCityCapital",      // Capital city
    "NameCity",             // Large city
    "NameVillage",          // Village
    "Name",                 // Generic named location
    "NameLocal",            // Local area name
    "NameMarine",           // Marine/water feature

    // Geography - Terrain Features
    "Mount",                // Mountain (many on map - removed)
    "Hill",                 // Hill (in Extras)
    "RockArea",             // Rocky area
    "ViewPoint",            // Scenic viewpoint
    "Airport",              // Airport

    // Geography - Areas (not currently used)
    "Area",                 // Generic area
    "FlatArea",             // Flat area
    "FlatAreaCity",         // Flat area in city
    "FlatAreaCitySmall",    // Small flat area in city
    "CityCenter",           // City center

    // Vegetation (not currently used)
    "VegetationBroadleaf",
    "VegetationFir",
    "VegetationPalm",
    "VegetationVineyard",

    // Tactical - Military/Strategic
    "Strategic",            // Strategic location
    "StrongpointArea",      // Strongpoint/fortification
    "BorderCrossing",       // Border crossing
    "SafetyZone",           // Safety zone
    "HandDrawnCamp",        // Camp marker
    "HistoricalSite",       // Historical site
    "CulturalProperty",     // Cultural property
    "CivilDefense",         // Civil defense
    "DangerousForces",      // Dangerous forces

    // Extras
    "Flag",                 // Flag marker
    "fakeTown",             // Fake town (not used)
    "Invisible",            // Invisible marker (not used)

    // NATO Symbols - BLUFOR (b_)
    "b_unknown", "b_inf", "b_motor_inf", "b_mech_inf", "b_armor",
    "b_recon", "b_air", "b_plane", "b_uav", "b_naval",
    "b_med", "b_art", "b_mortar", "b_hq", "b_support",
    "b_maint", "b_service", "b_installation", "b_antiair",

    // NATO Symbols - OPFOR (o_)
    "o_unknown", "o_inf", "o_motor_inf", "o_mech_inf", "o_armor",
    "o_recon", "o_air", "o_plane", "o_uav", "o_naval",
    "o_med", "o_art", "o_mortar", "o_hq", "o_support",
    "o_maint", "o_service", "o_installation", "o_antiair",

    // NATO Symbols - Independent (n_)
    "n_unknown", "n_inf", "n_motor_inf", "n_mech_inf", "n_armor",
    "n_recon", "n_air", "n_plane", "n_uav", "n_naval",
    "n_med", "n_art", "n_mortar", "n_hq", "n_support",
    "n_maint", "n_service", "n_installation", "n_antiair",

    // Civilian Markers (c_) - not currently used
    "c_unknown", "c_car", "c_ship", "c_air", "c_plane",

    // Unknown faction (u_)
    "u_installation",

    // Group Markers - not currently used
    "group_0", "group_1", "group_2", "group_3", "group_4",
    "group_5", "group_6", "group_7", "group_8", "group_9",
    "group_10", "group_11",

    // Respawn Markers - not currently used
    "respawn_unknown", "respawn_inf", "respawn_motor", "respawn_armor",
    "respawn_air", "respawn_plane", "respawn_naval", "respawn_para"
];

// =============================================================================
// CURRENTLY ACTIVE IN LANDMARKS MENU
// =============================================================================

/*
Geography:
    NameCityCapital, NameCity, NameVillage, Airport, NameMarine,
    RockArea, ViewPoint, Name, NameLocal

Tactical:
    Strategic, StrongpointArea, BorderCrossing, SafetyZone,
    HandDrawnCamp, HistoricalSite, CulturalProperty,
    CivilDefense, DangerousForces

NATO:
    All b_, o_, n_ prefixed types (detected dynamically)

Extras:
    Hill, Flag

NOT USED:
    Mount (too many), Area, FlatArea, FlatAreaCity, FlatAreaCitySmall,
    CityCenter, Vegetation*, fakeTown, Invisible, c_*, u_*,
    group_*, respawn_*
*/
