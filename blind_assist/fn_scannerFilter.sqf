/*
 * Function: BA_fnc_scannerFilter
 * Filters a scanned object based on the category's filter tag.
 *
 * Arguments:
 *   0: _object - Object to test
 *   1: _filterTag - Filter tag string from category definition
 *
 * Return Value:
 *   Boolean - true if object passes the filter (should be included)
 *
 * Filter Tags:
 *   "friendly_infantry"           - alive + friendly side
 *   "enemy_infantry"              - alive + enemy side
 *   "friendly_vehicles"           - alive + has living crew + friendly
 *   "enemy_vehicles"              - alive + has living crew + enemy
 *   "destroyed_friendly_vehicles" - !alive + dead crew was friendly
 *   "destroyed_enemy_vehicles"    - !alive + dead crew was enemy
 *   "empty_vehicles"              - alive + no crew
 *   "dead_friendly_infantry"      - !alive + friendly side
 *   "dead_enemy_infantry"         - !alive + enemy side
 *   ""                            - no filter, include everything
 */

params [["_object", objNull, [objNull]], ["_filterTag", "", [""]]];

if (isNull _object) exitWith { false };
if (_filterTag == "") exitWith { true };

// Get player side for comparison
private _playerSide = if (!isNil "BA_originalUnit" && {!isNull BA_originalUnit}) then {
    side BA_originalUnit
} else {
    side player
};

// Helper: check if a side is friendly to player
private _isFriendly = {
    params ["_checkSide"];
    if (_checkSide == civilian) exitWith { false };
    if (_checkSide == sideUnknown || _checkSide == sideEmpty) exitWith { false };
    if (_checkSide == _playerSide) exitWith { true };
    (_playerSide getFriend _checkSide) >= 0.6
};

// Helper: get config side for dead units (group side becomes unknown)
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

switch (_filterTag) do {
    case "friendly_infantry": {
        if (!alive _object) exitWith { false };
        private _unitSide = side group _object;
        [_unitSide] call _isFriendly
    };

    case "enemy_infantry": {
        if (!alive _object) exitWith { false };
        private _unitSide = side group _object;
        if (_unitSide == civilian || _unitSide == sideUnknown || _unitSide == sideEmpty) exitWith { false };
        !([_unitSide] call _isFriendly)
    };

    case "friendly_vehicles": {
        if (!alive _object) exitWith { false };
        private _aliveCrew = (crew _object) select {alive _x};
        if (count _aliveCrew == 0) exitWith { false };
        private _crewSide = side group (_aliveCrew select 0);
        [_crewSide] call _isFriendly
    };

    case "enemy_vehicles": {
        if (!alive _object) exitWith { false };
        private _aliveCrew = (crew _object) select {alive _x};
        if (count _aliveCrew == 0) exitWith { false };
        private _crewSide = side group (_aliveCrew select 0);
        if (_crewSide == civilian || _crewSide == sideUnknown || _crewSide == sideEmpty) exitWith { false };
        !([_crewSide] call _isFriendly)
    };

    case "destroyed_friendly_vehicles": {
        if (alive _object) exitWith { false };
        private _deadCrew = (crew _object) select {!alive _x};
        if (count _deadCrew == 0) exitWith { false };
        private _deadSide = [_deadCrew select 0] call _getConfigSide;
        [_deadSide] call _isFriendly
    };

    case "destroyed_enemy_vehicles": {
        if (alive _object) exitWith { false };
        private _deadCrew = (crew _object) select {!alive _x};
        if (count _deadCrew == 0) exitWith { false };
        private _deadSide = [_deadCrew select 0] call _getConfigSide;
        if (_deadSide == civilian || _deadSide == sideUnknown || _deadSide == sideEmpty) exitWith { false };
        !([_deadSide] call _isFriendly)
    };

    case "empty_vehicles": {
        if (!alive _object) exitWith { false };
        private _aliveCrew = (crew _object) select {alive _x};
        count _aliveCrew == 0
    };

    case "dead_friendly_infantry": {
        if (alive _object) exitWith { false };
        private _unitSide = side group _object;
        if (_unitSide == sideUnknown) then {
            _unitSide = [_object] call _getConfigSide;
        };
        [_unitSide] call _isFriendly
    };

    case "dead_enemy_infantry": {
        if (alive _object) exitWith { false };
        private _unitSide = side group _object;
        if (_unitSide == sideUnknown) then {
            _unitSide = [_object] call _getConfigSide;
        };
        if (_unitSide == civilian || _unitSide == sideUnknown || _unitSide == sideEmpty) exitWith { false };
        !([_unitSide] call _isFriendly)
    };

    default { true };
};
