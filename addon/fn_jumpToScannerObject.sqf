/*
 * Function: BA_fnc_jumpToScannerObject
 * Moves the cursor to the currently selected scanner object.
 * Announces "Jumped to [name]" after moving.
 *
 * Arguments:
 *   None (uses global state variables)
 *
 * Return Value:
 *   Boolean - true if jump was successful
 *
 * Example:
 *   [] call BA_fnc_jumpToScannerObject;
 */

// Must be in observer mode with active cursor
if (!BA_observerMode || !BA_cursorActive) exitWith {
    ["Cursor not active."] call BA_fnc_speak;
    false
};

// Check if we have objects
if (count BA_scannedObjects == 0) exitWith {
    ["No object selected."] call BA_fnc_speak;
    false
};

// Get current object
private _object = BA_scannedObjects select BA_scannerObjectIndex;

if (isNull _object) exitWith {
    ["Object no longer exists."] call BA_fnc_speak;
    false
};

// Get object position
private _objectPos = getPos _object;

// Get object name for announcement
private _name = "";
private _isDead = false;

if (_object isKindOf "Man") then {
    if (!alive _object) then {
        _isDead = true;
    };
    _name = getText (configFile >> "CfgVehicles" >> typeOf _object >> "displayName");
    if (_name == "") then {
        _name = name _object;
    };
    if (_name == "") then {
        _name = typeOf _object;
    };
} else {
    _name = getText (configFile >> "CfgVehicles" >> typeOf _object >> "displayName");
    if (_name == "") then {
        _name = typeOf _object;
    };
};

// Clear road state since cursor is leaving the road
BA_currentRoad = objNull;
BA_atRoadEnd = false;
BA_lastTravelDirection = "";

// Move cursor to object position (without announcement from setCursorPos)
BA_cursorPos = [_objectPos select 0, _objectPos select 1, getTerrainHeightASL [_objectPos select 0, _objectPos select 1]];

// Announce the jump
if (_isDead) then {
    [format ["Jumped to dead %1.", _name]] call BA_fnc_speak;
} else {
    [format ["Jumped to %1.", _name]] call BA_fnc_speak;
};

// Refresh scanner objects from new cursor position
[] call BA_fnc_scanObjects;

true
