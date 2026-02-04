/*
 * Function: BA_fnc_updatePlayerNav
 * Per-frame update for player navigation system.
 *
 * Runs at 10Hz (every 0.1 seconds) and handles:
 * - Arrival detection (< 3m from destination)
 * - Breadcrumb progress (advance to next path point when close)
 * - Audio beacon pan calculation based on direction to waypoint
 * - Path deviation detection and recalculation
 * - Distance threshold announcements
 *
 * Arguments:
 *   None (called from EachFrame handler)
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_updatePlayerNav;
 */

// Skip if navigation not active
if (!BA_playerNavEnabled) exitWith {};

// Rate limit to 10Hz
private _currentTime = diag_tickTime;
if (_currentTime - BA_playerNavLastUpdateTime < BA_playerNavUpdateInterval) exitWith {};
BA_playerNavLastUpdateTime = _currentTime;

// Get the soldier (BA_originalUnit in observer mode, player otherwise)
private _soldier = if (BA_observerMode && {!isNull BA_originalUnit}) then {
    BA_originalUnit
} else {
    player
};

if (isNull _soldier || !alive _soldier) exitWith {
    ["Navigation stopped: soldier unavailable."] call BA_fnc_speak;
    [] call BA_fnc_clearPlayerWaypoint;
};

private _soldierPos = getPos _soldier;

// Calculate distance to final destination
private _distToDestination = _soldierPos distance2D BA_playerNavDestination;

// Check for arrival (within 3 meters of destination)
if (_distToDestination < BA_playerNavArrivalRadius) exitWith {
    ["Arrived at waypoint."] call BA_fnc_speak;
    [] call BA_fnc_clearPlayerWaypoint;
};

// Get current path target point
private _currentTarget = if (BA_playerNavPathIndex < count BA_playerNavPath) then {
    BA_playerNavPath select BA_playerNavPathIndex
} else {
    BA_playerNavDestination
};

// Check breadcrumb progress - advance to next point when close
private _distToCurrentTarget = _soldierPos distance2D _currentTarget;
if (_distToCurrentTarget < BA_playerNavBreadcrumbRadius && BA_playerNavPathIndex < (count BA_playerNavPath - 1)) then {
    BA_playerNavPathIndex = BA_playerNavPathIndex + 1;
    _currentTarget = BA_playerNavPath select BA_playerNavPathIndex;
    diag_log format ["Blind Assist: Advanced to path point %1", BA_playerNavPathIndex];
};

// Calculate direction to current target for audio pan
// getRelDir returns 0-360 where 0 = ahead, 90 = right, 180 = behind, 270 = left
private _relDir = _soldier getRelDir _currentTarget;

// Convert to pan: -1 (left) to +1 (right)
// 0 = ahead (pan 0), 90 = right (pan +1), 180 = behind (pan 0 but turn around), 270 = left (pan -1)
private _pan = 0;
if (_relDir <= 180) then {
    // Target is to the right (0-180)
    _pan = sin _relDir;  // 0 at 0, 1 at 90, 0 at 180
} else {
    // Target is to the left (181-359)
    _pan = sin _relDir;  // Negative: 0 at 180, -1 at 270, 0 at 360
};

// Update the beacon pan
"nvda_arma3_bridge" callExtension format ["beacon_update:%1", _pan];

// Check path deviation - find minimum distance from soldier to any path point
private _minDistToPath = 9999;
{
    private _distToPoint = _soldierPos distance2D _x;
    if (_distToPoint < _minDistToPath) then {
        _minDistToPath = _distToPoint;
    };
} forEach BA_playerNavPath;

// Trigger recalculation if too far from path (with cooldown)
if (_minDistToPath > BA_playerNavDeviationThreshold) then {
    if (_currentTime - BA_playerNavLastRecalcTime > BA_playerNavRecalcCooldown) then {
        BA_playerNavLastRecalcTime = _currentTime;
        ["Recalculating route."] call BA_fnc_speak;

        // Recalculate path from current position
        [_soldier, BA_playerNavDestination] call BA_fnc_calculateNavPath;
    };
};

// Announce distance progress
[_distToDestination] call BA_fnc_announceNavProgress;
