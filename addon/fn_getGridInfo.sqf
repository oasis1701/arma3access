/*
 * Function: BA_fnc_getGridInfo
 * Gets a 6-digit grid reference formatted for speech.
 *
 * Arguments:
 *   0: _pos - Position to get grid for (default: BA_cursorPos)
 *
 * Return Value:
 *   String - Grid reference formatted as "0 4 5, 0 7 2"
 *
 * Example:
 *   private _grid = [BA_cursorPos] call BA_fnc_getGridInfo;
 *   // Returns "0 4 5, 0 7 2"
 */

params [
    ["_pos", [], [[]]]
];

// Use cursor position if none provided
if (count _pos == 0) then {
    _pos = BA_cursorPos;
};

// Get 6-digit grid reference (e.g., "045072")
private _grid = mapGridPosition _pos;

// Ensure we have 6 digits (pad with zeros if needed)
while {count _grid < 6} do {
    _grid = "0" + _grid;
};

// Split into easting (first 3) and northing (last 3)
private _easting = _grid select [0, 3];
private _northing = _grid select [3, 3];

// Format with spaces for speech: "0 4 5, 0 7 2"
private _eastingSpaced = format["%1 %2 %3",
    _easting select [0, 1],
    _easting select [1, 1],
    _easting select [2, 1]
];
private _northingSpaced = format["%1 %2 %3",
    _northing select [0, 1],
    _northing select [1, 1],
    _northing select [2, 1]
];

format["Grid %1, %2", _eastingSpaced, _northingSpaced]
