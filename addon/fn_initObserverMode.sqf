/*
 * Function: BA_fnc_initObserverMode
 * Initializes the Observer Mode system with hotkeys.
 *
 * Hotkeys:
 *   Ctrl+O       - Toggle observer mode
 *   Tab          - Next unit in current group
 *   Shift+Tab    - Previous unit in current group
 *   Ctrl+Tab     - Next group (switch to leader)
 *   Ctrl+Shift+Tab - Previous group (switch to leader)
 *   G            - Open group selection menu
 *   O            - Open orders menu
 *   L            - Open landmarks menu
 *   R            - Toggle road exploration mode
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
BA_originalUnit = objNull;
BA_ghostUnit = objNull;
BA_observerCamera = objNull;
BA_observedUnit = objNull;      // Currently observed unit (camera attached to)
BA_currentGroup = grpNull;      // Group of the observed unit
BA_currentUnitIndex = 0;        // Index in the group's unit array

// Initialize cursor system
[] call BA_fnc_initCursor;

// Initialize landmarks menu system
[] call BA_fnc_initLandmarksMenu;

// Initialize scanner system
[] call BA_fnc_initScanner;

// Add keyboard event handler
// DIK codes: O = 24, Tab = 15
// Parameters: [displayOrControl, key, shift, ctrl, alt]
findDisplay 46 displayAddEventHandler ["KeyDown", {
    params ["_display", "_key", "_shift", "_ctrl", "_alt"];

    // Ctrl+O (key 24) - Toggle observer mode
    if (_key == 24 && _ctrl && !_shift && !_alt) exitWith {
        [] call BA_fnc_toggleObserverMode;
        true
    };

    // Only process other hotkeys if in observer mode
    if (!BA_observerMode) exitWith { false };

    // G key (34) - Group selection menu (only in observer mode)
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
        // Up arrow (200)
        if (_key == 200) exitWith {
            [-1] call BA_fnc_navigateGroupMenu;
            true
        };
        // Down arrow (208)
        if (_key == 208) exitWith {
            [1] call BA_fnc_navigateGroupMenu;
            true
        };
        // Enter (28)
        if (_key == 28) exitWith {
            [] call BA_fnc_selectGroupMenuItem;
            true
        };
        // Escape (1)
        if (_key == 1) exitWith {
            [] call BA_fnc_closeGroupMenu;
            true
        };
        // Block other keys while menu is open
        true
    };

    // L key (38) - Open/close landmarks menu (only in observer mode)
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
        // Up arrow (200)
        if (_key == 200) exitWith {
            ["up"] call BA_fnc_navigateLandmarksMenu;
            true
        };
        // Down arrow (208)
        if (_key == 208) exitWith {
            ["down"] call BA_fnc_navigateLandmarksMenu;
            true
        };
        // Left arrow (203)
        if (_key == 203) exitWith {
            ["left"] call BA_fnc_navigateLandmarksMenu;
            true
        };
        // Right arrow (205)
        if (_key == 205) exitWith {
            ["right"] call BA_fnc_navigateLandmarksMenu;
            true
        };
        // Enter (28)
        if (_key == 28) exitWith {
            [] call BA_fnc_selectLandmarksMenuItem;
            true
        };
        // Escape (1)
        if (_key == 1) exitWith {
            [] call BA_fnc_closeLandmarksMenu;
            true
        };
        // Block other keys while menu is open
        true
    };

    // O key (24) without Ctrl - Open/close orders menu (only in observer mode)
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
        // Up arrow (200)
        if (_key == 200) exitWith {
            ["up"] call BA_fnc_navigateOrderMenu;
            true
        };
        // Down arrow (208)
        if (_key == 208) exitWith {
            ["down"] call BA_fnc_navigateOrderMenu;
            true
        };
        // Enter (28)
        if (_key == 28) exitWith {
            [] call BA_fnc_selectOrderMenuItem;
            true
        };
        // Escape (1)
        if (_key == 1) exitWith {
            [] call BA_fnc_closeOrderMenu;
            true
        };
        // Block other keys while menu is open
        false
    };

    // R key (19) - Toggle road exploration mode
    if (_key == 19 && !_ctrl && !_shift && !_alt) exitWith {
        [] call BA_fnc_toggleRoadMode;
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
                // All arrow keys now work based on compass direction
                [_direction] call BA_fnc_followRoad;
                true
            } else {
                if (_shift && !_ctrl && !_alt) then {
                    // Shift+Arrow = Turn at intersection
                    [_direction] call BA_fnc_selectRoadAtIntersection;
                    true
                } else {
                    // No modifier or Ctrl = do nothing in road mode (reserve for future)
                    false
                };
            };
        };

        // Normal cursor movement (road mode disabled)
        // Alt+Arrow = 10m, Shift+Arrow = 100m, Ctrl+Arrow = 1000m
        private _distance = if (_alt && !_ctrl && !_shift) then { 10 }
            else { if (_shift && !_ctrl && !_alt) then { 100 }
            else { if (_ctrl && !_shift && !_alt) then { 1000 } else { 0 } } };
        if (_distance > 0) then {
            [_direction, _distance] call BA_fnc_moveCursor;
        };
        _distance > 0
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
systemChat "Blind Assist: Observer Mode initialized. Press Ctrl+O to toggle.";
