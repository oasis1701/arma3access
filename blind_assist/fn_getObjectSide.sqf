/*
 * Function: BA_fnc_getObjectSide
 * Returns side name and relation to player.
 *
 * Arguments:
 *   0: _object - Object to check side for
 *
 * Return Value:
 *   Array - [sideName, relation]
 *   sideName: "BLUFOR", "OPFOR", "Independent", "Civilian", "Unknown"
 *   relation: "friendly", "enemy", "civilian", "empty", "unknown"
 *
 * Example:
 *   [_unit] call BA_fnc_getObjectSide;
 *   // Returns: ["OPFOR", "enemy"]
 */

params [["_object", objNull, [objNull]]];

// Helper function to convert side to readable name
private _sideToName = {
    params ["_side"];
    switch (_side) do {
        case west: { "BLUFOR" };
        case east: { "OPFOR" };
        case independent: { "Independent" };
        case civilian: { "Civilian" };
        default { "Unknown" };
    };
};

// Helper function to get side from config (for dead infantry)
// Config side: 0=OPFOR, 1=BLUFOR, 2=Independent, 3=Civilian
private _getConfigSide = {
    params ["_obj"];
    private _cfgSide = getNumber (configFile >> "CfgVehicles" >> typeOf _obj >> "side");
    switch (_cfgSide) do {
        case 0: { east };
        case 1: { west };
        case 2: { independent };
        case 3: { civilian };
        default { sideUnknown };
    };
};

if (isNull _object) exitWith { ["Unknown", "unknown"] };

// For vehicles (not infantry) - handle crew-based side detection
if (_object isKindOf "AllVehicles" && !(_object isKindOf "Man")) exitWith {
    private _crew = crew _object;
    private _aliveCrew = _crew select {alive _x};
    private _deadCrew = _crew select {!alive _x};

    // Case 1: Has living crew - show their side and relation
    if (count _aliveCrew > 0) then {
        private _crewSide = side group (_aliveCrew select 0);
        private _sideName = [_crewSide] call _sideToName;
        private _playerSide = if (!isNil "BA_originalUnit" && {!isNull BA_originalUnit}) then {
            side BA_originalUnit
        } else {
            side player
        };
        private _relation = if (_crewSide == civilian) then { "civilian" }
            else {
                if (_crewSide == _playerSide) then {
                    "friendly"
                } else {
                    // Check diplomatic relations (0.6+ is friendly threshold in Arma 3)
                    if ((_playerSide getFriend _crewSide) >= 0.6) then { "friendly" } else { "enemy" }
                }
            };
        [_sideName, _relation]
    } else {
        // Case 2: No living crew
        if (count _deadCrew > 0) then {
            // Has dead crew - report their side
            private _deadCrewSide = [_deadCrew select 0] call _getConfigSide;
            private _sideName = [_deadCrewSide] call _sideToName;
            ["", format ["dead %1 crew", _sideName]]  // Empty sideName, special relation
        } else {
            // Completely empty
            ["", "empty"]
        }
    }
};

// Get the side of the object (use group side for accurate allegiance)
// This section now only handles infantry (Man)
private _objectSide = if (_object isKindOf "Man") then {
    private _grpSide = side group _object;
    // Dead units are removed from groups, use config side as fallback
    if (_grpSide == sideUnknown && !alive _object) then {
        [_object] call _getConfigSide
    } else {
        _grpSide
    }
} else {
    // Fallback for non-vehicle, non-Man objects
    side _object
};

// Get side name
private _sideName = [_objectSide] call _sideToName;

// Handle objects with no side (civilian objects, etc.)
if (_objectSide == sideUnknown || _objectSide == sideEmpty) exitWith {
    ["Unknown", "unknown"]
};

// Get player's side for comparison (use BA_originalUnit in observer mode)
private _playerSide = if (!isNil "BA_originalUnit" && {!isNull BA_originalUnit}) then {
    side BA_originalUnit
} else {
    side player
};

// Determine relation based on direct side comparison
if (_objectSide == civilian) exitWith { [_sideName, "civilian"] };

if (_objectSide == _playerSide) exitWith { [_sideName, "friendly"] };

// Check diplomatic relations (0.6+ is friendly threshold in Arma 3)
if ((_playerSide getFriend _objectSide) >= 0.6) exitWith { [_sideName, "friendly"] };

// Different military side with hostile relations = enemy
[_sideName, "enemy"]
