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
    // Skip unnamed locations - they show as "Location, Location" and aren't useful
    if (text _x == "") then { continue };
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
        // Skip invisible markers (alpha 0) and markers with no display text (internal/AI markers)
        if (markerAlpha _name > 0 && {markerText _name != ""}) then {
            private _pos = getMarkerPos _name;
            // Skip markers at [0,0,0] (invalid or hidden)
            if !(_pos isEqualTo [0, 0, 0]) then {
                _markerItems pushBack _name;
            };
        };
    };
} forEach allMapMarkers;

// Sort markers by distance from cursor
_markerItems = [_markerItems, [], { BA_cursorPos distance2D (getMarkerPos _x) }, "ASCEND"] call BIS_fnc_sortBy;

// Limit markers
if (count _markerItems > _maxItems) then { _markerItems resize _maxItems };

// Get mission tasks - query only player and original unit (not all squad members)
// This avoids per-member duplicate task objects from mods like Hetman War Stories
private _taskItems = [];

diag_log "BA_TASKS: Starting task detection";

// Only query player and BA_originalUnit (in observer mode)
private _taskUnits = [player];
if (!isNil "BA_originalUnit" && {!isNull BA_originalUnit} && {BA_originalUnit != player}) then {
    _taskUnits pushBack BA_originalUnit;
};

// Method 1: Low-level simpleTasks
private _simpleTasks = [];
{
    private _unitTasks = simpleTasks _x;
    diag_log format ["BA_TASKS: simpleTasks %1 = %2", _x, count _unitTasks];
    _simpleTasks = _simpleTasks + _unitTasks;
} forEach _taskUnits;

diag_log format ["BA_TASKS: Total simpleTasks = %1", count _simpleTasks];

// Method 2: BIS Task Framework
private _frameworkTaskIDs = [];
if (!isNil "BIS_fnc_tasksUnit") then {
    {
        private _unitTaskIDs = [_x] call BIS_fnc_tasksUnit;
        diag_log format ["BA_TASKS: BIS_fnc_tasksUnit %1 = %2", _x, _unitTaskIDs];
        _frameworkTaskIDs = _frameworkTaskIDs + _unitTaskIDs;
    } forEach _taskUnits;

    _frameworkTaskIDs = _frameworkTaskIDs arrayIntersect _frameworkTaskIDs;
};

diag_log format ["BA_TASKS: Total framework task IDs = %1", _frameworkTaskIDs];

// Convert framework task IDs to task objects
private _frameworkTasks = [];
{
    private _taskObj = [_x] call BIS_fnc_taskReal;
    if (!isNull _taskObj) then {
        _frameworkTasks pushBack _taskObj;
    };
} forEach _frameworkTaskIDs;

// Combine both sources and remove object-level duplicates
private _allTasks = _simpleTasks + _frameworkTasks;
_allTasks = _allTasks arrayIntersect _allTasks;

diag_log format ["BA_TASKS: Combined tasks before dedup = %1", count _allTasks];

// Deduplicate by task title (handles mods that create separate task objects per unit)
private _seenTitles = [];
private _uniqueTasks = [];
{
    private _desc = taskDescription _x;
    private _title = if (_desc isEqualType []) then { _desc select 1 } else { str _desc };
    if (_title == "") then { _title = str _x };
    if !(_title in _seenTitles) then {
        _seenTitles pushBack _title;
        _uniqueTasks pushBack _x;
    };
} forEach _allTasks;
_allTasks = _uniqueTasks;

diag_log format ["BA_TASKS: After title dedup = %1", count _allTasks];

