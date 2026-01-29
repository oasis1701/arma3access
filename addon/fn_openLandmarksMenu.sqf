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

// Store in state
BA_landmarksItems = [_geoItems, _tacItems, _natoItems, _extrasItems];
BA_landmarksCategoryIndex = 0;
BA_landmarksItemIndex = [0, 0, 0, 0];
BA_landmarksMenuActive = true;

// Build announcement
private _categoryNames = ["Geography", "Tactical", "NATO", "Extras"];
private _currentCategory = _categoryNames select BA_landmarksCategoryIndex;
private _currentItems = BA_landmarksItems select BA_landmarksCategoryIndex;
private _itemCount = count _currentItems;

private _announcement = "Landmarks. ";

if (_itemCount > 0) then {
    _announcement = _announcement + format ["%1 category, %2 items. ", _currentCategory, _itemCount];

    // Announce first item
    private _firstItem = _currentItems select 0;
    private _description = [_firstItem] call BA_fnc_getLandmarkDescription;
    _announcement = _announcement + format ["1. %1. ", _description];
} else {
    _announcement = _announcement + format ["%1 category, no items. ", _currentCategory];
};

_announcement = _announcement + "Left Right for categories, Up Down to navigate, Enter to go.";

[_announcement] call BA_fnc_speak;
