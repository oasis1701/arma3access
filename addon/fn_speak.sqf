/*
 * Function: BA_fnc_speak
 * Makes NVDA speak the given text.
 *
 * Arguments:
 *   0: _text - String to speak
 *
 * Return Value:
 *   String - "OK" on success, error code otherwise
 *
 * Example:
 *   ["Hello world"] call BA_fnc_speak;
 *   ["Grid position 045 072"] call BA_fnc_speak;
 */

params [["_text", "", [""]]];

if (_text isEqualTo "") exitWith {
    "EMPTY_TEXT"
};

"nvda_arma3_bridge" callExtension format["speak:%1", _text]
