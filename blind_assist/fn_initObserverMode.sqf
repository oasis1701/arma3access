/*
 * Function: BA_fnc_initObserverMode
 * Initializes the Observer Mode and Focus Mode systems with hotkeys.
 *
 * Hotkeys (Observer Mode):
 *   Ctrl+O       - Toggle observer mode
 *   Tab          - Next unit in current group
 *   Shift+Tab    - Previous unit in current group
 *   Ctrl+Tab     - Next group (switch to leader)
 *   Ctrl+Shift+Tab - Previous group (switch to leader)
 *   G            - Open group selection menu
 *   O            - Open orders menu
 *   L            - Open landmarks menu
 *   R            - Toggle road exploration mode
 *   Ctrl+R       - Open intersection menu (in road mode)
 *   Arrow keys   - Cursor movement (with Alt/Shift/Ctrl modifiers)
 *                  In road mode: Alt+Arrow follows road in compass direction, Shift+Arrow turns at intersection
 *   I            - Detailed scan at cursor
 *   Home/Backspace - Snap cursor to observed unit
 *   U            - Cycle scanner range (10/50/100/500/1000m)
 *   Ctrl+PageUp  - Previous scanner category
 *   Ctrl+PageDown - Next scanner category
 *   PageUp       - Previous object in scanner
 *   PageDown     - Next object in scanner
 *   J            - Jump cursor to selected scanner object
 *   Alt+1        - Announce health status
 *   Alt+2        - Announce fatigue level
 *   Alt+3        - Announce capability (can move/fire)
 *   Alt+4        - Announce suppression (under fire)
 *   Alt+5        - Announce enemy contact
 *   Alt+6        - Announce weapon and ammo
 *   Alt+7        - Announce morale
 *   Alt+8        - Announce position context
 *   Alt+9        - Announce role
 *   Alt+0        - Announce full status summary
 *
 * Hotkeys (Focus Mode - handled by dialog):
 *   ~ (Backtick) - Toggle focus mode (cursor/scanner without observer)
 *   All cursor/scanner keys work in focus mode via dialog overlay
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_initObserverMode;
 */

// Initialize state variables
BA_observerMode = false;
BA_focusMode = false;          // Focus mode: cursor/scanner without observer mode
BA_originalUnit = objNull;
BA_ghostUnit = objNull;
BA_observerCamera = objNull;
BA_observedUnit = objNull;      // Currently observed unit (camera attached to)
BA_currentGroup = grpNull;      // Group of the observed unit
BA_currentUnitIndex = 0;        // Index in the group's unit array

// Edge case monitoring variables
BA_warnedIncapacitated = false; // Prevents unconscious warning spam
BA_warnedCaptive = false;       // Prevents captive warning spam
BA_lastObservedVehicle = objNull; // Tracks vehicle for ejection detection

// Initialize cursor system
[] call BA_fnc_initCursor;

// Initialize landmarks menu system
[] call BA_fnc_initLandmarksMenu;

// Initialize scanner system
[] call BA_fnc_initScanner;

// Initialize aim assist system
[] call BA_fnc_initAimAssist;

// Initialize terrain radar system
[] call BA_fnc_initTerrainRadar;

// Initialize direction snap system
[] call BA_fnc_initDirectionSnap;

// Initialize player navigation system
[] call BA_fnc_initPlayerNav;

// Add keyboard event handler
// DIK codes: O = 24, Tab = 15
// Parameters: [displayOrControl, key, shift, ctrl, alt]
// Wait for display 46 to be available (may not exist during early init)
waitUntil {!isNull findDisplay 46};

