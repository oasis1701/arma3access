/*
 * Function: BA_fnc_exitFocusMode
 * Exits focus mode - returns to normal manual control.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Boolean - true if successfully exited focus mode
 *
 * Example:
 *   [] call BA_fnc_exitFocusMode;
 */

// Only exit if in focus mode
if (!BA_focusMode) exitWith {
    false
};

// Clear state
BA_focusMode = false;
BA_cursorActive = false;

// Close any open menus
if (BA_landmarksMenuActive) then {
    [] call BA_fnc_closeLandmarksMenu;
};

if (BA_intersectionMenuActive) then {
    [] call BA_fnc_closeIntersectionMenu;
};

if (BA_menuActive) then {
    [] call BA_fnc_closeBAMenu;
};

// Close the dialog (this also triggers onUnload as a safety net)
closeDialog 0;

// Brief announcement (player is taking action, keep it short)
["Focus off."] call BA_fnc_speak;
systemChat "Focus Mode: Off";

true
