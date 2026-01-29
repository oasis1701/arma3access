/*
 * Arma 3 Location Types Reference
 *
 * This file documents all available location types in Arma 3 for use with
 * nearestLocations and nearestLocation commands.
 *
 * Reference: https://community.bistudio.com/wiki/Location
 */

// =============================================================================
// GEOGRAPHY LOCATIONS
// =============================================================================
// Natural and settlement features

BA_locationTypes_geography = [
    "NameCityCapital",      // Capital city
    "NameCity",             // Large city
    "NameVillage",          // Village or small settlement
    "Airport",              // Airport
    "NameMarine",           // Marine/water feature name
    "Hill",                 // Hill
    "Mount",                // Mountain
    "RockArea",             // Rocky area
    "ViewPoint"             // Scenic viewpoint
];

// =============================================================================
// TACTICAL LOCATIONS
// =============================================================================
// Military and strategic features

BA_locationTypes_tactical = [
    "Strategic",            // Strategic location
    "StrongpointArea",      // Strongpoint/fortification
    "BorderCrossing",       // Border crossing point
    "SafetyZone",           // Safety zone
    "HandDrawnCamp",        // Camp marker (hand-drawn style)
    "HistoricalSite",       // Historical site
    "CulturalProperty"      // Cultural property marker
];

// =============================================================================
// NATO SYMBOLS
// =============================================================================
// Military unit markers using NATO symbology
// Prefixes: b_ = BLUFOR, o_ = OPFOR, n_ = Independent

BA_locationTypes_nato_prefixes = ["b_", "o_", "n_"];

// Common NATO symbol suffixes (combine with prefix)
BA_locationTypes_nato_suffixes = [
    "inf",              // Infantry
    "motor_inf",        // Motorized Infantry
    "mech_inf",         // Mechanized Infantry
    "armor",            // Armor
    "recon",            // Reconnaissance
    "air",              // Air
    "plane",            // Fixed Wing Aircraft
    "heli",             // Helicopter
    "uav",              // Unmanned Aerial Vehicle
    "naval",            // Naval
    "art",              // Artillery
    "mortar",           // Mortar
    "hq",               // Headquarters
    "med",              // Medical
    "support",          // Support
    "maint",            // Maintenance
    "service",          // Service
    "antiair",          // Anti-Air
    "installation",     // Installation
    "unknown"           // Unknown
];

// =============================================================================
// ALL LOCATION TYPES
// =============================================================================
// Complete list for reference

BA_allLocationTypes = [
    // Geography
    "NameCityCapital",
    "NameCity",
    "NameVillage",
    "Airport",
    "NameMarine",
    "Hill",
    "Mount",
    "RockArea",
    "ViewPoint",

    // Tactical
    "Strategic",
    "StrongpointArea",
    "BorderCrossing",
    "SafetyZone",
    "HandDrawnCamp",
    "HistoricalSite",
    "CulturalProperty",

    // NATO BLUFOR
    "b_inf", "b_motor_inf", "b_mech_inf", "b_armor", "b_recon",
    "b_air", "b_plane", "b_heli", "b_uav", "b_naval",
    "b_art", "b_mortar", "b_hq", "b_med", "b_support",
    "b_maint", "b_service", "b_antiair", "b_installation", "b_unknown",

    // NATO OPFOR
    "o_inf", "o_motor_inf", "o_mech_inf", "o_armor", "o_recon",
    "o_air", "o_plane", "o_heli", "o_uav", "o_naval",
    "o_art", "o_mortar", "o_hq", "o_med", "o_support",
    "o_maint", "o_service", "o_antiair", "o_installation", "o_unknown",

    // NATO Independent
    "n_inf", "n_motor_inf", "n_mech_inf", "n_armor", "n_recon",
    "n_air", "n_plane", "n_heli", "n_uav", "n_naval",
    "n_art", "n_mortar", "n_hq", "n_med", "n_support",
    "n_maint", "n_service", "n_antiair", "n_installation", "n_unknown",

    // Other location types (not used in landmarks menu)
    "Name",
    "NameLocal",
    "Area",
    "FlatArea",
    "FlatAreaCity",
    "FlatAreaCitySmall",
    "CityCenter",
    "VegetationBroadleaf",
    "VegetationFir",
    "VegetationPalm",
    "VegetationVineyard"
];
