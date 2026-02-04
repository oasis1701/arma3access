/*
 * Function: BA_fnc_announceUnitStatus
 * Announces detailed status info about the observed unit.
 *
 * Hotkeys:
 *   Alt+1 = Health
 *   Alt+2 = Fatigue
 *   Alt+3 = Capability (can move/fire)
 *   Alt+4 = Suppression (under fire)
 *   Alt+5 = Enemies
 *   Alt+6 = Weapon and ammo
 *   Alt+7 = Morale
 *   Alt+8 = Position context
 *   Alt+9 = Role
 *   Alt+0 = Full summary
 *
 * Arguments:
 *   0: Category number (1-10, where 10 = 0 key = summary)
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [1] call BA_fnc_announceUnitStatus;
 */

params [["_category", 0, [0]]];

// Use observed unit if in observer mode, otherwise use player
private _unit = if (BA_observerMode) then { BA_observedUnit } else { player };
if (isNull _unit || !alive _unit) exitWith {
    ["No unit available"] call BA_fnc_speak;
};

private _announcement = "";

// Helper function to get health status
private _fnc_getHealth = {
    private _dmg = damage _unit;
    if (_dmg < 0.1) then { "Healthy" }
    else { if (_dmg < 0.4) then { "Lightly wounded" }
    else { if (_dmg < 0.75) then { "Wounded" }
    else { "Critically wounded" } } }
};

// Helper function to get fatigue status
private _fnc_getFatigue = {
    private _fat = getFatigue _unit;
    if (_fat < 0.3) then { "Fresh" }
    else { if (_fat < 0.7) then { "Tired" }
    else { "Exhausted" } }
};

// Helper function to get capability status
private _fnc_getCapability = {
    private _canMove = canMove _unit;
    private _canFire = canFire _unit;
    private _state = lifeState _unit;
    if (_state == "INCAPACITATED") then { "Incapacitated" }
    else { if (!_canMove && !_canFire) then { "Cannot move or fire" }
    else { if (!_canMove) then { "Cannot move" }
    else { if (!_canFire) then { "Cannot fire" }
    else { "Can move and fire" } } } }
};

// Helper function to get suppression status
private _fnc_getSuppression = {
    private _sup = getSuppression _unit;
    if (_sup < 0.1) then { "Not under fire" }
    else { if (_sup < 0.5) then { "Taking fire" }
    else { "Pinned down" } }
};

// Helper function to get enemy info using nearTargets
// Returns what this specific unit perceives about enemies
private _fnc_getEnemies = {
    // Get all targets within 2000m that this unit is aware of
    // Returns: [position, type, side, subjectiveCost, object, positionAccuracy]
    private _allTargets = _unit nearTargets 2000;

    // Filter for enemies (subjectiveCost > 0 means enemy)
    private _enemies = _allTargets select { (_x select 3) > 0 };

    if (count _enemies == 0) exitWith { "No known enemies" };

    // Sort by subjective cost (threat level) - highest threat first
    _enemies = [_enemies, [], {_x select 3}, "DESCEND"] call BIS_fnc_sortBy;

    private _count = count _enemies;
    private _announcements = [];

    {
        _x params ["_perceivedPos", "_perceivedType", "_perceivedSide", "_cost", "_object", "_accuracy"];

        // Calculate distance and bearing to perceived position
        private _dist = round (_unit distance _perceivedPos);
        private _bearing = _unit getDir _perceivedPos;
        private _dir = [_bearing] call BA_fnc_bearingToCompass;

        // Get display name from the perceived type (class name)
        // The type is what the unit recognized - could be specific or vague
        private _typeName = getText (configFile >> "CfgVehicles" >> _perceivedType >> "displayName");
        if (_typeName == "") then { _typeName = _perceivedType };

        // Add accuracy qualifier if position is uncertain (accuracy > 50 means less certain)
        private _prefix = if (_accuracy > 50) then { "Approximately " } else { "" };

        _announcements pushBack format["%1%2, %3 meters %4", _prefix, _typeName, _dist, _dir];
    } forEach _enemies;

    // Build final announcement
    private _intro = if (_count == 1) then { "" } else { format["%1 enemies. ", _count] };
    _intro + (_announcements joinString ". ")
};

// Helper function to get weapon info
private _fnc_getWeapon = {
    private _weapon = currentWeapon _unit;
    if (_weapon == "") then { "Unarmed" }
    else {
        private _weaponName = getText (configFile >> "CfgWeapons" >> _weapon >> "displayName");
        private _ammoCount = _unit ammo _weapon;
        private _ammoStatus = if (_ammoCount == 0) then { "empty" }
            else { if (_ammoCount < 10) then { format["%1 rounds, low", _ammoCount] }
            else { format["%1 rounds", _ammoCount] } };
        format["%1, %2", _weaponName, _ammoStatus]
    }
};

// Helper function to get morale status
private _fnc_getMorale = {
    if (fleeing _unit) then { "Fleeing" } else { "Steady" }
};

// Helper function to get position context
private _fnc_getPosition = {
    if (vehicle _unit != _unit) then {
        private _veh = vehicle _unit;
        private _vehName = getText (configFile >> "CfgVehicles" >> typeOf _veh >> "displayName");
        format["In %1", _vehName]
    } else {
        private _nearBldg = nearestBuilding _unit;
        private _inBldg = !isNull _nearBldg && {_unit distance _nearBldg < 5};
        private _unitPos = getPos _unit;
        private _swimming = surfaceIsWater _unitPos && {(stance _unit) in ["UNDEFINED", ""]};
        if (_inBldg) then { "Inside building" }
        else { if (_swimming) then { "Swimming" }
        else { "Open ground" } }
    }
};

// Helper function to get role
private _fnc_getRole = {
    private _isLeader = _unit == leader group _unit;
    private _hasMedikit = "Medikit" in items _unit;
    private _hasToolkit = "ToolKit" in items _unit;
    private _hasLauncher = secondaryWeapon _unit != "";
    if (_isLeader) then { "Squad leader" }
    else { if (_hasMedikit) then { "Medic" }
    else { if (_hasToolkit) then { "Engineer" }
    else { if (_hasLauncher) then { "AT/AA specialist" }
    else { "Rifleman" } } } }
};

switch (_category) do {
    // Alt+1: Health
    case 1: {
        _announcement = call _fnc_getHealth;
    };

    // Alt+2: Fatigue
    case 2: {
        _announcement = call _fnc_getFatigue;
    };

    // Alt+3: Capability
    case 3: {
        _announcement = call _fnc_getCapability;
    };

    // Alt+4: Suppression
    case 4: {
        _announcement = call _fnc_getSuppression;
    };

    // Alt+5: Enemies
    case 5: {
        _announcement = call _fnc_getEnemies;
    };

    // Alt+6: Weapon
    case 6: {
        _announcement = call _fnc_getWeapon;
    };

    // Alt+7: Morale
    case 7: {
        _announcement = call _fnc_getMorale;
    };

    // Alt+8: Position
    case 8: {
        _announcement = call _fnc_getPosition;
    };

    // Alt+9: Role
    case 9: {
        _announcement = call _fnc_getRole;
    };

    // Alt+0: Summary (combines health, fatigue, suppression, position)
    case 10: {
        private _health = call _fnc_getHealth;
        private _fatigue = call _fnc_getFatigue;
        private _suppression = call _fnc_getSuppression;
        private _position = call _fnc_getPosition;
        _announcement = format["%1. %2. %3. %4", _health, _fatigue, _suppression, _position];
    };

    default {
        _announcement = "Invalid status category";
    };
};

[_announcement] call BA_fnc_speak;
