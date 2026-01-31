/*
 * CfgFunctions.hpp - Function definitions for Blind Assist addon
 *
 * Include this in your mission's description.ext like:
 *   class CfgFunctions {
 *       #include "addon\CfgFunctions.hpp"
 *   };
 *
 * Or copy the contents directly into your CfgFunctions class.
 */

class BA {
    class NVDA {
        file = "addon";

        // Make NVDA speak text
        // Usage: ["Hello world"] call BA_fnc_speak;
        class speak {};

        // Cancel current speech
        // Usage: [] call BA_fnc_cancel;
        class cancel {};

        // Test if NVDA is running
        // Usage: if ([] call BA_fnc_test) then { ... };
        class test {};

        // Send to braille display
        // Usage: ["Message"] call BA_fnc_braille;
        class braille {};
    };

    class ObserverMode {
        file = "addon";

        // Initialize observer mode system (call once at mission start)
        // Usage: [] call BA_fnc_initObserverMode;
        class initObserverMode {};

        // Toggle between manual and observer mode
        // Usage: [] call BA_fnc_toggleObserverMode;
        class toggleObserverMode {};

        // Enter observer mode (AI takes control)
        // Usage: [] call BA_fnc_enterObserverMode;
        class enterObserverMode {};

        // Exit observer mode (return to manual control)
        // Usage: [] call BA_fnc_exitObserverMode;
        class exitObserverMode {};

        // Switch camera to a specific unit
        // Usage: [_unit] call BA_fnc_switchObserverTarget;
        class switchObserverTarget {};

        // Next unit in current group (Tab)
        // Usage: [] call BA_fnc_nextUnit;
        class nextUnit {};

        // Previous unit in current group (Shift+Tab)
        // Usage: [] call BA_fnc_prevUnit;
        class prevUnit {};

        // Next group leader (Ctrl+Tab)
        // Usage: [] call BA_fnc_nextGroup;
        class nextGroup {};

        // Previous group leader (Ctrl+Shift+Tab)
        // Usage: [] call BA_fnc_prevGroup;
        class prevGroup {};
    };

    class Cursor {
        file = "addon";

        // Initialize cursor system (called from initObserverMode)
        // Usage: [] call BA_fnc_initCursor;
        class initCursor {};

        // Set cursor to absolute position
        // Usage: [position, announce] call BA_fnc_setCursorPos;
        class setCursorPos {};

        // Move cursor by direction and distance
        // Usage: ["North", 100] call BA_fnc_moveCursor;
        class moveCursor {};

        // Snap cursor back to observed unit
        // Usage: [] call BA_fnc_snapCursorToUnit;
        class snapCursorToUnit {};

        // Get 6-digit grid reference formatted for speech
        // Usage: [position] call BA_fnc_getGridInfo;
        class getGridInfo {};

        // Get terrain type at position
        // Usage: [position] call BA_fnc_getTerrainInfo;
        class getTerrainInfo {};

        // Get altitude above sea level
        // Usage: [position] call BA_fnc_getAltitudeInfo;
        class getAltitudeInfo {};

        // Get slope description
        // Usage: [position] call BA_fnc_getSlopeInfo;
        class getSlopeInfo {};

        // Get nearby objects (buildings, vehicles, trees)
        // Usage: [position, radius] call BA_fnc_getNearbyObjects;
        class getNearbyObjects {};

        // Get nearby units (friendlies and known enemies)
        // Usage: [position, friendlyRadius, enemyRadius] call BA_fnc_getNearbyUnits;
        class getNearbyUnits {};

        // Get bearing and distance from observed unit to cursor
        // Usage: [position] call BA_fnc_getBearingDistance;
        class getBearingDistance {};

        // Announce cursor movement
        // Usage: ["North", 100] call BA_fnc_announceMovement;
        class announceMovement {};

        // Announce brief cursor info (grid, terrain, altitude)
        // Usage: [] call BA_fnc_announceCursorBrief;
        class announceCursorBrief {};

        // Announce detailed cursor info (all + objects + units + bearing)
        // Usage: [] call BA_fnc_announceCursorDetailed;
        class announceCursorDetailed {};
    };

    class Orders {
        file = "addon";

        // Initialize order menu state variables
        // Usage: [] call BA_fnc_initOrderMenu;
        class initOrderMenu {};

        // Detect unit type for menu selection
        // Usage: [_unit] call BA_fnc_detectUnitType;
        class detectUnitType {};

        // Open the order menu for current unit
        // Usage: [] call BA_fnc_openOrderMenu;
        class openOrderMenu {};

        // Navigate up/down in order menu
        // Usage: ["up"] call BA_fnc_navigateOrderMenu;
        class navigateOrderMenu {};

        // Select current menu item
        // Usage: [] call BA_fnc_selectOrderMenuItem;
        class selectOrderMenuItem {};

        // Close order menu without action
        // Usage: [] call BA_fnc_closeOrderMenu;
        class closeOrderMenu {};

        // Issue order to unit
        // Usage: ["move", "Move"] call BA_fnc_issueOrder;
        class issueOrder {};
    };

    class GroupMenu {
        file = "addon";

        // Initialize group menu state variables
        // Usage: [] call BA_fnc_initGroupMenu;
        class initGroupMenu {};

        // Open the group selection menu
        // Usage: [] call BA_fnc_openGroupMenu;
        class openGroupMenu {};

