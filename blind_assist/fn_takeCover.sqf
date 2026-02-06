/*
 * Function: BA_fnc_takeCover
 * Finds nearest cover position relative to a threat and starts audio-guided
 * navigation there using the player nav system (same beacon as Y key waypoint).
 *
 * Threat determination (waterfall):
 *   1. Aim assist target (BA_aimAssistTarget) if alive
 *   2. Highest-threat enemy from nearTargets 1000m
 *   3. Player's facing direction as fallback
 *
 * Cover search:
 *   Scans terrain objects and nearby objects within 35m, picks the closest
 *   position that has line-of-sight blockage from the threat.
 *
 * Toggle: Press C to find cover and start guidance. Press C again to cancel.
 * Does not affect aim assist or target lock.
 *
 * Hotkey: C (DIK 46) - manual mode only, not in vehicle
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_takeCover;
 */

// --- STEP 1: Toggle guard ---
// If cover nav is currently active, cancel it
if (!isNil "BA_takingCover" && {BA_takingCover} && {BA_playerNavEnabled}) exitWith {
    [] call BA_fnc_clearPlayerWaypoint;
    BA_takingCover = false;
    ["Cover cancelled."] call BA_fnc_speak;
};
BA_takingCover = true;

// --- STEP 2: Determine threat direction ---
private _dangerPos = [0,0,0];
private _announceText = "";

// A. Aim assist target
if (!isNil "BA_aimAssistTarget" && {!isNull BA_aimAssistTarget} && {alive BA_aimAssistTarget}) then {
    _dangerPos = getPosASL BA_aimAssistTarget;
    _announceText = "Taking cover against target.";
} else {
    // B. nearTargets fallback
    private _threats = player nearTargets 1000;
    // Filter: subjectiveCost > 0 (enemy threat) AND alive
    private _enemies = _threats select {
        (_x select 4) > 0 && {alive (_x select 1)}
    };

    if (count _enemies > 0) then {
        // Pick highest subjectiveCost
        private _bestEnemy = _enemies select 0;
        private _bestCost = _bestEnemy select 4;
        {
            if ((_x select 4) > _bestCost) then {
                _bestEnemy = _x;
                _bestCost = _x select 4;
            };
        } forEach _enemies;

        private _enemyObj = _bestEnemy select 1;
        _dangerPos = getPosASL _enemyObj;

        // Get display name from CfgVehicles
        private _displayName = getText (configFile >> "CfgVehicles" >> typeOf _enemyObj >> "displayName");
        if (_displayName == "") then { _displayName = "enemy" };
        _announceText = format ["Taking cover against %1.", _displayName];
    } else {
        // C. Facing direction fallback
        _dangerPos = AGLToASL (player modelToWorld [0, 100, 1.5]);
        private _compassDir = [getDir player] call BA_fnc_bearingToCompass;
        _announceText = format ["Taking cover against %1.", _compassDir];
    };
};

// --- STEP 3: Find cover ---
private _playerPos = getPos player;
private _dangerPosAGL = ASLToAGL _dangerPos;

// Scan terrain objects within 35m
private _terrainObjects = nearestTerrainObjects [_playerPos, ["TREE", "SMALL TREE", "BUSH", "WALL", "FENCE", "ROCK", "ROCKS", "HOUSE", "RUIN"], 35, false];

// Also scan nearestObjects for vehicles, ammo boxes, walls
private _nearObjects = nearestObjects [_playerPos, ["Car", "Tank", "Ship", "ReammoBox_F", "Wall", "Fence_F"], 35];

// Combine all candidates
private _candidates = _terrainObjects + _nearObjects;

private _bestPos = [];
private _bestDist = 9999;

{
    private _obj = _x;
    private _objPos = getPos _obj;

    // Size filter: skip tiny objects
    private _bb = boundingBoxReal _obj;
    private _bbMin = _bb select 0;
    private _bbMax = _bb select 1;
    private _maxWidth = (abs ((_bbMax select 0) - (_bbMin select 0))) max (abs ((_bbMax select 1) - (_bbMin select 1)));
    if (_maxWidth < 0.5) then { continue };

    // Calculate hiding spot: 2.5m behind object (opposite side from threat)
    private _dirFromThreat = _dangerPosAGL getDir _objPos;
    private _hidePos = _objPos getPos [2.5, _dirFromThreat];
    // _hidePos is [x, y, 0] AGL — Z=0 means ground level

    // Raycast safety: check if object blocks line of sight from threat
    // Convert AGL ground pos to ASL, then add chest height
    private _hidePosASL = AGLToASL _hidePos;
    private _hidePosChest = [_hidePosASL select 0, _hidePosASL select 1, (_hidePosASL select 2) + 1.0];
    private _dangerEye = [_dangerPos select 0, _dangerPos select 1, (_dangerPos select 2) + 1.5];

    private _blocked = lineIntersects [_dangerEye, _hidePosChest, objNull, player];

    // Also check terrainIntersect as backup
    if (!_blocked) then {
        _blocked = terrainIntersect [ASLToAGL _dangerEye, ASLToAGL _hidePosChest];
    };

    if (_blocked) then {
        // Valid cover! Check distance
        private _runDist = _playerPos distance2D _hidePos;
        if (_runDist < _bestDist) then {
            _bestDist = _runDist;
            _bestPos = _hidePos;
        };
    };
} forEach _candidates;

// --- STEP 4: Start navigation to cover ---
if (count _bestPos == 0) then {
    // No cover found - go prone
    ["No cover found! Going prone!"] call BA_fnc_speak;
    player setUnitPos "DOWN";
    BA_takingCover = false;
} else {
    private _soldier = player;

    // Clear any existing navigation
    if (BA_playerNavEnabled) then {
        [] call BA_fnc_clearPlayerWaypoint;
    };

    // Set up navigation state (mirrors fn_setPlayerWaypoint.sqf)
    BA_playerNavEnabled = true;
    BA_playerNavDestination = +_bestPos;
    BA_playerNavLastDistAnnounced = -1;
    BA_playerNavLastRecalcTime = 0;
    BA_playerNavPathIndex = 0;
    BA_playerNavPath = [];

    // Create marker at cover position
    BA_playerNavMarker = format ["BA_navWaypoint_%1", round random 99999];
    createMarkerLocal [BA_playerNavMarker, BA_playerNavDestination];
    BA_playerNavMarker setMarkerTypeLocal "mil_objective";
    BA_playerNavMarker setMarkerColorLocal "ColorOrange";
    BA_playerNavMarker setMarkerTextLocal "Cover";

    // Announce threat + distance
    private _distance = (getPos _soldier) distance2D BA_playerNavDestination;
    private _distRounded = round _distance;
    [format ["%1 %2 meters.", _announceText, _distRounded]] call BA_fnc_speak;

    // Initialize distance threshold for progress announcements
    {
        if (_distance > _x) exitWith {
            BA_playerNavLastDistAnnounced = _x;
        };
    } forEach BA_playerNavThresholds;

    diag_log format ["Blind Assist: Cover waypoint set at %1, distance %2m", BA_playerNavDestination, _distRounded];

    // Start pathfinding + audio beacon
    [_soldier, BA_playerNavDestination] call BA_fnc_calculateNavPath;
};
