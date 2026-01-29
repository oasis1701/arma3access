/*
 * Function: BA_fnc_getAltitudeInfo
 * Gets the altitude above sea level at a position.
 *
 * Arguments:
 *   0: _pos - Position to check (default: BA_cursorPos)
 *
 * Return Value:
 *   String - Altitude formatted for speech (e.g., "45 meters")
 *
 * Example:
 *   private _alt = [BA_cursorPos] call BA_fnc_getAltitudeInfo;
 */

params [
    ["_pos", [], [[]]]
];

// Use cursor position if none provided
if (count _pos == 0) then {
    _pos = BA_cursorPos;
};

// Get terrain height above sea level
private _altitude = getTerrainHeightASL [_pos select 0, _pos select 1];

// Round to nearest meter
_altitude = round _altitude;

// Handle negative altitudes (below sea level)
if (_altitude < 0) then {
    format["%1 meters below sea level", abs _altitude]
} else {
    format["%1 meters", _altitude]
}
