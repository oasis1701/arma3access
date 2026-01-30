/*
 * Function: BA_fnc_getMarkerDescription
 * Formats a marker for speech announcement.
 *
 * Arguments:
 *   0: _markerName - The marker name string
 *
 * Return Value:
 *   String - Formatted description: "Name, Radius, Distance Direction"
 *
 * Example:
 *   ["enemy_spawn_zone"] call BA_fnc_getMarkerDescription;
 *   // Returns: "Enemy Spawn Zone, 50 meter radius, 340 meters north"
 */

params [["_markerName", "", [""]]];

// Get marker text (display name), fall back to marker name if empty
private _text = markerText _markerName;
if (_text == "") then { _text = _markerName };

// Get marker position and size
private _pos = getMarkerPos _markerName;
private _size = markerSize _markerName;  // Returns [a, b] ellipse dimensions

// Build radius description
private _radiusDesc = "";
private _a = _size select 0;
private _b = _size select 1;
if (_a > 0 || _b > 0) then {
    if (_a == _b) then {
        _radiusDesc = format ["%1 meter radius", round _a];
    } else {
        _radiusDesc = format ["%1 by %2 meters", round _a, round _b];
    };
};

// Distance and direction from cursor
private _distance = round (BA_cursorPos distance2D _pos);
private _bearing = BA_cursorPos getDir _pos;
private _compassDir = [_bearing] call BA_fnc_bearingToCompass;

// Format output: "Name, radius, distance direction"
if (_radiusDesc != "") then {
    format ["%1, %2, %3 meters %4", _text, _radiusDesc, _distance, _compassDir]
} else {
    format ["%1, %2 meters %3", _text, _distance, _compassDir]
};
