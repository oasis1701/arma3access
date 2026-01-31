/*
 * Function: BA_fnc_openLandmarksMenu
 * Opens the landmarks menu and queries nearby locations from cursor position.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_openLandmarksMenu;
 */

// Don't open if already active
if (BA_landmarksMenuActive) exitWith {};

// Close other menus if open
if (BA_orderMenuActive) then { [] call BA_fnc_closeOrderMenu };
if (BA_groupMenuActive) then { [] call BA_fnc_closeGroupMenu };

// Set search radius to entire map
private _searchRadius = worldSize;

// Get category type definitions
private _geographyTypes = (BA_landmarksCategories select 0) select 1;
private _tacticalTypes = (BA_landmarksCategories select 1) select 1;
private _extrasTypes = (BA_landmarksCategories select 3) select 1;

// Query all locations on the map
private _allTypes = _geographyTypes + _tacticalTypes + _extrasTypes;
private _allLocations = nearestLocations [BA_cursorPos, _allTypes, _searchRadius];

// Also get NATO symbols (types starting with b_, o_, n_)
// These aren't in the standard list, so we query all location types
private _natoLocations = [];
{
    private _type = type _x;
    private _prefix = _type select [0, 2];
    if (_prefix in ["b_", "o_", "n_"]) then {
        _natoLocations pushBack _x;
    };
} forEach (nearestLocations [BA_cursorPos, [], _searchRadius]);

// Sort into categories
private _geoItems = [];
private _tacItems = [];
private _natoItems = [];
private _extrasItems = [];

{
    private _type = type _x;
    if (_type in _geographyTypes) then {
        _geoItems pushBack _x;
    } else {
        if (_type in _tacticalTypes) then {
            _tacItems pushBack _x;
        } else {
            if (_type in _extrasTypes) then {
                _extrasItems pushBack _x;
            };
        };
    };
} forEach _allLocations;

// NATO items already filtered
_natoItems = _natoLocations;

// Sort each category by distance
private _sortByDistance = {
    private _distA = BA_cursorPos distance2D (locationPosition _a);
    private _distB = BA_cursorPos distance2D (locationPosition _b);
    _distA - _distB
};

_geoItems = [_geoItems, [], { BA_cursorPos distance2D (locationPosition _x) }, "ASCEND"] call BIS_fnc_sortBy;
_tacItems = [_tacItems, [], { BA_cursorPos distance2D (locationPosition _x) }, "ASCEND"] call BIS_fnc_sortBy;
_natoItems = [_natoItems, [], { BA_cursorPos distance2D (locationPosition _x) }, "ASCEND"] call BIS_fnc_sortBy;
_extrasItems = [_extrasItems, [], { BA_cursorPos distance2D (locationPosition _x) }, "ASCEND"] call BIS_fnc_sortBy;

// Limit to max items per category
private _maxItems = BA_landmarksMaxPerCategory;
if (count _geoItems > _maxItems) then { _geoItems resize _maxItems };
if (count _tacItems > _maxItems) then { _tacItems resize _maxItems };
if (count _natoItems > _maxItems) then { _natoItems resize _maxItems };
if (count _extrasItems > _maxItems) then { _extrasItems resize _maxItems };

// Get mission markers
private _markerItems = [];
{
    private _name = _x;
    // Skip system markers (BIS_ prefix) and empty markers
    if (_name != "" && {!(_name select [0, 4] == "BIS_")} && {!(_name select [0, 1] == "_")}) then {
        private _pos = getMarkerPos _name;
        // Skip markers at [0,0,0] (invalid or hidden)
        if !(_pos isEqualTo [0, 0, 0]) then {
            _markerItems pushBack _name;
        };
    };
} forEach allMapMarkers;

// Sort markers by distance from cursor
_markerItems = [_markerItems, [], { BA_cursorPos distance2D (getMarkerPos _x) }, "ASCEND"] call BIS_fnc_sortBy;

// Limit markers
if (count _markerItems > _maxItems) then { _markerItems resize _maxItems };

// Get mission tasks - check both player and original unit (for observer mode)
private _taskItems = [];
private _allTasks = simpleTasks player;
// Also check original unit's tasks if in observer mode
if (!isNil "BA_originalUnit" && {!isNull BA_originalUnit} && {BA_originalUnit != player}) then {
    _allTasks = _allTasks + (simpleTasks BA_originalUnit);
    _allTasks = _allTasks arrayIntersect _allTasks;  // Remove duplicates
};
{
    private _task = _x;
    private _state = taskState _task;
    // Only include active tasks (not completed/failed/canceled)
    if (toUpper _state in ["CREATED", "ASSIGNED"]) then {
        private _pos = taskDestination _task;
        // Skip tasks with no destination
        if !(_pos isEqualTo [0, 0, 0]) then {
            _taskItems pushBack _task;  // Store Task object directly
        };
    };
} forEach _allTasks;

// Sort tasks by distance from cursor
_taskItems = [_taskItems, [], { BA_cursorPos distance2D (taskDestination _x) }, "ASCEND"] call BIS_fnc_sortBy;

// Limit tasks
if (count _taskItems > _maxItems) then { _taskItems resize _maxItems };

// Store in state
BA_landmarksItems = [_geoItems, _tacItems, _natoItems, _extrasItems, _markerItems, _taskItems];
BA_landmarksCategoryIndex = 0;
BA_landmarksItemIndex = [0, 0, 0, 0, 0, 0];
BA_landmarksMenuActive = true;

// Build announcement
private _categoryNames = ["Geography", "Tactical", "NATO", "Extras", "Markers", "Tasks"];
private _currentCategory = _categoryNames select BA_landmarksCategoryIndex;
private _currentItems = BA_landmarksItems select BA_landmarksCategoryIndex;
private _itemCount = count _currentItems;

private _announcement = "Landmarks. ";

if (_itemCount > 0) then {
    _announcement = _announcement + format ["%1 category, %2 items. ", _currentCategory, _itemCount];

    // Announce first item (check type based on category)
    private _firstItem = _currentItems select 0;
    private _description = "";
    if (BA_landmarksCategoryIndex == 5) then {
        // Tasks category - item is task ID
        _description = [_firstItem] call BA_fnc_getTaskDescription;
    } else {
        if (_firstItem isEqualType "") then {
            // Markers category - item is marker name
            _description = [_firstItem] call BA_fnc_getMarkerDescription;
        } else {
            // Location object
            _description = [_firstItem] call BA_fnc_getLandmarkDescription;
        };
    };
    _announcement = _announcement + format ["1. %1. ", _description];
} else {
    _announcement = _announcement + format ["%1 category, no items. ", _currentCategory];
};

_announcement = _announcement + "Left Right for categories, Up Down to navigate, Enter to go.";

[_announcement] call BA_fnc_speak;
