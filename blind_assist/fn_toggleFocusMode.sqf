/*
 * Function: BA_fnc_toggleFocusMode
 * Toggles focus mode on/off.
 *
 * Focus mode enables cursor/scanner/landmarks while player keeps direct control.
 * Only works when NOT in observer mode (observer mode has full features).
 *
 * Hotkey: Backtick/Tilde (~)
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Boolean - new state (true = focus mode on)
 *
 * Example:
 *   [] call BA_fnc_toggleFocusMode;
 */

// Don't toggle if in observer mode
if (BA_observerMode) exitWith {
    ["Observer mode active. Use Ctrl O to exit."] call BA_fnc_speak;
    false
};

if (BA_focusMode) then {
    [] call BA_fnc_exitFocusMode;
    false
} else {
    [] call BA_fnc_enterFocusMode;
    true
};
