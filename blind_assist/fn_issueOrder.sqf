/*
 * Function: BA_fnc_issueOrder
 * Executes an Arma 3 command based on order type.
 *
 * Uses BA_cursorPos as target position and BA_observedUnit as the unit.
 *
 * Arguments:
 *   0: Order type string <STRING>
 *   1: Order label for announcement <STRING>
 *   2: Target unit for individual orders (optional) <OBJECT>
 *
 * Return Value:
 *   None
 *
 * Example:
 *   ["move", "Move"] call BA_fnc_issueOrder;
 *   ["move", "Move", _specificUnit] call BA_fnc_issueOrder;
 */

params [["_orderType", "", [""]], ["_label", "", [""]], ["_targetUnit", objNull, [objNull]]];
private _isUnitOrder = !isNull _targetUnit;

// Debug helper
private _debug = {
    if (BA_debugMode) then {
        systemChat ("DEBUG: " + _this);
    };
};

format["issueOrder called: %1 (%2)", _label, _orderType] call _debug;

if (_orderType == "") exitWith {
    ["No order specified"] call BA_fnc_speak;
};

// Get target position and unit
private _targetPos = BA_cursorPos;
private _unit = if (BA_observerMode) then { BA_observedUnit } else { player };

format["cursorPos=%1, unit=%2", _targetPos, _unit] call _debug;

if (isNull _unit) exitWith {
    ["No unit selected"] call BA_fnc_speak;
};

if (isNil "_targetPos") exitWith {
    ["No cursor position set"] call BA_fnc_speak;
};
if (_targetPos isEqualTo []) exitWith {
    ["No cursor position set"] call BA_fnc_speak;
};

// Get the group - use selected order group if set, otherwise observed unit's group
private _group = group _unit;
if (!isNil "BA_selectedOrderGroup") then {
    if (!isNull BA_selectedOrderGroup) then {
        private _aliveUnits = units BA_selectedOrderGroup;
        private _hasAlive = false;
        {
            if (alive _x) exitWith { _hasAlive = true; };
        } forEach _aliveUnits;
        if (_hasAlive) then {
            _group = BA_selectedOrderGroup;
        };
    };
};

// Get the vehicle from the group leader (handles both Ctrl+Tab and G key selection)
// For unit orders, also get vehicle from the target unit
private _groupLeader = leader _group;
private _vehicle = vehicle _groupLeader;
if (_isUnitOrder) then {
    private _unitVeh = vehicle _targetUnit;
    if (_unitVeh != _targetUnit) then { _vehicle = _unitVeh };
};


// Get grid reference for announcement
private _gridInfo = [_targetPos] call BA_fnc_getGridInfo;
format["gridInfo=%1", _gridInfo] call _debug;

