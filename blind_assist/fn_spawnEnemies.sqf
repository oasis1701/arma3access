/*
 * fn_spawnEnemies.sqf
 * Spawn enemy units at the designated enemy spawn zone
 *
 * Parameters:
 * 0: STRING - Type of enemies: "infantry", "armor", or "mixed"
 * 1: NUMBER - Count of units/vehicles to spawn
 *
 * Usage:
 * ["infantry", 6] call BA_fnc_spawnEnemies;
 * ["armor", 2] call BA_fnc_spawnEnemies;
 * ["mixed", 8] call BA_fnc_spawnEnemies;
 *
 * Returns: ARRAY - Spawned units
 */

params [
    ["_type", "infantry", [""]],
    ["_count", 6, [0]]
];

// Get spawn position
private _spawnPos = BA_enemySpawnPos;
if (isNil "_spawnPos" || {_spawnPos isEqualTo [0,0,0]}) then {
    _spawnPos = getMarkerPos "enemy_spawn_zone";
    if (_spawnPos isEqualTo [0,0,0]) then {
        _spawnPos = [2036, 0, 5990];
    };
};

private _spawned = [];
private _infantryCount = 0;
private _armorCount = 0;

// Infantry unit classes (CSAT)
private _infantryClasses = [
    "O_Soldier_SL_F",
    "O_Soldier_F",
    "O_Soldier_F",
    "O_Soldier_AR_F",
    "O_Soldier_GL_F",
    "O_Soldier_LAT_F",
    "O_medic_F",
    "O_soldier_M_F"
];

// Armor classes (CSAT)
private _armorClasses = [
    "O_APC_Tracked_02_cannon_F",  // BTR-K Kamysh
    "O_APC_Wheeled_02_rcws_v2_F", // MSE-3 Marid
    "O_MBT_02_cannon_F"           // T-100 Varsuk
];

switch (toLower _type) do {
    case "infantry": {
        // Spawn infantry group
        private _grp = createGroup [east, true];
        for "_i" from 1 to _count do {
            private _class = selectRandom _infantryClasses;
            private _pos = _spawnPos getPos [random 20, random 360];
            private _unit = _grp createUnit [_class, _pos, [], 0, "FORM"];
            _spawned pushBack _unit;
            _infantryCount = _infantryCount + 1;
        };
        _grp setBehaviour "COMBAT";
        _grp setCombatMode "RED";

        // Track enemies
        if (isNil "BA_spawnedEnemies") then { BA_spawnedEnemies = []; };
        BA_spawnedEnemies append _spawned;
    };

    case "armor": {
        // Spawn armored vehicles
        private _armorGroups = [];
        for "_i" from 1 to _count do {
            private _class = selectRandom _armorClasses;
            private _pos = _spawnPos getPos [30 + random 30, random 360];
            private _grp = createGroup [east, true];
            private _veh = createVehicle [_class, _pos, [], 0, "NONE"];
            _veh setDir (random 360);

            // Create crew
            private _crew = createVehicleCrew _veh;
            (crew _veh) joinSilent _grp;

            _armorGroups pushBack _grp;

            _spawned pushBack _veh;
            _spawned append (crew _veh);
            _armorCount = _armorCount + 1;

            // Track enemies
            if (isNil "BA_spawnedEnemies") then { BA_spawnedEnemies = []; };
            BA_spawnedEnemies pushBack _veh;
            BA_spawnedEnemies append (crew _veh);
        };

        // Set combat behavior AFTER all vehicles are spawned
        {
            _x setBehaviour "COMBAT";
            _x setCombatMode "RED";
        } forEach _armorGroups;
    };

    case "mixed": {
        // Split between infantry and armor
        private _infantryToSpawn = floor (_count * 0.7);
        private _armorToSpawn = ceil (_count * 0.3);
        if (_armorToSpawn < 1) then { _armorToSpawn = 1; _infantryToSpawn = _count - 1; };

        // Spawn infantry
        private _grp = createGroup [east, true];
        for "_i" from 1 to _infantryToSpawn do {
            private _class = selectRandom _infantryClasses;
            private _pos = _spawnPos getPos [random 20, random 360];
            private _unit = _grp createUnit [_class, _pos, [], 0, "FORM"];
            _spawned pushBack _unit;
            _infantryCount = _infantryCount + 1;
        };

        // Spawn armor (collect groups, set behavior later)
        private _armorGroups = [];
        for "_i" from 1 to _armorToSpawn do {
            private _class = selectRandom _armorClasses;
            private _pos = _spawnPos getPos [30 + random 30, random 360];
            private _vehGrp = createGroup [east, true];
            private _veh = createVehicle [_class, _pos, [], 0, "NONE"];
            _veh setDir (random 360);

            private _crew = createVehicleCrew _veh;
            (crew _veh) joinSilent _vehGrp;

            _armorGroups pushBack _vehGrp;

            _spawned pushBack _veh;
            _spawned append (crew _veh);
            _armorCount = _armorCount + 1;
        };

        // Set combat behavior AFTER all units are spawned
        _grp setBehaviour "COMBAT";
        _grp setCombatMode "RED";
        {
            _x setBehaviour "COMBAT";
            _x setCombatMode "RED";
        } forEach _armorGroups;

        // Track enemies
        if (isNil "BA_spawnedEnemies") then { BA_spawnedEnemies = []; };
        BA_spawnedEnemies append _spawned;
    };

    default {
        private _msg = format["Unknown enemy type: %1. Use infantry, armor, or mixed.", _type];
        [_msg] call BA_fnc_speak;
        systemChat _msg;
        _spawned
    };
};

// Build announcement message
private _msg = "";
if (_type == "mixed") then {
    _msg = format["Spawned %1 infantry and %2 armor enemies, 300 meters north", _infantryCount, _armorCount];
} else {
    if (_type == "infantry") then {
        _msg = format["Spawned %1 infantry enemies, 300 meters north", _infantryCount];
    } else {
        _msg = format["Spawned %1 armor enemies, 300 meters north", _armorCount];
    };
};

[_msg] call BA_fnc_speak;
systemChat _msg;

_spawned
