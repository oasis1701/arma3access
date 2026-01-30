/*
 * fn_initDevSandbox.sqf
 * Initialize the dev sandbox features for testing accessibility
 *
 * Sets up:
 * - Global references to all friendly assets
 * - Enemy tracking array
 * - Asset spawn positions for reset functionality
 * - Nearby asset announcement system
 *
 * Usage: [] call BA_fnc_initDevSandbox;
 */

// Only run on client
if (!hasInterface) exitWith {};

// Initialize global tracking arrays
BA_spawnedEnemies = [];
BA_assetGroups = [];
BA_assetOriginalData = [];

// Wait for all units to be initialized
sleep 0.5;

// Find and register all friendly groups (excluding player's group)
private _playerGroup = group player;
{
    private _grp = _x;
    if (side _grp == west && {_grp != _playerGroup} && {count units _grp > 0}) then {
        BA_assetGroups pushBack _grp;

        // Store original data for reset functionality
        private _grpData = [];
        {
            private _unit = _x;
            private _unitData = [
                typeOf _unit,
                getPosATL _unit,
                getDir _unit,
                _unit getVariable ["BA_assetType", ""],
                vehicle _unit != _unit,
                if (vehicle _unit != _unit) then {typeOf vehicle _unit} else {""}
            ];
            _grpData pushBack _unitData;
        } forEach units _grp;

        BA_assetOriginalData pushBack [_grp, _grpData];
    };
} forEach allGroups;

// Store enemy spawn position (from marker)
BA_enemySpawnPos = getMarkerPos "enemy_spawn_zone";
if (BA_enemySpawnPos isEqualTo [0,0,0]) then {
    // Fallback if marker doesn't exist - 300m north of player start
    BA_enemySpawnPos = [2036, 0, 5990];
};

// Track last announced asset to avoid spam
BA_lastAnnouncedAsset = objNull;

// Set up nearby asset announcement loop
[] spawn {
    while {true} do {
        sleep 1;

        // Only check if player is alive and on foot
        if (alive player && vehicle player == player) then {
            private _nearestAsset = objNull;
            private _nearestDist = 15; // Detection radius

            // Check all asset group leaders
            {
                private _grp = _x;
                private _leader = leader _grp;
                if (alive _leader) then {
                    private _dist = player distance _leader;
                    if (_dist < _nearestDist) then {
                        _nearestDist = _dist;
                        _nearestAsset = _leader;
                    };
                };

                // Also check vehicles in group
                {
                    private _veh = vehicle _x;
                    if (_veh != _x && alive _veh) then {
                        private _dist = player distance _veh;
                        if (_dist < _nearestDist) then {
                            _nearestDist = _dist;
                            _nearestAsset = _veh;
                        };
                    };
                } forEach units _grp;
            } forEach BA_assetGroups;

            // Announce if we found a new asset
            if (!isNull _nearestAsset && _nearestAsset != BA_lastAnnouncedAsset) then {
                [_nearestAsset] call BA_fnc_announceNearbyAsset;
                BA_lastAnnouncedAsset = _nearestAsset;
            };

            // Clear last announced if we moved away
            if (isNull _nearestAsset) then {
                BA_lastAnnouncedAsset = objNull;
            };
        };
    };
};

// Speak initialization complete
private _assetCount = count BA_assetGroups;
private _msg = format["Dev sandbox initialized. %1 asset groups available. Use Control Tab to cycle groups.", _assetCount];
[_msg] call BA_fnc_speak;
systemChat _msg;

// Hint with available commands
hint parseText format[
    "<t size='1.2'>Dev Sandbox Ready</t><br/><br/>" +
    "<t color='#88ff88'>%1 Asset Groups:</t><br/>" +
    "- 2 Infantry Squads<br/>" +
    "- Ghost Hawk Helicopter<br/>" +
    "- Wipeout Jet<br/>" +
    "- Marshall APC<br/>" +
    "- Mortar Team<br/><br/>" +
    "<t color='#ffff88'>Debug Console Commands:</t><br/>" +
    "[""infantry"", 6] call BA_fnc_spawnEnemies;<br/>" +
    "[""armor"", 2] call BA_fnc_spawnEnemies;<br/>" +
    "[""mixed"", 8] call BA_fnc_spawnEnemies;<br/>" +
    "[] call BA_fnc_clearEnemies;<br/>" +
    "[] call BA_fnc_resetAssets;",
    _assetCount
];

true
