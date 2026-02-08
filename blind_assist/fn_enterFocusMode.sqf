/*
 * Function: BA_fnc_enterFocusMode
 * Enters focus mode - enables cursor/scanner/landmarks while player keeps control.
 *
 * Focus mode uses a transparent dialog overlay to block engine-level inputs
 * (flashlight, reload, soldier turning) while keeping the simulation running.
 * Auto-exits when player moves (WASD) or presses ESC.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Boolean - true if successfully entered focus mode
 *
 * Example:
 *   [] call BA_fnc_enterFocusMode;
 */

// Don't enter if already in focus mode or observer mode
if (BA_focusMode) exitWith {
    ["Already in focus mode."] call BA_fnc_speak;
    false
};

if (BA_observerMode) exitWith {
    ["In observer mode. Full features available."] call BA_fnc_speak;
    false
};

// Set state
BA_focusMode = true;

// Initialize cursor at player's position
BA_cursorPos = getPos player;
BA_cursorActive = true;

// Clear road state
BA_currentRoad = objNull;
BA_atRoadEnd = false;
BA_lastTravelDirection = "";

// Create the transparent dialog overlay
// This blocks engine inputs (flashlight, reload, turning) while keeping simulation running
createDialog "BA_FocusModeDialog";

// Add KeyDown handler to the dialog
private _display = findDisplay 9100;
if (isNull _display) exitWith {
    BA_focusMode = false;
    BA_cursorActive = false;
    ["Focus mode dialog failed to create."] call BA_fnc_speak;
    false
};

