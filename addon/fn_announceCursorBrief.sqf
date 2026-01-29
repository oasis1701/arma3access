/*
 * Function: BA_fnc_announceCursorBrief
 * Announces brief cursor position info: grid + terrain + altitude.
 *
 * Arguments:
 *   None (uses BA_cursorPos)
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_announceCursorBrief;
 *   // Speaks: "Grid 0 4 5, 0 7 2. Grass. 45 meters."
 */

// Get terrain type
private _terrain = [BA_cursorPos] call BA_fnc_getTerrainInfo;

// Get altitude
private _altitude = [BA_cursorPos] call BA_fnc_getAltitudeInfo;

// Get grid reference (last)
private _grid = [BA_cursorPos] call BA_fnc_getGridInfo;

// Build announcement: Terrain, Altitude, Grid (grid last)
private _announcement = format["%1. %2. %3.", _terrain, _altitude, _grid];

[_announcement] call BA_fnc_speak;
