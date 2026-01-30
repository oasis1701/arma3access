/*
 * Function: BA_fnc_announceScannedObject
 * Announces details about the currently selected scanned object.
 * Format: "Name, distance meters direction, side/status"
 *
 * Arguments:
 *   None (uses global state variables)
 *
 * Return Value:
 *   Boolean - true if announcement was made
 *
 * Example:
 *   [] call BA_fnc_announceScannedObject;
 */

// Check if we have objects to announce
if (count BA_scannedObjects == 0) exitWith {
    ["No objects found."] call BA_fnc_speak;
    false
};

// Get current object
private _object = BA_scannedObjects select BA_scannerObjectIndex;

if (isNull _object) exitWith {
    ["Object no longer exists."] call BA_fnc_speak;
    false
};

// Get cursor position for distance/bearing calculation
private _cursorPos = if (!isNil "BA_cursorPos") then { BA_cursorPos } else { getPos player };

// Calculate distance from cursor
private _distance = round (_object distance _cursorPos);

// Calculate bearing from cursor to object
private _objectPos = getPos _object;
private _dx = (_objectPos select 0) - (_cursorPos select 0);
private _dy = (_objectPos select 1) - (_cursorPos select 1);
private _bearing = (_dx atan2 _dy);
if (_bearing < 0) then { _bearing = _bearing + 360 };

// Convert bearing to compass direction
private _direction = [_bearing] call BA_fnc_bearingToCompass;

// Get object name
private _name = "";
private _isDead = false;

// Check if it's a unit (person)
if (_object isKindOf "Man") then {
    // Check if dead
    if (!alive _object) then {
        _isDead = true;
    };

    // Get display name
    _name = getText (configFile >> "CfgVehicles" >> typeOf _object >> "displayName");
    if (_name == "") then {
        _name = name _object;
    };
    if (_name == "") then {
        _name = typeOf _object;
    };
} else {
    // For vehicles and other objects
    if (!alive _object) then {
        _isDead = true;
    };
    _name = getText (configFile >> "CfgVehicles" >> typeOf _object >> "displayName");
    if (_name == "") then {
        _name = typeOf _object;
    };
};

// Get side/status [sideName, relation]
private _sideInfo = [_object] call BA_fnc_getObjectSide;
_sideInfo params ["_sideName", "_relation"];

// Format side status: "OPFOR enemy", "BLUFOR friendly", etc.
private _sideStatus = if (_sideName == "") then {
    _relation
} else {
    if (_relation in ["empty", "unknown"]) then {
        _relation
    } else {
        format ["%1 %2", _sideName, _relation]
    }
};

// Build announcement
private _announcement = "";

// Add "dead" prefix for dead units, "destroyed" for vehicles
if (_isDead) then {
    private _deadPrefix = if (_object isKindOf "Man") then { "dead" } else { "destroyed" };
    _announcement = format ["%1 %2, %3 meters %4, %5", _deadPrefix, _name, _distance, _direction, _sideStatus];
} else {
    _announcement = format ["%1, %2 meters %3, %4", _name, _distance, _direction, _sideStatus];
};

// Speak the announcement
[_announcement] call BA_fnc_speak;

// Debug mode: also announce the class type via NVDA
if (!isNil "BA_scannerDebug" && {BA_scannerDebug}) then {
    private _className = typeOf _object;
    systemChat format ["DEBUG: %1 | Class: %2", _name, _className];
    // Speak class name after a short delay so it doesn't overlap
    [_className] spawn {
        params ["_class"];
        sleep 1.5;
        [format ["Class: %1", _class]] call BA_fnc_speak;
    };
};

true
