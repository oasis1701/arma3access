/*
 * CfgFunctions.hpp - Function definitions for Blind Assist addon
 *
 * Include this in your mission's description.ext like:
 *   class CfgFunctions {
 *       #include "blind_assist\CfgFunctions.hpp"
 *   };
 *
 * Or copy the contents directly into your CfgFunctions class.
 */

class BA {
    class Core {
        file = "blind_assist";
        class autoInit {};
    };

    class NVDA {
        file = "blind_assist";

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
        file = "blind_assist";

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

        // Announce detailed unit status by category
        // Usage: [1] call BA_fnc_announceUnitStatus;
        // Categories: 1=Health, 2=Fatigue, 3=Capability, 4=Suppression,
        //   5=Enemies, 6=Weapon, 7=Morale, 8=Position, 9=Role, 10=Summary
        class announceUnitStatus {};
    };

    class Cursor {
        file = "blind_assist";

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
        file = "blind_assist";

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
        file = "blind_assist";

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
        file = "blind_assist";

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
        file = "blind_assist";

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
        file = "blind_assist";

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
        file = "blind_assist";

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
    };

    class AimAssist {
        file = "blind_assist";

        // Initialize aim assist state variables
        // Usage: [] call BA_fnc_initAimAssist;
        class initAimAssist {};

        // Toggle aim assist audio on/off (End key)
        // Usage: [] call BA_fnc_toggleAimAssist;
        class toggleAimAssist {};

        // Per-frame update for aim assist audio
        // Usage: [] call BA_fnc_updateAimAssist;
        class updateAimAssist {};

        // Find nearest visible enemy for targeting
        // Usage: [_soldier] call BA_fnc_findAimTarget;
        class findAimTarget {};

        // Calculate audio parameters (pan, pitch, locked)
        // Usage: [_soldier, _target] call BA_fnc_calculateAimOffset;
        class calculateAimOffset {};

        // Snap aim to current target (T key - horizontal only)
        // Usage: [] call BA_fnc_snapAimToTarget;
        class snapAimToTarget {};
    };

    class TerrainRadar {
        file = "blind_assist";

        // Initialize terrain radar state variables
        // Usage: [] call BA_fnc_initTerrainRadar;
        class initTerrainRadar {};

        // Toggle terrain radar on/off (Ctrl+W, only when observer mode OFF)
        // Usage: [] call BA_fnc_toggleTerrainRadar;
        class toggleTerrainRadar {};

        // Per-frame update for terrain radar sweep
        // Usage: [] call BA_fnc_updateTerrainRadar;
        class updateTerrainRadar {};
    };

    class FocusMode {
        file = "blind_assist";

        // Toggle focus mode on/off (Backtick ~)
        // Usage: [] call BA_fnc_toggleFocusMode;
        class toggleFocusMode {};

        // Enter focus mode (cursor/scanner without observer mode)
        // Usage: [] call BA_fnc_enterFocusMode;
        class enterFocusMode {};

        // Exit focus mode (return to normal manual control)
        // Usage: [] call BA_fnc_exitFocusMode;
        class exitFocusMode {};
    };

    class BAMenu {
        file = "blind_assist";

        // Initialize BA Menu state variables
        // Usage: [] call BA_fnc_initBAMenu;
        class initBAMenu {};

        // Open the BA Menu (M key) - shows weapon inventory
        // Usage: [] call BA_fnc_openBAMenu;
        class openBAMenu {};

        // Navigate up/down in BA Menu
        // Usage: ["up"] call BA_fnc_navigateBAMenu;
        class navigateBAMenu {};

        // Select current BA Menu item (handles level transitions)
        // Usage: [] call BA_fnc_selectBAMenuItem;
        class selectBAMenuItem {};

        // Close/back in BA Menu (level-aware)
        // Usage: [] call BA_fnc_closeBAMenu;
        class closeBAMenu {};

        // Restock a specific magazine type
        // Usage: ["30Rnd_65x39_caseless_mag", 6] call BA_fnc_restockAmmo;
        class restockAmmo {};

