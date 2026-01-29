/*
 * Function: BA_fnc_braille
 * Sends a message to the braille display (if available).
 *
 * Arguments:
 *   0: _text - String to display on braille
 *
 * Return Value:
 *   String - "OK" on success, error code otherwise
 *
 * Example:
 *   ["Position updated"] call BA_fnc_braille;
 */

params [["_text", "", [""]]];

if (_text isEqualTo "") exitWith {
    "EMPTY_TEXT"
};

"nvda_arma3_bridge" callExtension format["braille:%1", _text]