        // Navigate up/down in group menu
        // Usage: [1] call BA_fnc_navigateGroupMenu; (1=down, -1=up)
        class navigateGroupMenu {};

        // Select current group for orders
        // Usage: [] call BA_fnc_selectGroupMenuItem;
        class selectGroupMenuItem {};

        // Close group menu without selection
        // Usage: [] call BA_fnc_closeGroupMenu;
        class closeGroupMenu {};

        // Get group description (callsign, leader, count)
        // Usage: [_group] call BA_fnc_getGroupDescription;
        class getGroupDescription {};
    };

    class LandmarksMenu {
        file = "addon";

        // Initialize landmarks menu state variables
        // Usage: [] call BA_fnc_initLandmarksMenu;
        class initLandmarksMenu {};

        // Open the landmarks menu
        // Usage: [] call BA_fnc_openLandmarksMenu;
        class openLandmarksMenu {};

        // Navigate the landmarks menu
        // Usage: ["up"] call BA_fnc_navigateLandmarksMenu;
        class navigateLandmarksMenu {};

        // Select current landmark and move cursor
        // Usage: [] call BA_fnc_selectLandmarksMenuItem;
        class selectLandmarksMenuItem {};

        // Close landmarks menu without selection
        // Usage: [] call BA_fnc_closeLandmarksMenu;
        class closeLandmarksMenu {};

        // Get formatted landmark description
        // Usage: [_location] call BA_fnc_getLandmarkDescription;
        class getLandmarkDescription {};

        // Get formatted marker description
        // Usage: ["marker_name"] call BA_fnc_getMarkerDescription;
        class getMarkerDescription {};

        // Get formatted task description
        // Usage: ["task_id"] call BA_fnc_getTaskDescription;
        class getTaskDescription {};

        // Convert location type to readable name
        // Usage: ["NameCity"] call BA_fnc_getLocationTypeName;
        class getLocationTypeName {};

        // Convert bearing to compass direction
        // Usage: [45] call BA_fnc_bearingToCompass;
        class bearingToCompass {};
    };

    class Scanner {
        file = "addon";

        // Initialize scanner state variables and categories
        // Usage: [] call BA_fnc_initScanner;
        class initScanner {};

        // Cycle scanner range (10/50/100/500/1000m)
        // Usage: [] call BA_fnc_cycleScannerRange;
        class cycleScannerRange {};

        // Scan for objects near cursor position
        // Usage: [] call BA_fnc_scanObjects;
        class scanObjects {};

        // Navigate scanner categories and objects
        // Usage: ["category_next"] call BA_fnc_navigateScanner;
        class navigateScanner {};

        // Jump cursor to selected scanner object
        // Usage: [] call BA_fnc_jumpToScannerObject;
        class jumpToScannerObject {};

        // Announce details of current scanner object
        // Usage: [] call BA_fnc_announceScannedObject;
        class announceScannedObject {};

        // Get side relationship for object (friendly/enemy/etc)
        // Usage: [_object] call BA_fnc_getObjectSide;
        class getObjectSide {};
    };

    class RoadMode {
        file = "addon";

        // Toggle road exploration mode on/off
        // Usage: [] call BA_fnc_toggleRoadMode;
        class toggleRoadMode {};

        // Get human-readable road type description
        // Usage: [getRoadInfo _road] call BA_fnc_getRoadTypeDescription;
        class getRoadTypeDescription {};

        // Snap cursor to nearest road in direction
        // Usage: ["North"] call BA_fnc_snapToRoad;
        class snapToRoad {};

        // Follow road in current direction
        // Usage: [true] call BA_fnc_followRoad;
        class followRoad {};

        // Detect if position is at an intersection
        // Usage: [_road, _position] call BA_fnc_detectIntersection;
        class detectIntersection {};

        // Announce intersection options
        // Usage: [_road, _position, _direction] call BA_fnc_announceIntersection;
        class announceIntersection {};

        // Select road at intersection by compass direction
        // Usage: ["East"] call BA_fnc_selectRoadAtIntersection;
        class selectRoadAtIntersection {};

        // Open intersection menu showing all roads at position
        // Usage: [] call BA_fnc_openIntersectionMenu;
        class openIntersectionMenu {};

        // Navigate intersection menu up/down
        // Usage: [1] call BA_fnc_navigateIntersectionMenu;
        class navigateIntersectionMenu {};

        // Select current road in intersection menu
        // Usage: [] call BA_fnc_selectIntersectionMenuItem;
        class selectIntersectionMenuItem {};

        // Close intersection menu
        // Usage: [] call BA_fnc_closeIntersectionMenu;
        class closeIntersectionMenu {};
    };

    class DevSandbox {
        file = "addon";

        // Initialize dev sandbox with pre-placed assets
        // Usage: [] call BA_fnc_initDevSandbox;
        class initDevSandbox {};

        // Spawn enemy units at designated zone
        // Usage: ["infantry", 6] call BA_fnc_spawnEnemies;
        // Types: "infantry", "armor", "mixed"
        class spawnEnemies {};

        // Clear all spawned enemies
        // Usage: [] call BA_fnc_clearEnemies;
        class clearEnemies {};

        // Reset dead friendly assets to original positions
        // Usage: [] call BA_fnc_resetAssets;
        class resetAssets {};

        // Announce nearby asset when player approaches
        // Usage: [_asset] call BA_fnc_announceNearbyAsset;
        class announceNearbyAsset {};
    };
};
