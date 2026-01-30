/*
 * fn_clearEnemies.sqf
 * Remove all spawned enemies from the battlefield
 *
 * Usage: [] call BA_fnc_clearEnemies;
 *
 * Returns: NUMBER - Count of enemies cleared
 */

// Initialize if needed
if (isNil "BA_spawnedEnemies") then { BA_spawnedEnemies = []; };

private _count = 0;
private _groupsToDelete = [];

// Delete all tracked enemies
{
    private _entity = _x;
    if (!isNull _entity) then {
        // Track groups for deletion
        if (_entity isKindOf "Man") then {
            private _grp = group _entity;
            if (!isNull _grp && {!(_grp in _groupsToDelete)}) then {
                _groupsToDelete pushBack _grp;
            };
        };

        // If it's a vehicle, delete crew first
        if (_entity isKindOf "LandVehicle" || _entity isKindOf "Air") then {
            {
                private _grp = group _x;
                if (!isNull _grp && {!(_grp in _groupsToDelete)}) then {
                    _groupsToDelete pushBack _grp;
                };
                deleteVehicle _x;
            } forEach crew _entity;
        };

        deleteVehicle _entity;
        _count = _count + 1;
    };
} forEach BA_spawnedEnemies;

// Delete empty groups
{
    if (count units _x == 0) then {
        deleteGroup _x;
    };
} forEach _groupsToDelete;

// Also clean up any remaining OPFOR units that might have been missed
{
    if (side _x == east && {!(_x in BA_spawnedEnemies)}) then {
        private _grp = group _x;
        if (!isNull _grp && {!(_grp in _groupsToDelete)}) then {
            _groupsToDelete pushBack _grp;
        };
        deleteVehicle _x;
        _count = _count + 1;
    };
} forEach allUnits;

// Final group cleanup
{
    if (count units _x == 0) then {
        deleteGroup _x;
    };
} forEach allGroups;

// Clear tracking array
BA_spawnedEnemies = [];

// Announce
private _msg = "";
if (_count > 0) then {
    _msg = format["Cleared %1 enemies", _count];
} else {
    _msg = "No enemies to clear";
};

[_msg] call BA_fnc_speak;
systemChat _msg;

_count
