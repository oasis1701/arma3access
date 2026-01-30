/*
 * fn_resetAssets.sqf
 * Respawn dead friendly units and restore them to original positions
 *
 * Usage: [] call BA_fnc_resetAssets;
 *
 * Returns: NUMBER - Count of units respawned
 */

// Check if we have asset data
if (isNil "BA_assetOriginalData") exitWith {
    ["No asset data available. Run initDevSandbox first."] call BA_fnc_speak;
    0
};

private _respawnCount = 0;

// Process each asset group
{
    private _groupData = _x;
    private _grp = _groupData select 0;
    private _unitsData = _groupData select 1;

    // Check if group still exists, create new if needed
    if (isNull _grp || {count units _grp == 0}) then {
        // Group is empty or deleted, need to recreate
        _grp = createGroup [west, true];
        BA_assetOriginalData set [_forEachIndex, [_grp, _unitsData]];

        // Recreate all units
        {
            private _unitData = _x;
            _unitData params ["_type", "_pos", "_dir", "_assetType", "_wasInVehicle", "_vehType"];

            if (_wasInVehicle && _vehType != "") then {
                // Recreate vehicle with crew
                private _veh = createVehicle [_vehType, _pos, [], 0, "NONE"];
                _veh setDir _dir;
                if (_assetType != "") then {
                    _veh setVariable ["BA_assetType", _assetType];
                };

                // Create crew
                private _crew = createVehicleCrew _veh;
                (crew _veh) joinSilent _grp;

                _respawnCount = _respawnCount + count crew _veh;
            } else {
                // Recreate infantry unit
                private _unit = _grp createUnit [_type, _pos, [], 0, "FORM"];
                _unit setDir _dir;
                if (_assetType != "") then {
                    _unit setVariable ["BA_assetType", _assetType];
                };
                _respawnCount = _respawnCount + 1;
            };
        } forEach _unitsData;

        // Rejoin to player
        _grp join player;
    } else {
        // Group exists, check for dead units
        private _aliveUnits = units _grp select {alive _x};
        private _deadCount = (count _unitsData) - (count _aliveUnits);

        if (_deadCount > 0) then {
            // Delete dead bodies and respawn
            {
                if (!alive _x) then {
                    deleteVehicle _x;
                };
            } forEach units _grp;

            // Respawn missing units
            private _currentCount = count (units _grp select {alive _x});
            private _targetCount = count _unitsData;

            for "_i" from _currentCount to (_targetCount - 1) do {
                private _unitData = _unitsData select _i;
                _unitData params ["_type", "_pos", "_dir", "_assetType", "_wasInVehicle", "_vehType"];

                if (_wasInVehicle && _vehType != "") then {
                    // Find if vehicle still exists
                    private _existingVeh = objNull;
                    {
                        if (vehicle _x != _x && alive (vehicle _x)) exitWith {
                            _existingVeh = vehicle _x;
                        };
                    } forEach units _grp;

                    if (isNull _existingVeh) then {
                        // Recreate vehicle
                        private _veh = createVehicle [_vehType, _pos, [], 0, "NONE"];
                        _veh setDir _dir;
                        if (_assetType != "") then {
                            _veh setVariable ["BA_assetType", _assetType];
                        };
                        private _crew = createVehicleCrew _veh;
                        (crew _veh) joinSilent _grp;
                        _respawnCount = _respawnCount + count crew _veh;
                    };
                } else {
                    private _unit = _grp createUnit [_type, _pos, [], 0, "FORM"];
                    _unit setDir _dir;
                    if (_assetType != "") then {
                        _unit setVariable ["BA_assetType", _assetType];
                    };
                    _respawnCount = _respawnCount + 1;
                };
            };
        };
    };
} forEach BA_assetOriginalData;

// Update asset groups array
BA_assetGroups = [];
{
    private _grp = (_x select 0);
    if (!isNull _grp && {count units _grp > 0}) then {
        BA_assetGroups pushBack _grp;
    };
} forEach BA_assetOriginalData;

// Announce result
private _msg = "";
if (_respawnCount > 0) then {
    _msg = format["Reset complete. %1 units respawned", _respawnCount];
} else {
    _msg = "All units alive, no reset needed";
};

[_msg] call BA_fnc_speak;
systemChat _msg;

_respawnCount