// Execute command based on type
switch (_orderType) do {

    // ========== INFANTRY COMMANDS (WORKING) ==========

    case "move": {
        if (_isUnitOrder) then {
            _targetUnit doMove _targetPos;
        } else {
            _group move _targetPos;
            _group setBehaviour "AWARE";
            _group setSpeedMode "NORMAL";
        };
    };

    case "sneak": {
        if (_isUnitOrder) then {
            _targetUnit doMove _targetPos;
            _targetUnit setUnitPos "MIDDLE";
            _targetUnit setSpeedMode "LIMITED";
        } else {
            _group move _targetPos;
            _group setBehaviour "STEALTH";
            _group setSpeedMode "LIMITED";
        };
    };

    case "assault": {
        if (_isUnitOrder) then {
            _targetUnit doMove _targetPos;
            _targetUnit setCombatMode "RED";
        } else {
            _group move _targetPos;
            _group setBehaviour "COMBAT";
            _group setCombatMode "RED";
        };
    };

    case "garrison": {
        private _buildings = nearestObjects [_targetPos, ["Building", "House"], 100];
        if (count _buildings > 0) then {
            private _building = _buildings select 0;
            if (_isUnitOrder) then {
                _targetUnit doMove (getPos _building);
            } else {
                _group move (getPos _building);
                if (!isNil "BIS_fnc_taskDefend") then {
                    [_group, _building] call BIS_fnc_taskDefend;
                };
            };
            private _dist = round (_targetPos distance _building);
            [format["Garrisoning building %1 meters from cursor", _dist]] call BA_fnc_speak;
        } else {
            ["No building found near cursor"] call BA_fnc_speak;
        };
    };

    case "sweep": {
        if (_isUnitOrder) then {
            _targetUnit doMove _targetPos;
            _targetUnit setCombatMode "RED";
        } else {
            private _wp = _group addWaypoint [_targetPos, 0];
            _wp setWaypointType "SAD";
            _wp setWaypointBehaviour "COMBAT";
            _wp setWaypointCombatMode "RED";
            _group setCurrentWaypoint _wp;
        };
    };

    case "heal": {
        if (_isUnitOrder) then {
            if (damage _targetUnit > 0.1 && "FirstAidKit" in items _targetUnit) then {
                _targetUnit action ["HealSelf", _targetUnit];
                [format["%1 using first aid kit", name _targetUnit]] call BA_fnc_speak;
            } else {
                if ("Medikit" in items _targetUnit) then {
                    // This unit is a medic - find most injured squad mate
                    private _mostInjured = objNull;
                    private _maxDamage = 0;
                    {
                        if (damage _x > _maxDamage && alive _x) then {
                            _maxDamage = damage _x;
                            _mostInjured = _x;
                        };
                    } forEach units _group;
                    if (!isNull _mostInjured && _maxDamage > 0.1) then {
                        _targetUnit action ["Heal", _mostInjured];
                        [format["%1 healing %2", name _targetUnit, name _mostInjured]] call BA_fnc_speak;
                    } else {
                        ["No one needs healing"] call BA_fnc_speak;
                    };
                } else {
                    [format["%1 has no medical supplies", name _targetUnit]] call BA_fnc_speak;
                };
            };
        } else {
            private _units = units _group;
            private _medic = objNull;
            private _mostInjured = objNull;
            private _maxDamage = 0;

            {
                if ("Medikit" in items _x) then { _medic = _x; };
                if (damage _x > _maxDamage && alive _x) then {
                    _maxDamage = damage _x;
                    _mostInjured = _x;
                };
            } forEach _units;

            if (!isNull _medic && !isNull _mostInjured && _maxDamage > 0.1) then {
                _medic action ["Heal", _mostInjured];
                [format["Medic healing %1", name _mostInjured]] call BA_fnc_speak;
            } else {
                {
                    if (damage _x > 0.1 && "FirstAidKit" in items _x) then {
                        _x action ["HealSelf", _x];
                    };
                } forEach _units;
                ["Squad using first aid kits"] call BA_fnc_speak;
            };
        };
    };

    case "regroup": {
        if (_isUnitOrder) then {
            _targetUnit commandFollow (leader _group);
            _targetUnit setUnitPos "AUTO";
            [format["%1 regrouping on leader", name _targetUnit]] call BA_fnc_speak;
        } else {
            private _leader = leader _group;
            {
                _x commandFollow _leader;
                _x setUnitPos "AUTO";
                _x setBehaviour "AWARE";
            } forEach units _group;
            _group setSpeedMode "NORMAL";
            ["Squad regrouping on leader"] call BA_fnc_speak;
        };
    };

    case "find_cover": {
        if (_isUnitOrder) then {
            private _coverObjects = nearestTerrainObjects [getPos _targetUnit, ["TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS", "WALL", "FENCE"], 50];
            if (count _coverObjects > 0) then {
                private _cover = _coverObjects select 0;
                _targetUnit doMove (getPos _cover);
                _targetUnit setUnitPos "MIDDLE";
            } else {
                _targetUnit setUnitPos "DOWN";
            };
            [format["%1 finding cover", name _targetUnit]] call BA_fnc_speak;
        } else {
            _group setBehaviour "COMBAT";
            _group setSpeedMode "FULL";

            {
                private _unit = _x;
                private _coverObjects = nearestTerrainObjects [getPos _unit, ["TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS", "WALL", "FENCE"], 50];

                if (count _coverObjects > 0) then {
                    private _cover = _coverObjects select 0;
                    _unit doMove (getPos _cover);
                    _unit setUnitPos "MIDDLE";
                } else {
                    _unit setUnitPos "DOWN";
                };
            } forEach units _group;

            ["Squad scattering to cover"] call BA_fnc_speak;
        };
    };

    case "hold_fire": {
        if (_isUnitOrder) then {
            _targetUnit setCombatMode "BLUE";
        } else {
            _group setCombatMode "BLUE";
        };
    };

    case "fire_at_will": {
        if (_isUnitOrder) then {
            _targetUnit setCombatMode "RED";
        } else {
            _group setCombatMode "RED";
        };
    };

    // ========== GROUP-WIDE COMMANDS ==========

    case "stop_all": {
        commandStop (units _group);
        ["All units stopping"] call BA_fnc_speak;
    };

    // ========== VEHICLE COMMANDS ==========

    case "dismount_all": {
        private _mounted = (units _group) select { vehicle _x != _x };
        if (count _mounted > 0) then {
            // In observer mode, AI isn't under player command so prevent re-entry
            if (BA_observerMode) then {
                { _x orderGetIn false } forEach _mounted;
            };
            commandGetOut _mounted;
            if (BA_observerMode) then {
                // Re-allow boarding after 30s so future mount orders work
                [_mounted] spawn {
                    params ["_units"];
                    sleep 30;
                    { _x orderGetIn true } forEach _units;
                };
            };
        };
        ["All units dismounting"] call BA_fnc_speak;
    };

    case "vehicle_move": {
        if (_isUnitOrder) then {
            // commandMove on the driver — works whether player is inside or outside the vehicle
            private _vehDriver = driver (vehicle _targetUnit);
            if (!isNull _vehDriver) then {
                _vehDriver commandMove _targetPos;
            } else {
                ["No driver in vehicle"] call BA_fnc_speak;
            };
        } else {
            // Observer mode: move the entire group (intended behavior)
            private _vehDriver = driver _vehicle;
            if (!isNull _vehDriver) then {
                _group move _targetPos;
            } else {
                ["No driver in vehicle"] call BA_fnc_speak;
            };
        };
    };

    // ========== HELICOPTER COMMANDS ==========

    case "heli_move": {
        // Clear any existing waypoints (including loiter)
        while {count waypoints _group > 0} do {
            deleteWaypoint [_group, 0];
        };
        private _flyHeight = _vehicle getVariable ["BA_flyHeight", 150];
        if (_flyHeight < 30) then { _flyHeight = 150; };
        _vehicle flyInHeight _flyHeight;
        if (_isUnitOrder) then {
            _targetUnit doMove _targetPos;
        } else {
            _group move _targetPos;
        };
        _group setBehaviour "AWARE";
        _group setCombatMode "RED";
        _group setSpeedMode "NORMAL";
    };

    case "heli_land": {
        // Clear any existing waypoints
        while {count waypoints _group > 0} do {
            deleteWaypoint [_group, 0];
        };
        _vehicle setVariable ["BA_flyHeight", 0];
        _group setBehaviour "CARELESS";
        // Move to target position, then land when waypoint reached
        private _wp = _group addWaypoint [_targetPos, 50];
        _wp setWaypointType "MOVE";
        _wp setWaypointStatements ["true", "(vehicle this) land 'LAND'"];
        _group setCurrentWaypoint _wp;
    };

    case "heli_stop": {
        // Clear waypoints and hover
        while {count waypoints _group > 0} do {
            deleteWaypoint [_group, 0];
        };
        _group move (getPos _vehicle);
        _group setBehaviour "AWARE";
        private _flyHeight = _vehicle getVariable ["BA_flyHeight", 150];
        if (_flyHeight < 30) then { _flyHeight = 150; };
        _vehicle flyInHeight _flyHeight;
        ["Helicopter holding position"] call BA_fnc_speak;
    };

    case "heli_alt_50": {
        // Clear any existing waypoints (including loiter)
        while {count waypoints _group > 0} do {
            deleteWaypoint [_group, 0];
        };
        _vehicle flyInHeight 50;
        _vehicle setVariable ["BA_flyHeight", 50];
        _group setBehaviour "AWARE";
        ["Altitude set to 50 meters"] call BA_fnc_speak;
    };

    case "heli_alt_150": {
        // Clear any existing waypoints (including loiter)
        while {count waypoints _group > 0} do {
            deleteWaypoint [_group, 0];
        };
        _vehicle flyInHeight 150;
        _vehicle setVariable ["BA_flyHeight", 150];
        _group setBehaviour "AWARE";
        ["Altitude set to 150 meters"] call BA_fnc_speak;
    };

    case "heli_alt_300": {
        // Clear any existing waypoints (including loiter)
        while {count waypoints _group > 0} do {
            deleteWaypoint [_group, 0];
        };
        _vehicle flyInHeight 300;
        _vehicle setVariable ["BA_flyHeight", 300];
        _group setBehaviour "AWARE";
        ["Altitude set to 300 meters"] call BA_fnc_speak;
    };

    case "heli_loiter_300": {
        while {count waypoints _group > 0} do {
            deleteWaypoint [_group, 0];
        };
        private _flyHeight = _vehicle getVariable ["BA_flyHeight", 150];
        if (_flyHeight < 30) then { _flyHeight = 150; };
        _vehicle flyInHeight _flyHeight;
        _group setBehaviour "AWARE";
        _group setCombatMode "RED";
        private _wp = _group addWaypoint [_targetPos, 0];
        _wp setWaypointType "LOITER";
        _wp setWaypointLoiterRadius 300;
        _wp setWaypointLoiterType "CIRCLE_L";
        _group setCurrentWaypoint _wp;
    };

    case "heli_loiter_600": {
        while {count waypoints _group > 0} do {
            deleteWaypoint [_group, 0];
        };
        private _flyHeight = _vehicle getVariable ["BA_flyHeight", 150];
        if (_flyHeight < 30) then { _flyHeight = 150; };
        _vehicle flyInHeight _flyHeight;
        _group setBehaviour "AWARE";
        _group setCombatMode "RED";
        private _wp = _group addWaypoint [_targetPos, 0];
        _wp setWaypointType "LOITER";
        _wp setWaypointLoiterRadius 600;
        _wp setWaypointLoiterType "CIRCLE_L";
        _group setCurrentWaypoint _wp;
    };

    case "heli_loiter_900": {
        while {count waypoints _group > 0} do {
            deleteWaypoint [_group, 0];
        };
        private _flyHeight = _vehicle getVariable ["BA_flyHeight", 150];
        if (_flyHeight < 30) then { _flyHeight = 150; };
        _vehicle flyInHeight _flyHeight;
        _group setBehaviour "AWARE";
        _group setCombatMode "RED";
        private _wp = _group addWaypoint [_targetPos, 0];
        _wp setWaypointType "LOITER";
        _wp setWaypointLoiterRadius 900;
        _wp setWaypointLoiterType "CIRCLE_L";
        _group setCurrentWaypoint _wp;
    };

    case "heli_defend": {
        // Defend current position - engage enemies in the area
        while {count waypoints _group > 0} do {
            deleteWaypoint [_group, 0];
        };
        private _flyHeight = _vehicle getVariable ["BA_flyHeight", 150];
        if (_flyHeight < 30) then { _flyHeight = 150; };
        _vehicle flyInHeight _flyHeight;
        _group setBehaviour "AWARE";
        _group setCombatMode "RED";
        // SAD waypoint at current position - helicopter defends this area
        private _wp = _group addWaypoint [getPos _vehicle, 0];
        _wp setWaypointType "SAD";
        _group setCurrentWaypoint _wp;
        ["Helicopter defending position"] call BA_fnc_speak;
    };

    case "heli_attack_area": {
        // Attack targets near cursor, stay in area
        while {count waypoints _group > 0} do {
            deleteWaypoint [_group, 0];
        };
        private _flyHeight = _vehicle getVariable ["BA_flyHeight", 150];
        if (_flyHeight < 30) then { _flyHeight = 150; };
        _vehicle flyInHeight _flyHeight;
        _group setBehaviour "AWARE";
        _group setCombatMode "RED";
        // SAD waypoint at cursor - helicopter attacks this area
        private _wp = _group addWaypoint [_targetPos, 0];
        _wp setWaypointType "SAD";
        _group setCurrentWaypoint _wp;
    };

    case "heli_strafe": {
        // Strafe run: fly THROUGH target area, then return
        private _startPos = getPos _vehicle;
        private _flyHeight = _vehicle getVariable ["BA_flyHeight", 150];
        if (_flyHeight < 30) then { _flyHeight = 150; };

        // Calculate direction from heli to target
        private _dir = _vehicle getDir _targetPos;

        // Calculate fly-through point 500m past target
        private _flyThroughPos = [
            (_targetPos select 0) + (sin _dir * 500),
            (_targetPos select 1) + (cos _dir * 500),
            0
        ];

        while {count waypoints _group > 0} do {
            deleteWaypoint [_group, 0];
        };

        _vehicle flyInHeight _flyHeight;
        _group setBehaviour "AWARE";
        _group setCombatMode "RED";
        _group setSpeedMode "FULL";

        // Attack waypoint - fly through target area at speed
        private _wp1 = _group addWaypoint [_flyThroughPos, 0];
        _wp1 setWaypointType "SAD";
        _wp1 setWaypointCompletionRadius 50;

        // Return waypoint
        private _wp2 = _group addWaypoint [_startPos, 0];
        _wp2 setWaypointType "MOVE";

        _group setCurrentWaypoint _wp1;
        ["Strafing target, will return after"] call BA_fnc_speak;
    };

    // ========== JET COMMANDS ==========

    case "jet_move": {
        while {count waypoints _group > 0} do { deleteWaypoint [_group, 0]; };

        private _altitude = _vehicle getVariable ["BA_jetAltitude", 500];
        _vehicle flyInHeightASL [_altitude, _altitude, _altitude];

        if (_isUnitOrder) then {
            _targetUnit doMove _targetPos;
        } else {
            _group move _targetPos;
        };
        _group setBehaviour "AWARE";
        _group setCombatMode "RED";
        _group setSpeedMode "FULL";
    };

    case "jet_patrol_small": {
        while {count waypoints _group > 0} do { deleteWaypoint [_group, 0]; };

        private _altitude = _vehicle getVariable ["BA_jetAltitude", 500];
        _vehicle flyInHeightASL [_altitude, _altitude, _altitude];

        private _radius = 1000;

        // Create 3 random SAD waypoints within radius (Rydygier's approach)
        for "_i" from 1 to 3 do {
            private _angle = random 360;
            private _dist = _radius * sqrt(random 1);
            private _wpPos = _targetPos getPos [_dist, _angle];
            _wpPos set [2, _altitude];

            private _wp = _group addWaypoint [_wpPos, 0];
            _wp setWaypointType "SAD";
        };

        // CYCLE waypoint to loop patrol
        private _wpCycle = _group addWaypoint [_targetPos, 0];
        _wpCycle setWaypointType "CYCLE";

        _group setCurrentWaypoint (waypoints _group select 0);

        // Reveal enemies in patrol area to aircraft group (aircraft can't perceive ground targets from altitude)
        [_group, _targetPos, _radius] spawn {
            params ["_grp", "_center", "_rad"];
            while {count units _grp > 0} do {
                {
                    if (side _x != side _grp && _x distance2D _center < _rad) then {
                        _grp reveal [_x, 4];
                    };
                } forEach allUnits;
                sleep 10;
            };
        };

        ["Jet patrolling 1 kilometer area"] call BA_fnc_speak;
    };

    case "jet_patrol_med": {
        while {count waypoints _group > 0} do { deleteWaypoint [_group, 0]; };

        private _altitude = _vehicle getVariable ["BA_jetAltitude", 500];
        _vehicle flyInHeightASL [_altitude, _altitude, _altitude];

        private _radius = 2000;

        // Create 3 random SAD waypoints within radius (Rydygier's approach)
        for "_i" from 1 to 3 do {
            private _angle = random 360;
            private _dist = _radius * sqrt(random 1);
            private _wpPos = _targetPos getPos [_dist, _angle];
            _wpPos set [2, _altitude];

            private _wp = _group addWaypoint [_wpPos, 0];
            _wp setWaypointType "SAD";
        };

        // CYCLE waypoint to loop patrol
        private _wpCycle = _group addWaypoint [_targetPos, 0];
        _wpCycle setWaypointType "CYCLE";

        _group setCurrentWaypoint (waypoints _group select 0);

        // Reveal enemies in patrol area to aircraft group (aircraft can't perceive ground targets from altitude)
        [_group, _targetPos, _radius] spawn {
            params ["_grp", "_center", "_rad"];
            while {count units _grp > 0} do {
                {
                    if (side _x != side _grp && _x distance2D _center < _rad) then {
                        _grp reveal [_x, 4];
                    };
                } forEach allUnits;
                sleep 10;
            };
        };

        ["Jet patrolling 2 kilometer area"] call BA_fnc_speak;
    };

    case "jet_patrol_large": {
        while {count waypoints _group > 0} do { deleteWaypoint [_group, 0]; };

        private _altitude = _vehicle getVariable ["BA_jetAltitude", 500];
        _vehicle flyInHeightASL [_altitude, _altitude, _altitude];

        private _radius = 4000;

        // Create 3 random SAD waypoints within radius (Rydygier's approach)
        for "_i" from 1 to 3 do {
            private _angle = random 360;
            private _dist = _radius * sqrt(random 1);
            private _wpPos = _targetPos getPos [_dist, _angle];
            _wpPos set [2, _altitude];

            private _wp = _group addWaypoint [_wpPos, 0];
            _wp setWaypointType "SAD";
        };

        // CYCLE waypoint to loop patrol
        private _wpCycle = _group addWaypoint [_targetPos, 0];
        _wpCycle setWaypointType "CYCLE";

        _group setCurrentWaypoint (waypoints _group select 0);

        // Reveal enemies in patrol area to aircraft group (aircraft can't perceive ground targets from altitude)
        [_group, _targetPos, _radius] spawn {
            params ["_grp", "_center", "_rad"];
            while {count units _grp > 0} do {
                {
                    if (side _x != side _grp && _x distance2D _center < _rad) then {
                        _grp reveal [_x, 4];
                    };
                } forEach allUnits;
                sleep 10;
            };
        };

        ["Jet patrolling 4 kilometer area"] call BA_fnc_speak;
    };

    case "jet_strike": {
        while {count waypoints _group > 0} do { deleteWaypoint [_group, 0]; };

        // Create invisible target at cursor
        private _targetType = if (side _group == west) then {"LaserTargetW"} else {
            if (side _group == east) then {"LaserTargetE"} else {"Land_HelipadEmpty_F"}
        };
        private _bullseye = _targetType createVehicle _targetPos;
        _group reveal [_bullseye, 4];

        // Calculate attack run positions (3km approach)
        private _attackDir = _vehicle getDir _targetPos;
        private _startPos = [
            (_targetPos select 0) + (sin (_attackDir + 180) * 3000),
            (_targetPos select 1) + (cos (_attackDir + 180) * 3000),
            0
        ];
        private _exitPos = [
            (_targetPos select 0) + (sin _attackDir * 3000),
            (_targetPos select 1) + (cos _attackDir * 3000),
            0
        ];

        // High altitude for approach
        _vehicle flyInHeightASL [1000, 300, 1000];

        _group setBehaviour "COMBAT";
        _group setCombatMode "RED";

        // WP1: Line up
        private _wp1 = _group addWaypoint [_startPos, 0];
        _wp1 setWaypointType "MOVE";
        _wp1 setWaypointSpeed "FULL";

        // WP2: Destroy target
        private _wp2 = _group addWaypoint [_targetPos, 0];
        _wp2 setWaypointType "DESTROY";
        _wp2 waypointAttachVehicle _bullseye;

        // WP3: Exit
        private _wp3 = _group addWaypoint [_exitPos, 0];
        _wp3 setWaypointType "MOVE";

        _group setCurrentWaypoint _wp1;

        ["Jet beginning attack run"] call BA_fnc_speak;

        // Cleanup target after 2 minutes
        [_bullseye] spawn {
            params ["_target"];
            sleep 120;
            if (!isNull _target) then { deleteVehicle _target; };
        };
    };

    case "jet_loiter": {
        while {count waypoints _group > 0} do { deleteWaypoint [_group, 0]; };

        private _altitude = _vehicle getVariable ["BA_jetAltitude", 500];
        _vehicle flyInHeightASL [_altitude, _altitude, _altitude];

        _group setBehaviour "AWARE";
        _group setCombatMode "RED";

        private _wp = _group addWaypoint [_targetPos, 0];
        _wp setWaypointType "LOITER";
        _wp setWaypointLoiterRadius 2000;
        _wp setWaypointLoiterType "CIRCLE_L";
        _group setCurrentWaypoint _wp;
    };

    case "jet_alt_low": {
        _vehicle setVariable ["BA_jetAltitude", 200];
        _vehicle flyInHeightASL [200, 200, 200];
        ["Altitude set to 200 meters"] call BA_fnc_speak;
    };

    case "jet_alt_med": {
        _vehicle setVariable ["BA_jetAltitude", 500];
        _vehicle flyInHeightASL [500, 500, 500];
        ["Altitude set to 500 meters"] call BA_fnc_speak;
    };

    case "jet_alt_high": {
        _vehicle setVariable ["BA_jetAltitude", 1000];
        _vehicle flyInHeightASL [1000, 1000, 1000];
        ["Altitude set to 1000 meters"] call BA_fnc_speak;
    };

    case "jet_rtb": {
        while {count waypoints _group > 0} do { deleteWaypoint [_group, 0]; };

        _vehicle flyInHeightASL [500, 500, 500];
        _group setBehaviour "CARELESS";

        // Land command will find nearest airport
        _vehicle land "LAND";

        ["Jet returning to base"] call BA_fnc_speak;
    };

    // ========== DISABLED - NEED FIXING ==========
    // case "stop", "hold_position", "watch", "mount_nearest", "dismount"
    // case vehicle/artillery/static commands

    default {
        ["Command not yet implemented"] call BA_fnc_speak;
    };
};

// Announce order issued (except for commands with custom messages or error cases)
if !(_orderType in ["garrison", "heal", "regroup", "find_cover", "stop_all", "dismount_all", "heli_stop", "heli_alt_50", "heli_alt_150", "heli_alt_300", "heli_defend", "heli_strafe", "jet_patrol", "jet_strike", "jet_hunt", "jet_strafe", "jet_alt_low", "jet_alt_med", "jet_alt_high", "jet_rtb"]) then {
    private _message = if (_isUnitOrder) then {
        format["%1, %2, grid %3", name _targetUnit, _label, _gridInfo]
    } else {
        format["%1 issued to grid %2", _label, _gridInfo]
    };
    format["announcing: %1", _message] call _debug;
    [_message] call BA_fnc_speak;
};

format["issueOrder complete: %1", _orderType] call _debug;
