/*
 * Function: BA_fnc_test
 * Tests if NVDA is running and accessible.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Boolean - true if NVDA is running, false otherwise
 *
 * Example:
 *   if ([] call BA_fnc_test) then {
 *       ["NVDA is ready"] call BA_fnc_speak;
 *   };
 */

private _result = "nvda_arma3_bridge" callExtension "test";
_result == "OK"
