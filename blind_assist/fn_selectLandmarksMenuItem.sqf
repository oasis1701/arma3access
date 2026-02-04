/*
 * Function: BA_fnc_selectLandmarksMenuItem
 * Selects the current landmark and moves the cursor to it.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_selectLandmarksMenuItem;
 */

if (!BA_landmarksMenuActive) exitWith {};

private _currentItems = BA_landmarksItems select BA_landmarksCategoryIndex;
private _itemCount = count _currentItems;

if (_itemCount == 0) exitWith {
    ["No item selected."] call BA_fnc_speak;
};

private _currentIndex = BA_landmarksItemIndex select BA_landmarksCategoryIndex;
private _selectedItem = _currentItems select _currentIndex;

// Get position and name (check type based on category)
private _locPos = [];
private _name = "";

if (BA_landmarksCategoryIndex == 5) then {
    // Tasks category - could be Task object OR Warlords array
    if (_selectedItem isEqualType []) then {
        // Warlords entry: ["type", "name", [pos], sectorNum, canVote]
        private _type = _selectedItem select 0;
        _name = _selectedItem select 1;
        _locPos = _selectedItem select 2;

        // Skip status entries with no position
        if (_locPos isEqualTo [0,0,0]) exitWith {
            ["Cannot move to status item."] call BA_fnc_speak;
        };

        // Handle voting for sectors
        if (_type == "warlords_sector" && {count _selectedItem >= 5}) then {
            private _sectorObj = _selectedItem select 3;  // Sector object stored directly from BIS_WL_allSectors
            private _canVote = _selectedItem select 4;

            if (_canVote && {!isNull _sectorObj}) then {
                // Cast the vote using the correct Warlords variable (found in fn_wlsectorselectionstart.sqf)
                player setVariable ["BIS_WL_selectedSector", _sectorObj, true];
                BIS_WL_currentSelection = "voted";
                // Sector name is in bis_wl_sectortext variable
                private _voteName = _sectorObj getVariable ["bis_wl_sectortext", "sector"];
                diag_log format ["BA_VOTE: Voted for %1 (object: %2, type: %3)", _voteName, _sectorObj, typeOf _sectorObj];
                _name = format ["VOTED: %1", _voteName];
            } else {
                if (isNull _sectorObj) then {
                    diag_log "BA_VOTE: Cannot vote - sector object not available";
                };
            };
        };

        // Handle Combat Patrol voting
        if (_type == "combatpatrol_location" && {count _selectedItem >= 5}) then {
            private _locationIndex = _selectedItem select 3;
            private _canVote = _selectedItem select 4;

            if (_canVote && _locationIndex >= 0) then {
                // Cast the vote
                player setVariable ["BIS_CP_votedFor", _locationIndex, true];

                // Trigger countdown if this is the first vote
                if ((missionNamespace getVariable ["BIS_CP_voting_countdown_end", 0]) == 0) then {
                    private _votingTimer = missionNamespace getVariable ["BIS_CP_votingTimer", 15];
                    missionNamespace setVariable ["BIS_CP_voting_countdown_end", daytime + (_votingTimer / 3600), true];
                };

                private _voteName = if (!isNil "BIS_CP_locationArrFinal" && {_locationIndex < count BIS_CP_locationArrFinal}) then {
                    (BIS_CP_locationArrFinal select _locationIndex) select 1
                } else {
                    "location"
                };

                diag_log format ["BA_VOTE_CP: Voted for %1 (index: %2)", _voteName, _locationIndex];
                _name = format ["VOTED: %1", _voteName];
            };
        };
    } else {
        // Standard Task object
        _locPos = taskDestination _selectedItem;
        private _desc = taskDescription _selectedItem;
        _name = if (_desc isEqualType []) then { _desc select 1 } else { str _desc };
        if (_name == "") then { _name = str _selectedItem };
    };
} else {
    if (_selectedItem isEqualType "") then {
        // It's a marker name (string)
        _locPos = getMarkerPos _selectedItem;
        _name = markerText _selectedItem;
        if (_name == "") then { _name = _selectedItem };
    } else {
        // It's a location object
        _locPos = locationPosition _selectedItem;
        _name = text _selectedItem;
        if (_name == "") then {
            _name = [type _selectedItem] call BA_fnc_getLocationTypeName;
        };
    };
};

// Close the menu first
BA_landmarksMenuActive = false;
BA_landmarksCategoryIndex = 0;
BA_landmarksItemIndex = [0, 0, 0, 0, 0, 0];
BA_landmarksItems = [[], [], [], [], [], []];

// Clear road state since cursor is leaving the road
BA_currentRoad = objNull;
BA_atRoadEnd = false;
BA_lastTravelDirection = "";

// Move cursor to the location
[_locPos, false] call BA_fnc_setCursorPos;

// Announce the move
[format ["Cursor moved to %1.", _name]] call BA_fnc_speak;