        // Get magazine info for a weapon
        // Usage: [_unit, _weaponClass] call BA_fnc_getWeaponMagazineInfo;
        // Returns: [magazineClass, currentCount]
        class getWeaponMagazineInfo {};
    };

    class DirectionSnap {
        file = "blind_assist";

        // Initialize direction snap state variables
        // Usage: [] call BA_fnc_initDirectionSnap;
        class initDirectionSnap {};

        // Cycle player direction to next cardinal compass point
        // Usage: [true] call BA_fnc_cycleDirection;  // clockwise
        // Usage: [false] call BA_fnc_cycleDirection; // counter-clockwise
        // Hotkeys: Delete = counter-clockwise, PageDown = clockwise (manual mode only)
        class cycleDirection {};

        // Per-frame update for smooth direction interpolation
        // Usage: [] call BA_fnc_updateDirectionSnap;
        class updateDirectionSnap {};
    };

    class PlayerNav {
        file = "blind_assist";

        // Initialize player navigation state variables
        // Usage: [] call BA_fnc_initPlayerNav;
        class initPlayerNav {};

        // Set waypoint at current cursor position
        // Usage: [] call BA_fnc_setPlayerWaypoint;
        // Hotkey: Y (requires cursor active)
        class setPlayerWaypoint {};

        // Clear active navigation waypoint
        // Usage: [] call BA_fnc_clearPlayerWaypoint;
        // Hotkey: Ctrl+Y
        class clearPlayerWaypoint {};

        // Per-frame navigation update (10Hz)
        // Usage: [] call BA_fnc_updatePlayerNav;
        class updatePlayerNav {};

        // Calculate navigation path (async)
        // Usage: [_soldier, _destination] call BA_fnc_calculateNavPath;
        class calculateNavPath {};

        // Announce distance threshold progress
        // Usage: [_distance] call BA_fnc_announceNavProgress;
        class announceNavProgress {};
    };

    class EnemyDetection {
        file = "blind_assist";

        // Initialize enemy detection (auto-starts, always active)
        // Usage: [] call BA_fnc_initEnemyDetection;
        class initEnemyDetection {};

        // Per-frame update for enemy detection
        // Usage: [] call BA_fnc_updateEnemyDetection;
        class updateEnemyDetection {};
    };

    class EnemyNerf {
        file = "blind_assist";

        // Initialize passive enemy skill nerf (auto-starts, always active)
        // Usage: [] call BA_fnc_initEnemyNerf;
        class initEnemyNerf {};

        // Per-frame update for enemy nerf scanning
        // Usage: [] call BA_fnc_updateEnemyNerf;
        class updateEnemyNerf {};
    };

    class StanceMonitor {
        file = "blind_assist";

        // Initialize stance change announcements (always active)
        // Usage: [] call BA_fnc_initStanceMonitor;
        class initStanceMonitor {};

        // Per-frame stance change detection (4Hz)
        // Usage: [] call BA_fnc_updateStanceMonitor;
        class updateStanceMonitor {};
    };

    class ChatReader {
        file = "blind_assist";

        // Initialize chat reader for Side/Command chat announcements
        // Usage: [] call BA_fnc_initChatReader;
        class initChatReader {};
    };

    class TakeCover {
        file = "blind_assist";

        // Smart cover: run to nearest cover relative to threat (C key)
        // Usage: [] call BA_fnc_takeCover;
        class takeCover {};
    };

    class LookoutMenu {
        file = "blind_assist";

        // Initialize lookout menu state variables
        // Usage: [] call BA_fnc_initLookoutMenu;
        class initLookoutMenu {};

        // Open the lookout menu (W key in focus mode)
        // Usage: [] call BA_fnc_openLookoutMenu;
        class openLookoutMenu {};

        // Navigate up/down in lookout menu
        // Usage: ["up"] call BA_fnc_navigateLookoutMenu;
        class navigateLookoutMenu {};

        // Close lookout menu without selection
        // Usage: [] call BA_fnc_closeLookoutMenu;
        class closeLookoutMenu {};

        // Find best lookout position and navigate there
        // Usage: [50] call BA_fnc_findLookout;
        class findLookout {};
    };
};
