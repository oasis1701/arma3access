/*
 * Function: BA_fnc_followRoad
 * Moves cursor along the current road in the specified compass direction.
 * Chooses the road endpoint that is closest to the requested direction.
 *
 * Arguments:
 *   0: _direction - Compass direction: "North", "South", "East", or "West"
 *
 * Return Value:
 *   Boolean - true if successfully moved along road
 *
 * Example:
 *   ["North"] call BA_fnc_followRoad;
 */

params [
    ["_direction", "North", [""]]
];

// Must be in observer mode with cursor active and road mode enabled
if (!BA_observerMode || !BA_cursorActive || !BA_roadModeEnabled) exitWith { false };

// If no current road, snap to nearest first
if (isNull BA_currentRoad) exitWith {
    [_direction] call BA_fnc_snapToRoad
};

// Get current road info
private _roadInfo = getRoadInfo BA_currentRoad;
if (count _roadInfo == 0) exitWith {
    BA_currentRoad = objNull;
    ["Road data unavailable."] call BA_fnc_speak;
    false
};

_roadInfo params ["_mapType", "_width", "_isPedestrian", "_texture", "_textureEnd", "_material", "_begPos", "_endPos", "_isBridge"];

// Convert direction to target bearing
private _targetBearing = switch (_direction) do {
    case "North": { 0 };
    case "East":  { 90 };
    case "South": { 180 };
    case "West":  { 270 };
    default { 0 };
};

// Get cursor position
private _cursorPos2D = [BA_cursorPos select 0, BA_cursorPos select 1];

// Calculate bearing from cursor to each endpoint
private _bearingToBeg = _cursorPos2D getDir _begPos;
private _bearingToEnd = _cursorPos2D getDir _endPos;

// Choose endpoint closest to target bearing
private _diffBeg = abs(_bearingToBeg - _targetBearing);
if (_diffBeg > 180) then { _diffBeg = 360 - _diffBeg };
private _diffEnd = abs(_bearingToEnd - _targetBearing);
if (_diffEnd > 180) then { _diffEnd = 360 - _diffEnd };

// Calculate distances to endpoints to detect if we're standing at one
private _distToBeg = _cursorPos2D distance2D _begPos;
private _distToEnd = _cursorPos2D distance2D _endPos;

// If very close to one endpoint, only consider direction to the OTHER endpoint
// (bearing calculation is unstable at near-zero distance)
private _targetPos = [];
if (_distToBeg < 3) then {
    // At beginning endpoint - can only go toward end
    _targetPos = _endPos;
} else {
    if (_distToEnd < 3) then {
        // At end endpoint - can only go toward beginning
        _targetPos = _begPos;
    } else {
        // In middle of segment - pick closest direction to requested
        _targetPos = if (_diffBeg < _diffEnd) then { _begPos } else { _endPos };
    };
};
private _fromPos = if (_diffBeg < _diffEnd) then { _endPos } else { _begPos };

// Calculate movement step (approximately 10-15 meters per keypress)
private _stepSize = 12;

// Vector from current position to target endpoint
private _toTarget = [
    (_targetPos select 0) - (_cursorPos2D select 0),
    (_targetPos select 1) - (_cursorPos2D select 1)
];
private _distToTarget = sqrt ((_toTarget select 0)^2 + (_toTarget select 1)^2);