// Filter: only active tasks with valid destinations
{
    private _task = _x;
    private _state = taskState _task;
    private _pos = taskDestination _task;
    private _desc = taskDescription _task;
    // taskDescription returns [description, title, marker]
    private _marker = if (_desc isEqualType [] && {count _desc >= 3}) then { _desc select 2 } else { "" };
    private _markerPos = if (_marker != "") then { getMarkerPos _marker } else { [0,0,0] };
    diag_log format ["BA_TASKS: Task %1, state=%2, pos=%3, marker=%4, markerPos=%5", _task, _state, _pos, _marker, _markerPos];
    diag_log format ["BA_TASKS: Task desc = %1", _desc];
    if (toUpper _state in ["CREATED", "ASSIGNED"]) then {
        // Try marker position if taskDestination is [0,0,0]
        private _finalPos = if (_pos isEqualTo [0,0,0]) then { _markerPos } else { _pos };
        if !(_finalPos isEqualTo [0, 0, 0]) then {
            _taskItems pushBack _task;
        };
    };
} forEach _allTasks;

diag_log format ["BA_TASKS: After filter = %1 tasks", count _taskItems];

// Warlords Detection - use markers since BIS_WL variables don't sync to client
// See docs/warlords_reference/ for Warlords source code reference
private _wlMarkers = allMapMarkers select { "BIS_WL" in _x };
private _sectorMarkers = _wlMarkers select { "sectorMrkr_" in _x && !("Text" in _x) && !("Lock" in _x) };
private _isWarlords = count _sectorMarkers > 0;

if (_isWarlords) then {
    // Get current target for our side (correct variable from fn_wlaicore.fsm)
    private _mySide = side group player;
    private _sideStr = str _mySide;  // "WEST", "EAST", "GUER"
    private _varName = format ["BIS_WL_currentSector_%1", _sideStr];
    private _targetSector = missionNamespace getVariable [_varName, objNull];

    diag_log format ["BA_TASKS: Side=%1, Target var=%2, Target=%3", _sideStr, _varName, _targetSector];

    // Add status message based on voting/attack phase
    if (isNull _targetSector) then {
        diag_log "BA_TASKS: === VOTING PHASE ===";
        _taskItems pushBack ["warlords_status", "VOTING - Select a sector", [0,0,0], objNull, false];
    } else {
        // Sector name is in bis_wl_sectortext variable
        private _targetName = _targetSector getVariable ["bis_wl_sectortext", "Unknown Sector"];
        private _targetPos = getPos _targetSector;
        diag_log format ["BA_TASKS: === ATTACK PHASE === Target: %1", _targetName];
        _taskItems pushBack ["warlords_attack", format ["ATTACK: %1", _targetName], _targetPos, objNull, false];
    };

    // Build sector list using marker-based triangulation
    // BIS_WL_allSectors is server-side only, so we find Logic objects near marker positions
    diag_log format ["BA_TASKS: Using marker triangulation for %1 sector markers", count _sectorMarkers];

    {
        private _markerName = _x;
        private _pos = getMarkerPos _markerName;

        // Find Warlords sector module near this marker position
        // The correct class is ModuleWLSector_F (not ModuleSector_F)
        private _nearbySectors = nearestObjects [_pos, ["ModuleWLSector_F"], 50];

        if (count _nearbySectors > 0) then {
            private _sectorObj = _nearbySectors select 0;
            diag_log format ["BA_TASKS: Found ModuleWLSector_F: %1", _sectorObj];

            // Get sector name from text marker
            private _sectorNum = (_markerName splitString "_") select 3;
            private _textMarker = format ["BIS_WL_sectorMrkrText_%1", _sectorNum];
            private _sectorName = markerText _textMarker;

            // Determine ownership from marker color
            private _color = getMarkerColor _markerName;
            private _ownerStr = switch (_color) do {
                case "colorBLUFOR": { if (_mySide == west) then {"FRIENDLY"} else {"ENEMY"} };
                case "colorOPFOR": { if (_mySide == east) then {"FRIENDLY"} else {"ENEMY"} };
                default { "NEUTRAL" };
            };

            // Can only vote for non-friendly sectors during voting phase
            private _canVote = (isNull _targetSector) && (_ownerStr != "FRIENDLY");

            _taskItems pushBack ["warlords_sector", format ["%1: %2", _ownerStr, _sectorName], _pos, _sectorObj, _canVote];
            diag_log format ["BA_TASKS: Found sector %1 at %2 (obj: %3, canVote: %4)", _sectorName, _pos, _sectorObj, _canVote];
        } else {
            // No ModuleWLSector_F found, add marker-only entry (no voting)
            private _sectorNum = (_markerName splitString "_") select 3;
            private _textMarker = format ["BIS_WL_sectorMrkrText_%1", _sectorNum];
            private _sectorName = markerText _textMarker;
            private _color = getMarkerColor _markerName;
            private _ownerStr = switch (_color) do {
                case "colorBLUFOR": { if (_mySide == west) then {"FRIENDLY"} else {"ENEMY"} };
                case "colorOPFOR": { if (_mySide == east) then {"FRIENDLY"} else {"ENEMY"} };
                default { "NEUTRAL" };
            };

            _taskItems pushBack ["warlords_sector", format ["%1: %2", _ownerStr, _sectorName], _pos, objNull, false];
            diag_log format ["BA_TASKS: No ModuleWLSector_F found near marker %1", _markerName];
        };
    } forEach _sectorMarkers;
};

