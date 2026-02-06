/*
 * Function: BA_fnc_findLookout
 * Finds the best lookout/overwatch position within search radius using
 * a lighthouse scan algorithm (raycasting in 8 directions).
 *
 * Toggle: If lookout nav is active, cancels it instead.
 *
 * Arguments:
 *   0: NUMBER - Search radius in meters (30, 50, or 100)
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [50] call BA_fnc_findLookout;
 */

params ["_searchRadius"];

// --- STEP 1: Toggle guard ---
if (BA_lookoutNavActive && {BA_playerNavEnabled}) exitWith {
    [] call BA_fnc_clearPlayerWaypoint;
    BA_lookoutNavActive = false;
    ["Lookout cancelled."] call BA_fnc_speak;
};
BA_lookoutNavActive = true;

// --- STEP 2: Announce ---
["Analyzing terrain."] call BA_fnc_speak;

// --- STEP 3: Generate candidates ---
private _playerPos = getPos player;
private _playerASL = getPosASL player;
private _playerAlt = _playerASL select 2;
private _candidates = [];

// Multi-ring terrain sampling
private _rings = switch (true) do {
    case (_searchRadius <= 30): { [10, 20, 30] };
    case (_searchRadius <= 50): { [15, 30, 50] };
    case (_searchRadius <= 100): { [25, 50, 75, 100] };
    default { [50, 100, 200, 300, 400] };
};

// 8 directions (every 45 degrees)
private _scanDirs = [0, 45, 90, 135, 180, 225, 270, 315];

{
    private _ringDist = _x;
    {
        private _dir = _x;
        private _pos = _playerPos getPos [_ringDist, _dir];
        // Get terrain height at position
        _pos set [2, 0];
        _candidates pushBack _pos;
    } forEach _scanDirs;
} forEach _rings;

// --- STEP 4: Lighthouse scan scoring ---
private _bestScore = -1;
private _bestDist = 9999;
private _bestPos = [];
private _bestClear = 0;
private _bestHeightDiff = 0;

// Height weight scales with search radius: 0.3 at 30m, 1.0 at 100m, 4.0 at 400m
private _heightWeight = _searchRadius / 100;

private _rayDist = 150;

{
    private _candidatePos = _x;
    // Get ASL height at candidate (terrain + building floor)
    private _candidateASL = AGLToASL _candidatePos;
    private _eyeHeight = (_candidateASL select 2) + 1.7;
    private _eyePos = [_candidateASL select 0, _candidateASL select 1, _eyeHeight];

    // Cast rays in 8 directions
    private _clearCount = 0;
    {
        private _rayDir = _x;
        // Target point at _rayDist in this direction, same height
        private _targetAGL = _candidatePos getPos [_rayDist, _rayDir];
        private _targetASL = AGLToASL _targetAGL;
        private _targetEye = [_targetASL select 0, _targetASL select 1, _eyeHeight];

        // Check line of sight (not blocked by terrain or objects)
        private _terrainBlocked = terrainIntersect [ASLToAGL _eyePos, ASLToAGL _targetEye];
        private _objectBlocked = lineIntersects [_eyePos, _targetEye, objNull, objNull];

        if (!_terrainBlocked && !_objectBlocked) then {
            _clearCount = _clearCount + 1;
        };
    } forEach _scanDirs;

    // Continuous height bonus: every meter above player scaled by search radius
    private _heightDiff = (_eyeHeight - _playerAlt) max 0;
    private _score = _clearCount + (_heightDiff * _heightWeight);

    // Select winner: highest score, tie-break by closest distance
    private _dist = _playerPos distance2D _candidatePos;
    if (_score > _bestScore || {_score == _bestScore && _dist < _bestDist}) then {
        _bestScore = _score;
        _bestDist = _dist;
        _bestPos = _candidatePos;
        _bestClear = _clearCount;
        _bestHeightDiff = _heightDiff;
    };
} forEach _candidates;

// --- STEP 5: Navigate to winner ---
if (count _bestPos == 0 || _bestScore <= 0) exitWith {
    ["No lookout found."] call BA_fnc_speak;
    BA_lookoutNavActive = false;
};

private _soldier = player;

// Clear any existing navigation
if (BA_playerNavEnabled) then {
    [] call BA_fnc_clearPlayerWaypoint;
};

// Set up navigation state (mirrors fn_takeCover.sqf)
BA_playerNavEnabled = true;
BA_playerNavDestination = +_bestPos;
BA_playerNavLastDistAnnounced = -1;
BA_playerNavLastRecalcTime = 0;
BA_playerNavPathIndex = 0;
BA_playerNavPath = [];

// Create marker at lookout position
BA_playerNavMarker = format ["BA_navWaypoint_%1", round random 99999];
createMarkerLocal [BA_playerNavMarker, BA_playerNavDestination];
BA_playerNavMarker setMarkerTypeLocal "mil_objective";
BA_playerNavMarker setMarkerColorLocal "ColorGreen";
BA_playerNavMarker setMarkerTextLocal "Lookout";

// Announce direction + distance + score
private _bearing = _playerPos getDir _bestPos;
private _compassDir = [_bearing] call BA_fnc_bearingToCompass;
private _distRounded = round _bestDist;
private _heightRounded = round _bestHeightDiff;
if (_heightRounded > 1) then {
    [format ["Lookout found. %1, %2 meters. %3 of 8 clear. %4 meters up.", _compassDir, _distRounded, _bestClear, _heightRounded]] call BA_fnc_speak;
} else {
    [format ["Lookout found. %1, %2 meters. %3 of 8 clear.", _compassDir, _distRounded, _bestClear]] call BA_fnc_speak;
};

// Initialize distance threshold for progress announcements
private _distance = _bestDist;
{
    if (_distance > _x) exitWith {
        BA_playerNavLastDistAnnounced = _x;
    };
} forEach BA_playerNavThresholds;

diag_log format ["Blind Assist: Lookout waypoint set at %1, distance %2m, clear %3/8, height +%4m, score %5", BA_playerNavDestination, _distRounded, _bestClear, round _bestHeightDiff, _bestScore];

// Start pathfinding + audio beacon
[_soldier, BA_playerNavDestination] call BA_fnc_calculateNavPath;
