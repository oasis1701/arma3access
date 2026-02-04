/*
 * Function: BA_fnc_calculateNavPath
 * Calculates navigation path using Arma 3's pathfinding.
 *
 * Automatically detects vehicle type and uses appropriate pathfinding:
 *   - man: Infantry on foot
 *   - car: Cars, trucks, motorcycles
 *   - tank: Tanks, tracked APCs
 *   - wheeled_APC: Wheeled APCs
 *   - boat: Boats, ships
 *   - helicopter: Helicopters
 *   - plane: Fixed-wing aircraft
 *
 * Arguments:
 *   0: Object - Soldier to navigate (default: player or BA_originalUnit)
 *   1: Array - Destination position [x, y, z]
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [player, BA_cursorPos] call BA_fnc_calculateNavPath;
 */

params [
    ["_soldier", objNull, [objNull]],
    ["_destination", [], [[]]]
];

// Validate inputs
if (isNull _soldier) exitWith {
    ["Navigation error: No soldier."] call BA_fnc_speak;
};

if (count _destination < 2) exitWith {
    ["Navigation error: Invalid destination."] call BA_fnc_speak;
};

private _startPos = getPos _soldier;

// Detect vehicle type for appropriate pathfinding
private _vehicle = vehicle _soldier;
private _pathType = "man";

if (_soldier != _vehicle) then {
    if (_vehicle isKindOf "Helicopter") then {
        _pathType = "helicopter";
    } else {
        if (_vehicle isKindOf "Plane") then {
            _pathType = "plane";
        } else {
            if (_vehicle isKindOf "Ship") then {
                _pathType = "boat";
            } else {
                if (_vehicle isKindOf "Tank") then {
                    _pathType = "tank";
                } else {
                    if (_vehicle isKindOf "WheeledAPC") then {
                        _pathType = "wheeled_APC";
                    } else {
                        _pathType = "car";
                    };
                };
            };
        };
    };
};

// Use isNil to ensure EH is added before path calculation (per wiki recommendation)
isNil {
    (calculatePath [_pathType, "safe", _startPos, _destination]) addEventHandler ["PathCalculated", {
        params ["_agent", "_path"];

        // Bug workaround: PathCalculated fires twice
        // First call has real path, second has 2 identical end points
        if (count _path == 2 && {(_path select 0) isEqualTo (_path select 1)}) exitWith {};

        // Check if path was found
        if (count _path == 0) exitWith {
            ["Route blocked. Try a different waypoint."] call BA_fnc_speak;
            [] call BA_fnc_clearPlayerWaypoint;
        };

        // Store path
        BA_playerNavPath = _path;
        BA_playerNavPathIndex = 0;

        // Start the audio beacon
        "nvda_arma3_bridge" callExtension "beacon_start";

        // Add the EachFrame handler for navigation updates
        BA_playerNavEHId = addMissionEventHandler ["EachFrame", {
            [] call BA_fnc_updatePlayerNav;
        }];

        // Delete the temporary agent
        deleteVehicle _agent;
    }];
};

