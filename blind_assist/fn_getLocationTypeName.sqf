/*
 * Function: BA_fnc_getLocationTypeName
 * Converts a location type code to a readable name.
 *
 * Arguments:
 *   0: _type - Location type string (e.g., "NameCity", "b_inf")
 *
 * Return Value:
 *   String - Human-readable type name
 *
 * Example:
 *   ["NameCity"] call BA_fnc_getLocationTypeName;
 *   // Returns: "City"
 *   ["b_inf"] call BA_fnc_getLocationTypeName;
 *   // Returns: "BLUFOR Infantry"
 */

params [["_type", "", [""]]];

// Check for NATO symbol (b_, o_, n_ prefix)
private _prefix = _type select [0, 2];
if (_prefix in ["b_", "o_", "n_"]) exitWith {
    // Decode faction
    private _faction = switch (_prefix) do {
        case "b_": { "BLUFOR" };
        case "o_": { "OPFOR" };
        case "n_": { "Independent" };
        default { "Unknown" };
    };

    // Decode unit type (everything after the prefix)
    private _unitCode = _type select [2];
    private _unitType = switch (_unitCode) do {
        case "inf": { "Infantry" };
        case "motor_inf": { "Motorized Infantry" };
        case "mech_inf": { "Mechanized Infantry" };
        case "armor": { "Armor" };
        case "recon": { "Recon" };
        case "air": { "Air" };
        case "plane": { "Fixed Wing" };
        case "heli": { "Helicopter" };
        case "uav": { "UAV" };
        case "naval": { "Naval" };
        case "art": { "Artillery" };
        case "mortar": { "Mortar" };
        case "hq": { "Headquarters" };
        case "med": { "Medical" };
        case "support": { "Support" };
        case "maint": { "Maintenance" };
        case "service": { "Service" };
        case "antiair": { "Anti-Air" };
        case "installation": { "Installation" };
        case "unknown": { "Unknown" };
        default { _unitCode };
    };

    format ["%1 %2", _faction, _unitType]
};

// Geography and Tactical types
switch (_type) do {
    // Geography
    case "NameCityCapital": { "Capital" };
    case "NameCity": { "City" };
    case "NameVillage": { "Village" };
    case "Airport": { "Airport" };
    case "NameMarine": { "Marine" };
    case "Hill": { "Hill" };
    case "Mount": { "Mountain" };
    case "RockArea": { "Rocky Area" };
    case "ViewPoint": { "Viewpoint" };

    // Tactical
    case "Strategic": { "Strategic Point" };
    case "StrongpointArea": { "Strongpoint" };
    case "BorderCrossing": { "Border Crossing" };
    case "SafetyZone": { "Safety Zone" };
    case "HandDrawnCamp": { "Camp" };
    case "HistoricalSite": { "Historical Site" };
    case "CulturalProperty": { "Cultural Property" };
    case "CivilDefense": { "Civil Defense" };
    case "DangerousForces": { "Dangerous Forces" };

    // Extras
    case "Flag": { "Flag" };
    case "Name": { "Location" };
    case "NameLocal": { "Local Area" };

    // Default - return type as-is
    default { _type };
}
