/*
 * Function: BA_fnc_selectLandmarksMenuItem
 * Selects the current landmark and moves the cursor to it.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_selectLandmarksMenuItem;
 */

if (!BA_landmarksMenuActive) exitWith {};

private _currentItems = BA_landmarksItems select BA_landmarksCategoryIndex;
private _itemCount = count _currentItems;

if (_itemCount == 0) exitWith {
    ["No item selected."] call BA_fnc_speak;
};

private _currentIndex = BA_landmarksItemIndex select BA_landmarksCategoryIndex;
private _selectedItem = _currentItems select _currentIndex;

// Get position and name (check if marker string or location object)
private _locPos = [];
private _name = "";

if (_selectedItem isEqualType "") then {
    // It's a marker name (string)
    _locPos = getMarkerPos _selectedItem;
    _name = markerText _selectedItem;
    if (_name == "") then { _name = _selectedItem };
} else {
    // It's a location object
    _locPos = locationPosition _selectedItem;
    _name = text _selectedItem;
    if (_name == "") then {
        _name = [type _selectedItem] call BA_fnc_getLocationTypeName;
    };
};

// Close the menu first
BA_landmarksMenuActive = false;
BA_landmarksCategoryIndex = 0;
BA_landmarksItemIndex = [0, 0, 0, 0, 0];
BA_landmarksItems = [[], [], [], [], []];

// Clear road state since cursor is leaving the road
BA_currentRoad = objNull;
BA_atRoadEnd = false;
BA_lastTravelDirection = "";

// Move cursor to the location
[_locPos, false] call BA_fnc_setCursorPos;

// Announce the move
[format ["Cursor moved to %1.", _name]] call BA_fnc_speak;
