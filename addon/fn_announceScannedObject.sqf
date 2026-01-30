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

// Special handling for Logistics category (containers, dropped equipment)
private _isContainer = false;
if (!isNil "BA_scannerCategoryIndex" && {BA_scannerCategoryIndex == 2}) then {
    private _weapons = weaponCargo _object;
    private _magazines = magazineCargo _object;
    private _items = itemCargo _object;
    private _backpacks = backpackCargo _object;

    private _totalCargo = count _weapons + count _magazines + count _items + count _backpacks;

    if (_totalCargo > 0) then {
        _isContainer = true;
        private _contents = [];

        // Weapons
        if (count _weapons > 0) then {
            if (count _weapons == 1) then {
                private _weaponName = getText (configFile >> "CfgWeapons" >> (_weapons select 0) >> "displayName");
                if (_weaponName == "") then { _weaponName = "weapon" };
                _contents pushBack _weaponName;
            } else {
                _contents pushBack format ["%1 weapons", count _weapons];
            };
        };

        // Magazines -> "ammo"
        if (count _magazines > 0) then {
            _contents pushBack "ammo";
        };

        // Items
        if (count _items > 0) then {
            _contents pushBack format ["%1 items", count _items];
        };

        // Backpacks
        if (count _backpacks > 0) then {
            if (count _backpacks == 1) then {
                _contents pushBack "backpack";
            } else {
                _contents pushBack format ["%1 backpacks", count _backpacks];
            };
        };

        _name = "Dropped: " + (_contents joinString ", ");
    } else {
        // Empty cargo but is a WeaponHolder type
        private _className = typeOf _object;
        if (_className find "WeaponHolder" >= 0) then {
            _isContainer = true;
            _name = "Dropped equipment";
        };
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

if (_isContainer) then {
    // Containers: no side info needed
    _announcement = format ["%1, %2 meters %3", _name, _distance, _direction];
} else {
    if (_isDead) then {
        private _deadPrefix = if (_object isKindOf "Man") then { "dead" } else { "destroyed" };
        _announcement = format ["%1 %2, %3 meters %4, %5", _deadPrefix, _name, _distance, _direction, _sideStatus];
    } else {
        _announcement = format ["%1, %2 meters %3, %4", _name, _distance, _direction, _sideStatus];
    };
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