// If we're very close to target endpoint, try to continue to next segment
if (_distToTarget < _stepSize * 1.5) then {
    // Multi-method road detection to avoid false "Road ends" announcements
    // nearRoads finds roads by CENTER point, not endpoints, so we need multiple approaches

    // Method 1: Check for road directly at target position (most reliable)
    private _roadAtTarget = roadAt _targetPos;

    // Method 2: Use Arma's road graph with extended search
    private _graphConnected = roadsConnectedTo [BA_currentRoad, true];

    // Method 3: Find roads within large radius (road segments can be 40m+ long)
    private _nearbyRoads = _targetPos nearRoads 50;

    // Combine all found roads (remove duplicates)
    private _allRoads = [];

    if (!isNull _roadAtTarget) then {
        _allRoads pushBackUnique _roadAtTarget;
    };

    {
        _allRoads pushBackUnique _x;
    } forEach _graphConnected;

    {
        _allRoads pushBackUnique _x;
    } forEach _nearbyRoads;

    // Filter to roads with an endpoint near target position (within 15m)
    private _connectedRoads = _allRoads select {
        private _info = getRoadInfo _x;
        if (count _info == 0) then { false } else {
            _info params ["", "", "", "", "", "", "_b", "_e"];
            (_targetPos distance2D _b < 15) || (_targetPos distance2D _e < 15)
        };
    };

    if (count _connectedRoads == 0) exitWith {
        // Road truly ends - no roads found by any method
        ["Road ends."] call BA_fnc_speak;
        BA_currentRoad = objNull;
        false
    };

    // Check for intersection (more than 1 connected road)
    private _isIntersection = [BA_currentRoad, _targetPos] call BA_fnc_detectIntersection;

    if (_isIntersection) then {
        // Announce intersection with all available directions
        [BA_currentRoad, _targetPos, 0] call BA_fnc_announceIntersection;
    };

    // Find the road that best continues in the requested direction
    private _bestRoad = objNull;
    private _bestAngle = 180;

    {
        private _nextRoad = _x;
        if (_nextRoad isEqualTo BA_currentRoad) then { continue };

        private _nextInfo = getRoadInfo _nextRoad;
        if (count _nextInfo == 0) then { continue };

        _nextInfo params ["", "", "", "", "", "", "_nextBeg", "_nextEnd"];

        // Determine which endpoint connects to our target
        private _nextStart = if (_nextBeg distance2D _targetPos < _nextEnd distance2D _targetPos) then { _nextBeg } else { _nextEnd };
        private _nextTarget = if (_nextStart isEqualTo _nextBeg) then { _nextEnd } else { _nextBeg };

        // Calculate bearing of next road segment (away from intersection)
        private _nextBearing = _nextStart getDir _nextTarget;

        // Angular difference from requested direction
        private _angleDiff = abs (_nextBearing - _targetBearing);
        if (_angleDiff > 180) then { _angleDiff = 360 - _angleDiff };

        // Choose road closest to requested direction
        if (_angleDiff < _bestAngle) then {
            _bestRoad = _nextRoad;
            _bestAngle = _angleDiff;
        };
    } forEach _connectedRoads;

    if (isNull _bestRoad) exitWith {
        ["Road ends."] call BA_fnc_speak;
        BA_currentRoad = objNull;
        false
    };

    // Switch to new road
    private _oldType = [_roadInfo] call BA_fnc_getRoadTypeDescription;
    BA_currentRoad = _bestRoad;
    BA_lastRoadInfo = getRoadInfo BA_currentRoad;

    // Check for road type change
    private _newType = [BA_lastRoadInfo] call BA_fnc_getRoadTypeDescription;
    if (_oldType != _newType) then {
        [format ["Road becomes %1.", _newType]] call BA_fnc_speak;
    };

    // Move cursor to transition point
    private _z = getTerrainHeightASL _targetPos;
    BA_cursorPos = [_targetPos select 0, _targetPos select 1, _z];
};

// Calculate new position along road
if (_distToTarget >= _stepSize) then {
    // Normalize direction vector
    private _dirNorm = [
        (_toTarget select 0) / _distToTarget,
        (_toTarget select 1) / _distToTarget
    ];

    // Calculate new position
    private _newX = (_cursorPos2D select 0) + (_dirNorm select 0) * _stepSize;
    private _newY = (_cursorPos2D select 1) + (_dirNorm select 1) * _stepSize;
    private _newZ = getTerrainHeightASL [_newX, _newY];

    BA_cursorPos = [_newX, _newY, _newZ];

    // Get road type for announcement
    private _roadType = [_roadInfo] call BA_fnc_getRoadTypeDescription;

    // Calculate actual travel direction
    private _actualBearing = _cursorPos2D getDir [_newX, _newY];
    private _actualDir = [_actualBearing] call BA_fnc_bearingToCompass;

    // Check for bridge
    if (_isBridge) then {
        private _bridgeLength = _begPos distance2D _endPos;
        [format ["Bridge. %1 meters %2.", round _bridgeLength, toLower _actualDir]] call BA_fnc_speak;
    } else {
        // Announce: "Main road. 12 meters northeast."
        [format ["%1. %2 meters %3.", _roadType, round _stepSize, toLower _actualDir]] call BA_fnc_speak;
    };
};

// Auto-refresh scanner
[] call BA_fnc_scanObjects;

true
