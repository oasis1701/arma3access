/*
 * Function: BA_fnc_issueOrder
 * Executes an Arma 3 command based on order type.
 *
 * Uses BA_cursorPos as target position and BA_observedUnit as the unit.
 *
 * Arguments:
 *   0: Order type string <STRING>
 *   1: Order label for announcement <STRING>
 *
 * Return Value:
 *   None
 *
 * Example:
 *   ["move", "Move"] call BA_fnc_issueOrder;
 */

params [["_orderType", "", [""]], ["_label", "", [""]]];

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
private _unit = BA_observedUnit;

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

// Get the vehicle if unit is in one
private _vehicle = vehicle _unit;

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
format["Using group: %1", _group] call _debug;

format["group=%1, vehicle=%2", _group, _vehicle] call _debug;

// Get grid reference for announcement
private _gridInfo = [_targetPos] call BA_fnc_getGridInfo;
format["gridInfo=%1", _gridInfo] call _debug;

// Execute command based on type
switch (_orderType) do {

    // ========== INFANTRY COMMANDS (WORKING) ==========

    case "move": {
        format["move: group %1 to %2", _group, _targetPos] call _debug;
        _group move _targetPos;
        _group setBehaviour "AWARE";
        _group setSpeedMode "NORMAL";
        "move: command sent" call _debug;
    };

    case "sneak": {
        _group move _targetPos;
        _group setBehaviour "STEALTH";
        _group setSpeedMode "LIMITED";
    };

    case "assault": {
        _group move _targetPos;
        _group setBehaviour "COMBAT";
        _group setCombatMode "RED";
    };

    case "garrison": {
        private _buildings = _targetPos nearObjects ["Building", 100];
        if (count _buildings > 0) then {
            private _building = _buildings select 0;
            _group move (getPos _building);
            if (!isNil "BIS_fnc_taskDefend") then {
                [_group, _building] call BIS_fnc_taskDefend;
            };
        } else {
            ["No building found near cursor"] call BA_fnc_speak;
        };
    };

    case "hold_fire": {
        _group setCombatMode "BLUE";
    };

    case "fire_at_will": {
        _group setCombatMode "RED";
    };

    // ========== DISABLED - NEED FIXING ==========
    // case "stop", "hold_position", "watch", "mount_nearest", "dismount"
    // case helicopter/jet/vehicle/artillery/static commands

    default {
        ["Command not yet implemented"] call BA_fnc_speak;
    };
};

// Announce order issued (except for commands with custom messages or error cases)
if !(_orderType in ["garrison"]) then {
    private _message = format["%1 issued to grid %2", _label, _gridInfo];
    format["announcing: %1", _message] call _debug;
    [_message] call BA_fnc_speak;
};

format["issueOrder complete: %1", _orderType] call _debug;
