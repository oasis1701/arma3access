/*
 * Function: BA_fnc_getLandmarkDescription
 * Formats a landmark location for speech announcement.
 *
 * Arguments:
 *   0: _location - Location object from nearestLocations
 *
 * Return Value:
 *   String - Formatted description: "[name], [type], [distance] meters [direction]"
 *
 * Example:
 *   [_location] call BA_fnc_getLandmarkDescription;
 *   // Returns: "Agia Marina, Village, 1520 meters northeast"
 */

params [["_location", locationNull, [locationNull]]];

if (isNull _location) exitWith { "Unknown location" };

// Get location properties
private _name = text _location;
private _type = type _location;
private _locPos = locationPosition _location;

// Get readable type name
private _typeName = [_type] call BA_fnc_getLocationTypeName;

// Calculate distance from cursor
private _distance = BA_cursorPos distance2D _locPos;
private _distanceRounded = round _distance;

// Calculate bearing and compass direction
private _bearing = BA_cursorPos getDir _locPos;
private _compassDir = [_bearing] call BA_fnc_bearingToCompass;

// Format the description
if (_name == "") then {
    _name = _typeName;
};

format ["%1, %2, %3 meters %4", _name, _typeName, _distanceRounded, _compassDir]
