/*
 * Function: BA_fnc_snapCursorToUnit
 * Snaps the cursor back to the observed unit (observer mode) or player (focus mode).
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Boolean - true if cursor was snapped
 *
 * Example:
 *   [] call BA_fnc_snapCursorToUnit;
 */

// Must be in observer mode or focus mode
if (!BA_observerMode && !BA_focusMode) exitWith {
    ["Not in observer or focus mode."] call BA_fnc_speak;
    false
};

// Determine which unit to snap to
private _unit = if (BA_observerMode) then { BA_observedUnit } else { player };

// Must have a valid unit
if (isNull _unit || !alive _unit) exitWith {
    ["No unit to snap to."] call BA_fnc_speak;
    false
};

// Get unit's current position
private _unitPos = getPos _unit;

// Clear road state since we're leaving the road
BA_currentRoad = objNull;
BA_atRoadEnd = false;
BA_lastTravelDirection = "";

// Set cursor position
[_unitPos, false] call BA_fnc_setCursorPos;

// Announce
private _msg = if (BA_observerMode) then { "Cursor at observed unit." } else { "Cursor at your position." };
[_msg] call BA_fnc_speak;

// Announce brief position info
[] call BA_fnc_announceCursorBrief;

true
