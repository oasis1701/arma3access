/*
 * Function: BA_fnc_snapCursorToUnit
 * Snaps the cursor back to the currently observed unit's position.
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

// Must be in observer mode
if (!BA_observerMode) exitWith {
    ["Not in observer mode."] call BA_fnc_speak;
    false
};

// Must have a valid observed unit
if (isNull BA_observedUnit || !alive BA_observedUnit) exitWith {
    ["No unit to snap to."] call BA_fnc_speak;
    false
};

// Get unit's current position
private _unitPos = getPos BA_observedUnit;

// Clear road state since we're leaving the road
BA_currentRoad = objNull;
BA_atRoadEnd = false;
BA_lastTravelDirection = "";

// Set cursor position
[_unitPos, false] call BA_fnc_setCursorPos;

// Announce
["Cursor at observed unit."] call BA_fnc_speak;

// Announce brief position info
[] call BA_fnc_announceCursorBrief;

true
