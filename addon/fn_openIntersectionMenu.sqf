/*
 * Function: BA_fnc_openIntersectionMenu
 * Opens a menu showing all roads at the current cursor position.
 * Allows selection of a road to follow using Up/Down and Enter.
 *
 * Features:
 * - Marks the road you came from as "(back)"
 * - Shows bearing when multiple roads go the same compass direction
 * - Skips very short junction segments and shows the real road they lead to
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Boolean - true if menu opened successfully
 *
 * Example:
 *   [] call BA_fnc_openIntersectionMenu;
 */

// Must be in observer mode with road mode enabled
if (!BA_observerMode || !BA_cursorActive || !BA_roadModeEnabled) exitWith {
    ["Road mode not active."] call BA_fnc_speak;
    false
};

// Get cursor position
private _cursorPos2D = [BA_cursorPos select 0, BA_cursorPos select 1];

// Find all roads at cursor position using multi-method detection
private _roadAtCursor = roadAt BA_cursorPos;
private _nearbyRoads = _cursorPos2D nearRoads 50;

// Combine and deduplicate
private _allRoads = [];
if (!isNull _roadAtCursor) then {
    _allRoads pushBackUnique _roadAtCursor;
};
{
    _allRoads pushBackUnique _x;
} forEach _nearbyRoads;

// Filter to roads with endpoint near cursor
private _roadsAtPosition = _allRoads select {
    private _info = getRoadInfo _x;
    if (count _info == 0) then { false } else {
        _info params ["", "", "", "", "", "", "_b", "_e"];
        (_cursorPos2D distance2D _b < 15) || (_cursorPos2D distance2D _e < 15)
    };
};

if (count _roadsAtPosition == 0) exitWith {
    ["No roads at cursor position."] call BA_fnc_speak;
    false
};

// Helper function to follow short segments and find the "real" road
private _fnc_followShortSegments = {
    params ["_startRoad", "_startPos", "_cursorPos", "_visited"];

    private _roadInfo = getRoadInfo _startRoad;
    if (count _roadInfo == 0) exitWith { [_startRoad, _roadInfo, 0] };

    _roadInfo params ["", "", "", "", "", "", "_begPos", "_endPos"];
    private _length = _begPos distance2D _endPos;

    // Determine far endpoint (away from cursor)
    private _farPos = if (_cursorPos distance2D _begPos < _cursorPos distance2D _endPos) then { _endPos } else { _begPos };

    // If segment is long enough, return it
    if (_length >= 15) exitWith { [_startRoad, _roadInfo, _length] };

    // Segment is short - try to find the next real road
    private _farRoads = _farPos nearRoads 50;
    private _nextRoads = _farRoads select {
        if (_x isEqualTo _startRoad) then { false } else {
            if (_x in _visited) then { false } else {
                private _info = getRoadInfo _x;
                if (count _info == 0) then { false } else {
                    _info params ["", "", "", "", "", "", "_b", "_e"];
                    (_farPos distance2D _b < 15) || (_farPos distance2D _e < 15)
                };
            };
        };
    };

    if (count _nextRoads == 0) exitWith { [_startRoad, _roadInfo, _length] };

    // Find the longest connecting road
    private _bestRoad = objNull;
    private _bestLen = 0;
    private _bestInfo = [];

    {
        private _nextInfo = getRoadInfo _x;
        if (count _nextInfo > 0) then {
            _nextInfo params ["", "", "", "", "", "", "_nBeg", "_nEnd"];
            private _nextLen = _nBeg distance2D _nEnd;
            if (_nextLen > _bestLen) then {
                _bestRoad = _x;
                _bestLen = _nextLen;
                _bestInfo = _nextInfo;
            };
        };
    } forEach _nextRoads;

    if (isNull _bestRoad) exitWith { [_startRoad, _roadInfo, _length] };

    // If next road is also short, recurse (with depth limit via visited)
    if (_bestLen < 15 && count _visited < 3) then {
        _visited pushBack _startRoad;
        [_bestRoad, _farPos, _cursorPos, _visited] call _fnc_followShortSegments
    } else {
        [_bestRoad, _bestInfo, _length + _bestLen]
    };
};

// Build menu items with road details
// Format: [road, compassDir, type, length, destination, bearing, isBack]
private _menuItems = [];