_display displayAddEventHandler ["KeyDown", {
    params ["_display", "_key", "_shift", "_ctrl", "_alt"];

    // Backtick/Tilde (key 41) - Exit focus mode
    if (_key == 41 && !_ctrl && !_shift && !_alt) exitWith {
        closeDialog 0;
        true
    };

    // ESC (key 1) - Exit focus mode
    if (_key == 1) exitWith {
        closeDialog 0;
        true
    };

    // WASD (17, 30, 31, 32) - Exit focus mode and pass key through
    if (_key in [17, 30, 31, 32] && !_ctrl && !_alt) exitWith {
        [] call BA_fnc_exitFocusMode;
        false  // Let movement key through to Arma
    };

    // G key (34) - Group menu not available in focus mode
    if (_key == 34 && !_ctrl && !_shift && !_alt) exitWith {
        ["Group menu requires observer mode."] call BA_fnc_speak;
        true
    };

    // O key (24) without Ctrl - Open squad member menu (or close active menus)
    if (_key == 24 && !_ctrl && !_shift && !_alt) exitWith {
        if (BA_orderMenuActive) then {
            [] call BA_fnc_closeOrderMenu;
            BA_pendingSquadUnit = objNull;
        } else {
            if (BA_squadMenuActive) then {
                [] call BA_fnc_closeSquadMenu;
            } else {
                [] call BA_fnc_openSquadMenu;
            };
        };
        true
    };

    // When squad member menu is active, intercept navigation keys
    if (BA_squadMenuActive) exitWith {
        switch (_key) do {
            case 200: { ["up"] call BA_fnc_navigateSquadMenu; true };
            case 208: { ["down"] call BA_fnc_navigateSquadMenu; true };
            case 28: { [] call BA_fnc_selectSquadMenuItem; true };
            case 1: { [] call BA_fnc_closeSquadMenu; true };
            default { true };
        }
    };

    // When order menu is active, intercept navigation keys
    if (BA_orderMenuActive) exitWith {
        switch (_key) do {
            case 200: { ["up"] call BA_fnc_navigateOrderMenu; true };
            case 208: { ["down"] call BA_fnc_navigateOrderMenu; true };
            case 28: { [] call BA_fnc_selectOrderMenuItem; true };
            case 1: { [] call BA_fnc_closeOrderMenu; BA_pendingSquadUnit = objNull; true };
            default { true };
        }
    };

    // L key (38) - Open/close landmarks menu
    if (_key == 38 && !_ctrl && !_shift && !_alt) exitWith {
        if (BA_landmarksMenuActive) then {
            [] call BA_fnc_closeLandmarksMenu;
        } else {
            [] call BA_fnc_openLandmarksMenu;
        };
        true
    };

    // Landmarks menu navigation (when active)
    if (BA_landmarksMenuActive) exitWith {
        switch (_key) do {
            case 200: { ["up"] call BA_fnc_navigateLandmarksMenu; true };
            case 208: { ["down"] call BA_fnc_navigateLandmarksMenu; true };
            case 203: { ["left"] call BA_fnc_navigateLandmarksMenu; true };
            case 205: { ["right"] call BA_fnc_navigateLandmarksMenu; true };
            case 28: { [] call BA_fnc_selectLandmarksMenuItem; true };
            default { true };
        }
    };

    // N key (49) - Open/close BA Menu
    if (_key == 49 && !_ctrl && !_shift && !_alt) exitWith {
        if (BA_menuActive) then {
            [] call BA_fnc_closeBAMenu;
        } else {
            [] call BA_fnc_openBAMenu;
        };
        true
    };

    // BA Menu navigation (when active)
    if (BA_menuActive) exitWith {
        switch (_key) do {
            case 200: { ["up"] call BA_fnc_navigateBAMenu; true };
            case 208: { ["down"] call BA_fnc_navigateBAMenu; true };
            case 203: { ["left"] call BA_fnc_navigateBAMenu; true };
            case 205: { ["right"] call BA_fnc_navigateBAMenu; true };
            case 28: { [] call BA_fnc_selectBAMenuItem; true };
            case 1: { [] call BA_fnc_closeBAMenu; true };
            default { true };
        }
    };

    // Lookout menu navigation (when active)
    if (BA_lookoutMenuActive) exitWith {
        switch (_key) do {
            case 200: { ["up"] call BA_fnc_navigateLookoutMenu; true };
            case 208: { ["down"] call BA_fnc_navigateLookoutMenu; true };
            case 28: {
                // Select: get radius, close menu, exit focus mode, run findLookout
                private _item = BA_lookoutMenuItems select BA_lookoutMenuIndex;
                private _radius = _item select 1;
                BA_lookoutMenuActive = false;
                BA_lookoutMenuItems = [];
                BA_lookoutMenuIndex = 0;
                closeDialog 0;
                [_radius] call BA_fnc_findLookout;
                true
            };
            case 1: { [] call BA_fnc_closeLookoutMenu; true };
            case 17: { if (_ctrl) then { [] call BA_fnc_closeLookoutMenu; }; true };
            default { true };
        }
    };

    // Intersection menu navigation (when active)
    if (BA_intersectionMenuActive) exitWith {
        switch (_key) do {
            case 200: { [-1] call BA_fnc_navigateIntersectionMenu; true };
            case 208: { [1] call BA_fnc_navigateIntersectionMenu; true };
            case 28: { [] call BA_fnc_selectIntersectionMenuItem; true };
            default { true };
        }
    };

    // R key (19) - Toggle road exploration mode
    if (_key == 19 && !_ctrl && !_shift && !_alt) exitWith {
        [] call BA_fnc_toggleRoadMode;
        true
    };

    // Ctrl+R (key 19) - Open intersection menu (in road mode)
    if (_key == 19 && _ctrl && !_shift && !_alt) exitWith {
        if (BA_intersectionMenuActive) then {
            [] call BA_fnc_closeIntersectionMenu;
        } else {
            [] call BA_fnc_openIntersectionMenu;
        };
        true
    };

    // Ctrl+W (key 17) - Lookout menu toggle / cancel lookout nav
    if (_key == 17 && _ctrl && !_shift && !_alt) exitWith {
        // If lookout nav active, cancel it
        if (BA_lookoutNavActive && {BA_playerNavEnabled}) exitWith {
            [] call BA_fnc_clearPlayerWaypoint;
            BA_lookoutNavActive = false;
            ["Lookout cancelled."] call BA_fnc_speak;
            true
        };
        // Toggle lookout menu
        if (BA_lookoutMenuActive) then {
            [] call BA_fnc_closeLookoutMenu;
        } else {
            [] call BA_fnc_openLookoutMenu;
        };
        true
    };

    // Arrow keys (200=Up, 208=Down, 203=Left, 205=Right) - Cursor movement
    if (_key in [200, 208, 203, 205]) exitWith {
        private _direction = switch (_key) do {
            case 200: { "North" };
            case 208: { "South" };
            case 205: { "East" };
            case 203: { "West" };
        };

        // Check if road mode is enabled
        if (BA_roadModeEnabled) exitWith {
            if (_alt && !_ctrl && !_shift) then {
                [_direction] call BA_fnc_followRoad;
            } else {
                if (_shift && !_ctrl && !_alt) then {
                    [_direction] call BA_fnc_selectRoadAtIntersection;
                } else {
                    if (_alt || _shift || _ctrl) then {
                        ["Road mode: Alt to follow, Shift to turn."] call BA_fnc_speak;
                    };
                };
            };
            true
        };

        // Normal cursor movement
        private _distance = if (_alt && !_ctrl && !_shift) then { 10 }
            else { if (_shift && !_ctrl && !_alt) then { 100 }
            else { if (_ctrl && !_shift && !_alt) then { 1000 } else { 0 } } };
        if (_distance > 0) then {
            [_direction, _distance] call BA_fnc_moveCursor;
        } else {
            if (_alt || _shift || _ctrl) then {
                ["Use Alt for 10m, Shift for 100m, Ctrl for 1000m."] call BA_fnc_speak;
            };
        };
        true
    };

    // I key (23) - Detailed scan at cursor
    if (_key == 23 && !_ctrl && !_shift && !_alt) exitWith {
        [] call BA_fnc_announceCursorDetailed;
        true
    };

    // Home (199) or Backspace (14) - Snap cursor to player
    if (_key in [199, 14] && !_ctrl && !_shift && !_alt) exitWith {
        BA_cursorPos = getPos player;
        ["Cursor at your position."] call BA_fnc_speak;
        [] call BA_fnc_announceCursorBrief;
        true
    };

    // U key (22) - Cycle scanner range
    if (_key == 22 && !_ctrl && !_shift && !_alt) exitWith {
        [] call BA_fnc_cycleScannerRange;
        true
    };

    // PageUp (201) - Scanner navigation
    if (_key == 201) exitWith {
        if (_ctrl && !_shift && !_alt) then {
            ["category_prev"] call BA_fnc_navigateScanner;
        } else {
            if (!_ctrl && !_shift && !_alt) then {
                ["object_prev"] call BA_fnc_navigateScanner;
            };
        };
        true
    };

    // PageDown (209) - Scanner navigation
    if (_key == 209) exitWith {
        if (_ctrl && !_shift && !_alt) then {
            ["category_next"] call BA_fnc_navigateScanner;
        } else {
            if (!_ctrl && !_shift && !_alt) then {
                ["object_next"] call BA_fnc_navigateScanner;
            };
        };
        true
    };

    // J key (36) - Jump to selected scanner object
    if (_key == 36 && !_ctrl && !_shift && !_alt) exitWith {
        [] call BA_fnc_jumpToScannerObject;
        true
    };

    // Y key (21) - Set player waypoint
    if (_key == 21 && !_ctrl && !_shift && !_alt) exitWith {
        [] call BA_fnc_setPlayerWaypoint;
        true
    };

    // Ctrl+Y (21) - Clear player waypoint
    if (_key == 21 && _ctrl && !_shift && !_alt) exitWith {
        if (BA_playerNavEnabled) then {
            [] call BA_fnc_clearPlayerWaypoint;
            ["Waypoint cleared."] call BA_fnc_speak;
        } else {
            ["No active waypoint."] call BA_fnc_speak;
        };
        true
    };

    // Alt+1 through Alt+9: Unit status categories
    if (_alt && !_ctrl && !_shift && _key >= 2 && _key <= 10) exitWith {
        [_key - 1] call BA_fnc_announceUnitStatus;
        true
    };

    // Alt+0: Summary
    if (_alt && !_ctrl && !_shift && _key == 11) exitWith {
        [10] call BA_fnc_announceUnitStatus;
        true
    };

    // Tab (key 15) - Not available in focus mode
    if (_key == 15) exitWith {
        ["Unit cycling requires observer mode."] call BA_fnc_speak;
        true
    };

    // Block all other keys by default
    true
}];

// Announce entry
["Focus mode. Cursor at your position."] call BA_fnc_speak;
systemChat "Focus Mode: Cursor/Scanner/Landmarks enabled. WASD or ESC to exit.";

// Announce brief position info
[] call BA_fnc_announceCursorBrief;

true
