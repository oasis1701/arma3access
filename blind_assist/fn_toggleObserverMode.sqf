/*
 * Function: BA_fnc_toggleObserverMode
 * Toggles between manual control and AI observer mode.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Boolean - true if now in observer mode, false if in manual mode
 *
 * Example:
 *   [] call BA_fnc_toggleObserverMode;
 */

if (BA_observerMode) then {
    // Currently in observer mode - exit to manual control
    [] call BA_fnc_exitObserverMode;
    false
} else {
    // Currently in manual mode - enter observer mode
    [] call BA_fnc_enterObserverMode;
    true
};