{
    private _road = _x;
    private _roadInfo = getRoadInfo _road;
    if (count _roadInfo == 0) then { continue };

    _roadInfo params ["_mapType", "_width", "_isPedestrian", "_texture", "_textureEnd", "_material", "_begPos", "_endPos", "_isBridge"];

    // Determine which endpoint is at cursor (the "start" of this road from here)
    private _begDist = _cursorPos2D distance2D _begPos;
    private _endDist = _cursorPos2D distance2D _endPos;
    private _startPos = if (_begDist < _endDist) then { _begPos } else { _endPos };
    private _farPos = if (_startPos isEqualTo _begPos) then { _endPos } else { _begPos };

    // Calculate bearing (direction road goes from here)
    private _bearing = _startPos getDir _farPos;
    private _compassDir = [_bearing] call BA_fnc_bearingToCompass;

    // Check if this is the road we came from
    private _isBack = _road isEqualTo BA_currentRoad;

    // Get road type
    private _roadType = [_roadInfo] call BA_fnc_getRoadTypeDescription;

    // Calculate road length
    private _length = _begPos distance2D _endPos;

    // For short segments, follow to find real road
    private _displayRoad = _road;
    private _displayInfo = _roadInfo;
    private _displayLength = _length;

    if (_length < 15 && !_isBack) then {
        private _result = [_road, _startPos, _cursorPos2D, []] call _fnc_followShortSegments;
        _result params ["_realRoad", "_realInfo", "_totalLen"];
        _displayRoad = _realRoad;
        _displayInfo = _realInfo;
        _displayLength = _totalLen;

        // Update road type if we found a different road
        if (!(_realRoad isEqualTo _road) && count _realInfo > 0) then {
            _roadType = [_realInfo] call BA_fnc_getRoadTypeDescription;
        };
    };

    // Determine destination (what's at the far end of the display road)
    private _destination = "continues";

    if (count _displayInfo > 0) then {
        _displayInfo params ["", "", "", "", "", "", "_dBeg", "_dEnd"];
        // Far end of display road (opposite of where we connect)
        private _displayFar = if (_cursorPos2D distance2D _dBeg < _cursorPos2D distance2D _dEnd) then { _dEnd } else { _dBeg };

        private _farRoads = _displayFar nearRoads 50;
        private _connectedAtFar = _farRoads select {
            if (_x isEqualTo _displayRoad) then { false } else {
                private _info = getRoadInfo _x;
                if (count _info == 0) then { false } else {
                    _info params ["", "", "", "", "", "", "_b", "_e"];
                    (_displayFar distance2D _b < 15) || (_displayFar distance2D _e < 15)
                };
            };
        };

        if (count _connectedAtFar == 0) then {
            _destination = "ends";
        } else {
            if (count _connectedAtFar >= 2) then {
                _destination = "intersection";
            };
        };
    };

    // Add to menu items: [road, compassDir, type, length, destination, bearing, isBack]
    _menuItems pushBack [_road, _compassDir, _roadType, round _displayLength, _destination, round _bearing, _isBack];
} forEach _roadsAtPosition;

if (count _menuItems == 0) exitWith {
    ["No roads found."] call BA_fnc_speak;
    false
};

// Check for duplicate compass directions
private _dirCounts = createHashMap;
{
    private _dir = toLower (_x select 1);
    _dirCounts set [_dir, (_dirCounts getOrDefault [_dir, 0]) + 1];
} forEach _menuItems;

// Build final menu items with direction text
BA_intersectionMenuItems = [];
{
    _x params ["_road", "_compassDir", "_type", "_len", "_dest", "_bearing", "_isBack"];

    // Build direction text
    private _dirText = _compassDir;

    // Add bearing if there are duplicates
    if ((_dirCounts getOrDefault [toLower _compassDir, 0]) > 1) then {
        _dirText = format ["%1 (%2°)", _compassDir, _bearing];
    };

    BA_intersectionMenuItems pushBack [_road, _dirText, _type, _len, _dest, _bearing];
} forEach _menuItems;

// Sort by bearing for logical order (north first, then clockwise)
BA_intersectionMenuItems sort true; // sorts by first element after we add sort key
BA_intersectionMenuItems = BA_intersectionMenuItems apply {
    [_x select 5] + _x // prepend bearing for sorting
};
BA_intersectionMenuItems sort true;
// Remove sort key, keep [road, dirText, type, len, dest]
BA_intersectionMenuItems = BA_intersectionMenuItems apply {
    [_x select 1, _x select 2, _x select 3, _x select 4, _x select 5]
};

// Open menu
BA_intersectionMenuActive = true;
BA_intersectionMenuIndex = 0;

// Announce menu opening with first item
private _count = count BA_intersectionMenuItems;
private _firstItem = BA_intersectionMenuItems select 0;
_firstItem params ["_road", "_dir", "_type", "_len", "_dest"];

private _announcement = format ["Intersection menu. %1 roads. 1: %2, %3, %4 meters, %5.",
    _count, _dir, _type, _len, _dest];
[_announcement] call BA_fnc_speak;

true
