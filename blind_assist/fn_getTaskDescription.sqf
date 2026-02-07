/*
 * Function: BA_fnc_getTaskDescription
 * Gets a formatted description of a task for speech output.
 *
 * Arguments:
 *   0: _task - Task object OR Warlords array ["warlords", name, pos]
 *
 * Return Value:
 *   String - Formatted description: "Title, state, distance direction"
 *
 * Example:
 *   [_task] call BA_fnc_getTaskDescription;
 *   // Returns: "Destroy the Radar, active, 450 meters northwest"
 */

params [["_task", taskNull, [taskNull, []]]];

// Handle Warlords objective (array format: ["type", name, pos])
if (_task isEqualType []) then {
    _task params ["_type", "_name", "_pos"];

    // Handle different Warlords entry types
    switch (_type) do {
        case "warlords_status": {
            // Status message (no position)
            _name
        };
        case "warlords_vote": {
            // Voteable sector during voting phase
            private _distance = round (BA_cursorPos distance2D _pos);
            private _bearing = BA_cursorPos getDir _pos;
            private _compassDir = [_bearing] call BA_fnc_bearingToCompass;
            format ["VOTE: %1, %2 meters %3", _name, _distance, _compassDir]
        };
        case "warlords_attack": {
            // Active attack target
            private _distance = round (BA_cursorPos distance2D _pos);
            private _bearing = BA_cursorPos getDir _pos;
            private _compassDir = [_bearing] call BA_fnc_bearingToCompass;
            format ["%1, %2 meters %3", _name, _distance, _compassDir]
        };
        case "warlords_sector": {
            // Sector with ownership (FRIENDLY/ENEMY/NEUTRAL: name)
            private _distance = round (BA_cursorPos distance2D _pos);
            private _bearing = BA_cursorPos getDir _pos;
            private _compassDir = [_bearing] call BA_fnc_bearingToCompass;
            format ["%1, %2 meters %3", _name, _distance, _compassDir]
        };
        case "combatpatrol_status": {
            // Status message (no distance) - same as warlords_status
            _name
        };
        case "combatpatrol_location": {
            // Voteable location with distance
            private _distance = round (BA_cursorPos distance2D _pos);
            private _bearing = BA_cursorPos getDir _pos;
            private _compassDir = [_bearing] call BA_fnc_bearingToCompass;
            format ["%1, %2 meters %3", _name, _distance, _compassDir]
        };
        default {
            // Legacy "warlords" type
            private _distance = round (BA_cursorPos distance2D _pos);
            private _bearing = BA_cursorPos getDir _pos;
            private _compassDir = [_bearing] call BA_fnc_bearingToCompass;
            format ["OBJECTIVE: %1, %2 meters %3", _name, _distance, _compassDir]
        };
    }
} else {
    // Standard task object handling
    // Get task info using native commands on Task object
    private _desc = taskDescription _task;
    // taskDescription returns [description, title, marker] - get the title
    private _title = if (_desc isEqualType []) then { _desc select 1 } else { str _desc };
    if (_title == "") then { _title = str _task };

    private _state = taskState _task;
    private _pos = taskDestination _task;

    // Format state for speech (use toUpper for case-insensitive matching)
    private _stateText = switch (toUpper _state) do {
        case "CREATED": { "queued" };
        case "ASSIGNED": { "active" };
        case "SUCCEEDED": { "completed" };
        case "FAILED": { "failed" };
        case "CANCELED": { "canceled" };
        default { _state };
    };

    // Distance and direction from cursor
    private _distance = round (BA_cursorPos distance2D _pos);
    private _bearing = BA_cursorPos getDir _pos;
    private _compassDir = [_bearing] call BA_fnc_bearingToCompass;

    // Format: "Destroy the Radar, active, 450 meters northwest"
    format ["%1, %2, %3 meters %4", _title, _stateText, _distance, _compassDir]
}