findDisplay 46 displayAddEventHandler ["KeyDown", {
    params ["_display", "_key", "_shift", "_ctrl", "_alt"];

    // Ctrl+O (key 24) - Toggle observer mode
    if (_key == 24 && _ctrl && !_shift && !_alt) exitWith {
        [] call BA_fnc_toggleObserverMode;
        true
    };

    // End key (207) - Toggle aiming assistance (works both in and out of observer mode)
    if (_key == 207 && !_ctrl && !_shift && !_alt) exitWith {
        [] call BA_fnc_toggleAimAssist;
        true
    };

    // Ctrl+W (key 17) - Toggle terrain radar (only when observer mode OFF)
    if (_key == 17 && _ctrl && !_shift && !_alt) exitWith {
        if (!BA_observerMode) then {
            [] call BA_fnc_toggleTerrainRadar;
        } else {
            ["Terrain radar only available in manual mode."] call BA_fnc_speak;
        };
        true
    };

    // Ctrl+Shift+W (key 17) - Toggle terrain radar debug output
    if (_key == 17 && _ctrl && _shift && !_alt) exitWith {
        BA_terrainRadarDebug = !BA_terrainRadarDebug;
        [format ["Radar debug %1", if (BA_terrainRadarDebug) then {"on"} else {"off"}]] call BA_fnc_speak;
        true
    };

    // Backtick/Tilde (key 41) - Toggle focus mode (only when NOT in observer mode)
    // Note: Focus mode has its own key handler via dialog, but we need this to enter focus mode
    if (_key == 41 && !_ctrl && !_shift && !_alt) exitWith {
        if (!BA_observerMode) then {
            [] call BA_fnc_toggleFocusMode;
        };
        true
    };

    // Y key (21) - Set player waypoint (requires cursor active)
    if (_key == 21 && !_ctrl && !_shift && !_alt) exitWith {
        if (BA_cursorActive) then {
            [] call BA_fnc_setPlayerWaypoint;
        } else {
            ["Enter focus mode or observer mode first."] call BA_fnc_speak;
        };
        true
    };

    // Ctrl+Y (key 21) - Clear player waypoint
    if (_key == 21 && _ctrl && !_shift && !_alt) exitWith {
        if (BA_playerNavEnabled) then {
            [] call BA_fnc_clearPlayerWaypoint;
            ["Waypoint cleared."] call BA_fnc_speak;
        } else {
            ["No active waypoint."] call BA_fnc_speak;
        };
        true
    };

    // Delete key (211) - Cycle direction counter-clockwise (only in manual mode)
    if (_key == 211 && !_ctrl && !_shift && !_alt) exitWith {
        if (!BA_observerMode && !BA_focusMode) then {
            [false] call BA_fnc_cycleDirection;  // false = counter-clockwise
        };
        true
    };

    // Page Down (209) without modifiers - Cycle direction clockwise (only in manual mode)
    // Note: In observer/focus mode, PageDown is used for scanner navigation
    if (_key == 209 && !_ctrl && !_shift && !_alt && !BA_observerMode && !BA_focusMode) exitWith {
        [true] call BA_fnc_cycleDirection;  // true = clockwise
        true
    };

    // Only process other hotkeys if in observer mode
    // Focus mode keys are handled by the dialog overlay (fn_enterFocusMode.sqf)
    if (!BA_observerMode) exitWith { false };

    // G key (34) - Group selection menu
    if (_key == 34 && !_ctrl && !_shift && !_alt) exitWith {
        if (BA_groupMenuActive) then {
            [] call BA_fnc_closeGroupMenu;
        } else {
            [] call BA_fnc_openGroupMenu;
        };
        true
    };

    // Group menu navigation (when active) - takes priority over order menu
    if (BA_groupMenuActive) exitWith {
        switch (_key) do {
            case 200: { [-1] call BA_fnc_navigateGroupMenu; true };
            case 208: { [1] call BA_fnc_navigateGroupMenu; true };
            case 28: { [] call BA_fnc_selectGroupMenuItem; true };
            case 1: { [] call BA_fnc_closeGroupMenu; true };
            default { true };  // Block all other keys while menu open
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

    // Landmarks menu navigation (when active) - takes priority over cursor movement
    if (BA_landmarksMenuActive) exitWith {
        switch (_key) do {
            case 200: { ["up"] call BA_fnc_navigateLandmarksMenu; true };
            case 208: { ["down"] call BA_fnc_navigateLandmarksMenu; true };
            case 203: { ["left"] call BA_fnc_navigateLandmarksMenu; true };
            case 205: { ["right"] call BA_fnc_navigateLandmarksMenu; true };
            case 28: { [] call BA_fnc_selectLandmarksMenuItem; true };
            case 1: { [] call BA_fnc_closeLandmarksMenu; true };
            default { true };  // Block all other keys while menu open
        }
    };

    // Intersection menu navigation (when active) - takes priority
    if (BA_intersectionMenuActive) exitWith {
        switch (_key) do {
            case 200: { [-1] call BA_fnc_navigateIntersectionMenu; true };
            case 208: { [1] call BA_fnc_navigateIntersectionMenu; true };
            case 28: { [] call BA_fnc_selectIntersectionMenuItem; true };
            case 1: { [] call BA_fnc_closeIntersectionMenu; true };
            default { true };  // Block all other keys while menu open
        }
    };

    // O key (24) without Ctrl - Open/close orders menu
    if (_key == 24 && !_ctrl && !_shift && !_alt) exitWith {
        if (BA_orderMenuActive) then {
            [] call BA_fnc_closeOrderMenu;
        } else {
            [] call BA_fnc_openOrderMenu;
        };
        true
    };

    // When order menu is active, intercept navigation keys
    if (BA_orderMenuActive) exitWith {
        switch (_key) do {
            case 200: { ["up"] call BA_fnc_navigateOrderMenu; true };
            case 208: { ["down"] call BA_fnc_navigateOrderMenu; true };
            case 28: { [] call BA_fnc_selectOrderMenuItem; true };
            case 1: { [] call BA_fnc_closeOrderMenu; true };
            default { true };  // Block all other keys while menu open
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

    // Arrow keys (200=Up, 208=Down, 203=Left, 205=Right) - Cursor movement
    if (_key in [200, 208, 203, 205]) exitWith {
        private _direction = switch (_key) do {
            case 200: { "North" };  // Up arrow
            case 208: { "South" };  // Down arrow
            case 205: { "East" };   // Right arrow
            case 203: { "West" };   // Left arrow
        };

        // Check if road mode is enabled
        if (BA_roadModeEnabled) exitWith {
            // Road mode arrow key handling
            if (_alt && !_ctrl && !_shift) then {
                // Alt+Arrow = Follow road in compass direction
                [_direction] call BA_fnc_followRoad;
            } else {
                if (_shift && !_ctrl && !_alt) then {
                    // Shift+Arrow = Turn at intersection
                    [_direction] call BA_fnc_selectRoadAtIntersection;
                } else {
                    // No valid modifier in road mode
                    if (_alt || _shift || _ctrl) then {
                        ["Road mode: Alt to follow, Shift to turn."] call BA_fnc_speak;
                    };
                };
            };
            // Always return true to block arrow keys
            true
        };

        // Normal cursor movement (road mode disabled)
        // Alt+Arrow = 10m, Shift+Arrow = 100m, Ctrl+Arrow = 1000m
        private _distance = if (_alt && !_ctrl && !_shift) then { 10 }
            else { if (_shift && !_ctrl && !_alt) then { 100 }
            else { if (_ctrl && !_shift && !_alt) then { 1000 } else { 0 } } };
        if (_distance > 0) then {
            [_direction, _distance] call BA_fnc_moveCursor;
        } else {
            // No valid modifier combination
            if (_alt || _shift || _ctrl) then {
                ["Use Alt for 10m, Shift for 100m, Ctrl for 1000m."] call BA_fnc_speak;
            };
        };
        // Always return true to block arrow keys in observer mode
        true
    };

    // I key (23) - Detailed scan at cursor
    if (_key == 23 && !_ctrl && !_shift && !_alt) exitWith {
        [] call BA_fnc_announceCursorDetailed;
        true
    };

    // Home (199) or Backspace (14) - Snap cursor to observed unit
    if (_key in [199, 14] && !_ctrl && !_shift && !_alt) exitWith {
        [] call BA_fnc_snapCursorToUnit;
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
            // Ctrl+PageUp - Previous category
            ["category_prev"] call BA_fnc_navigateScanner;
        } else {
            if (!_ctrl && !_shift && !_alt) then {
                // PageUp - Previous object
                ["object_prev"] call BA_fnc_navigateScanner;
            };
        };
        true
    };

    // PageDown (209) - Scanner navigation
    if (_key == 209) exitWith {
        if (_ctrl && !_shift && !_alt) then {
            // Ctrl+PageDown - Next category
            ["category_next"] call BA_fnc_navigateScanner;
        } else {
            if (!_ctrl && !_shift && !_alt) then {
                // PageDown - Next object
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

    // Alt+1 through Alt+9: Unit status categories (DIK codes 2-10)
    // 1=2, 2=3, 3=4, 4=5, 5=6, 6=7, 7=8, 8=9, 9=10
    if (_alt && !_ctrl && !_shift && _key >= 2 && _key <= 10) exitWith {
        [_key - 1] call BA_fnc_announceUnitStatus;
        true
    };

    // Alt+0: Summary (DIK code 11)
    if (_alt && !_ctrl && !_shift && _key == 11) exitWith {
        [10] call BA_fnc_announceUnitStatus;
        true
    };

    // Tab (key 15) - Unit/group cycling
    if (_key == 15) exitWith {
        if (_ctrl && _shift) then {
            // Ctrl+Shift+Tab - Previous group
            [] call BA_fnc_prevGroup;
        } else {
            if (_ctrl) then {
                // Ctrl+Tab - Next group
                [] call BA_fnc_nextGroup;
            } else {
                if (_shift) then {
                    // Shift+Tab - Previous unit in group
                    [] call BA_fnc_prevUnit;
                } else {
                    // Tab - Next unit in group
                    [] call BA_fnc_nextUnit;
                };
            };
        };
        true
    };

    false
}];

// Log initialization
systemChat "Blind Assist: Initialized. Ctrl+O for observer mode, ~ for focus mode.";
