/*
 * Function: BA_fnc_announceNavProgress
 * Announces distance when crossing threshold markers.
 *
 * Thresholds:
 *   >= 100m: Every 50m (1050, 1000, 950, ... 150, 100)
 *   < 100m:  Every 10m (90, 80, 70, 60, 50, 40, 30, 20, 10)
 *
 * Arguments:
 *   0: Number - Current distance to destination in meters
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [75] call BA_fnc_announceNavProgress;
 */

params [["_distance", 0, [0]]];

// Calculate the threshold we just crossed
private _threshold = -1;

if (_distance >= 100) then {
    // 50m intervals: round down to nearest 50
    _threshold = (floor (_distance / 50)) * 50;
} else {
    // 10m intervals: round down to nearest 10
    _threshold = (floor (_distance / 10)) * 10;
};

// Announce if we crossed a new threshold (lower than last announced)
if (_threshold > 0 && (_threshold < BA_playerNavLastDistAnnounced || BA_playerNavLastDistAnnounced < 0)) then {
    BA_playerNavLastDistAnnounced = _threshold;
    [format ["%1 meters.", _threshold]] call BA_fnc_speak;
};