// (Old BIS_WL_allSectors check removed - using marker-based detection above)

// Combat Patrol Detection
// Uses BIS_CP_locationArrFinal (populated by fn_cpinit.sqf)
private _isCombatPatrol = !isNil "BIS_CP_locationArrFinal"
    && { (missionNamespace getVariable ["BIS_CP_targetLocationID", -1]) == -1 }
    && { (missionNamespace getVariable ["BIS_CP_preset_locationSelection", 0]) != 1 };

// Combat Patrol status entry (will be added after sorting to keep at top)
private _cpStatusEntry = [];

if (_isCombatPatrol) then {
    diag_log "BA_TASKS: === COMBAT PATROL VOTING PHASE ===";

    // Get player's current vote
    private _currentVote = player getVariable ["BIS_CP_votedFor", -1];

    // Prepare status entry (added after sorting to keep at top)
    if (_currentVote >= 0 && _currentVote < count BIS_CP_locationArrFinal) then {
        private _votedName = (BIS_CP_locationArrFinal select _currentVote) select 1;
        _cpStatusEntry = ["combatpatrol_status", format ["VOTED: %1", _votedName], [0,0,0], -1, false];
    } else {
        _cpStatusEntry = ["combatpatrol_status", "Select a location from the list", [0,0,0], -1, false];
    };

    // Add each location as voteable entry
    {
        private _pos = _x select 0;
        private _name = _x select 1;
        private _size = _x select 2;

        // Determine location type label
        private _typeLabel = switch (true) do {
            case (_size >= 1.5): { "Capital" };
            case (_size >= 1): { "City" };
            default { "Village" };
        };

        private _isCurrentVote = (_forEachIndex == _currentVote);
        private _label = if (_isCurrentVote) then {
            format ["[VOTED] %1 (%2)", _name, _typeLabel]
        } else {
            format ["%1 (%2)", _name, _typeLabel]
        };

        // Array: [type, label, pos, locationIndex, canVote]
        _taskItems pushBack ["combatpatrol_location", _label, _pos, _forEachIndex, true];

    } forEach BIS_CP_locationArrFinal;

    diag_log format ["BA_TASKS: Added %1 Combat Patrol locations", count BIS_CP_locationArrFinal];
};

diag_log format ["BA_TASKS: Final task count = %1", count _taskItems];

// Sort tasks by distance from cursor (handle both Task objects and Warlords arrays)
_taskItems = [_taskItems, [], {
    private _pos = if (_x isEqualType []) then { _x select 2 } else { taskDestination _x };
    BA_cursorPos distance2D _pos
}, "ASCEND"] call BIS_fnc_sortBy;

// Add Combat Patrol status at the top (after sorting)
if (count _cpStatusEntry > 0) then {
    _taskItems = [_cpStatusEntry] + _taskItems;
};

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
