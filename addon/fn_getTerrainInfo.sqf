/*
 * Function: BA_fnc_getTerrainInfo
 * Gets the terrain type at a position as a human-readable name.
 *
 * Arguments:
 *   0: _pos - Position to check (default: BA_cursorPos)
 *
 * Return Value:
 *   String - Terrain type name (e.g., "Grass", "Road", "Water")
 *
 * Example:
 *   private _terrain = [BA_cursorPos] call BA_fnc_getTerrainInfo;
 */

params [
    ["_pos", [], [[]]]
];

// Use cursor position if none provided
if (count _pos == 0) then {
    _pos = BA_cursorPos;
};

// Get surface type at position
private _surface = surfaceType _pos;

// Convert to lowercase for matching
_surface = toLower _surface;

// Known terrain types (base names without suffixes)
private _terrainTypes = createHashMapFromArray [
    ["seabed", "Seabed"],
    ["beach", "Beach"],
    ["sand", "Sand"],
    ["drygrass", "Dry grass"],
    ["greengrass", "Grass"],
    ["grass", "Grass"],
    ["tallgrass", "Tall grass"],
    ["dirt", "Dirt"],
    ["rock", "Rock"],
    ["rocks", "Rocks"],
    ["forest", "Forest"],
    ["forestpine", "Pine forest"],
    ["forestconifer", "Conifer forest"],
    ["forestbroadleaf", "Forest"],
    ["jungle", "Jungle"],
    ["concrete", "Concrete"],
    ["asphalt", "Road"],
    ["road", "Road"],
    ["gravel", "Gravel"],
    ["mud", "Mud"],
    ["water", "Water"],
    ["pond", "Pond"],
    ["river", "River"],
    ["rubble", "Rubble"],
    ["stone", "Stone"],
    ["soil", "Soil"],
    ["field", "Field"],
    ["crop", "Crops"],
    ["wheat", "Wheat field"],
    ["snow", "Snow"],
    ["ice", "Ice"],
    ["tarmac", "Tarmac"],
    ["runway", "Runway"],
    ["marsh", "Marsh"],
    ["swamp", "Swamp"]
];

// Strip prefixes: #gdt, #gdtstratis, #gdtaltis, etc.
// Format is like: #GdtStratisSeabedCluttered -> seabedcluttered
private _cleaned = _surface;

// Remove # if present
if (_cleaned find "#" == 0) then {
    _cleaned = _cleaned select [1, count _cleaned - 1];
};

// Remove "gdt" prefix if present (with or without underscore)
if (_cleaned find "gdt_" == 0) then {
    _cleaned = _cleaned select [4, count _cleaned - 4];
} else {
    if (_cleaned find "gdt" == 0) then {
        _cleaned = _cleaned select [3, count _cleaned - 3];
    };
};

// Remove map name prefixes (vanilla + DLC maps)
{
    if (_cleaned find _x == 0) then {
        _cleaned = _cleaned select [count _x, count _cleaned - count _x];
    };
} forEach ["stratis", "altis", "tanoa", "malden", "livonia", "enoch", "virtualreality", "vr", "bootcamp", "gabreta", "weferlingen"];

// Check for and extract suffixes like "cluttered", "detail", etc.
private _foundSuffix = "";
{
    private _suffix = _x;
    private _suffixLen = count _suffix;
    private _cleanedLen = count _cleaned;
    if (_cleanedLen > _suffixLen && _foundSuffix == "") then {
        if (_cleaned select [_cleanedLen - _suffixLen, _suffixLen] == _suffix) then {
            _foundSuffix = _suffix;
            _cleaned = _cleaned select [0, _cleanedLen - _suffixLen];
        };
    };
} forEach ["cluttered", "clutter", "detailed", "detail", "wet", "dry"];

// Look up in terrain types hashmap
private _terrainName = _terrainTypes getOrDefault [_cleaned, ""];

// If still not found, just capitalize first letter of cleaned string
if (_terrainName == "" && count _cleaned > 0) then {
    _terrainName = (toUpper (_cleaned select [0, 1])) + (_cleaned select [1, count _cleaned - 1]);
};

// Append suffix if one was found (e.g., "Seabed, cluttered")
if (_foundSuffix != "") then {
    _terrainName = format["%1, %2", _terrainName, _foundSuffix];
};

_terrainName
