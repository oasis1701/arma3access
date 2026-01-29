/*
 * Function: BA_fnc_enterObserverMode
 * Enters observer mode - AI takes control of the player's soldier.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Boolean - true if successfully entered observer mode
 *
 * Example:
 *   [] call BA_fnc_enterObserverMode;
 */

// Don't enter if already in observer mode
if (BA_observerMode) exitWith {
    ["Already in observer mode."] call BA_fnc_speak;
    false
};

// Store reference to original player unit
BA_originalUnit = player;
BA_observedUnit = player;
BA_currentGroup = group player;
BA_currentUnitIndex = (units BA_currentGroup) find player;

// Get side name
private _side = side BA_originalUnit;
private _sideName = switch (_side) do {
    case west: { "Blufor" };
    case east: { "Opfor" };
    case independent: { "Independent" };
    case civilian: { "Civilian" };
    default { "Unknown" };
};

// Get group name
private _groupName = groupId BA_currentGroup;

// Get unit type for announcement
private _unitType = getText (configFile >> "CfgVehicles" >> typeOf BA_originalUnit >> "displayName");
if (_unitType == "") then { _unitType = "Soldier"; };

// Create invisible ghost unit at a safe location far away
// Using a Logic entity which is invisible and has no physical presence
private _safePos = [0, 0, 0];
BA_ghostUnit = createAgent ["Logic", _safePos, [], 0, "NONE"];
BA_ghostUnit hideObjectGlobal true;
BA_ghostUnit allowDamage false;

// Switch player control to ghost - original unit becomes AI-controlled
selectPlayer BA_ghostUnit;

// Create camera attached to original unit's head
BA_observerCamera = "camera" camCreate (getPos BA_originalUnit);
BA_observerCamera attachTo [BA_originalUnit, [0, 0.1, 0.1], "head"];
BA_observerCamera cameraEffect ["Internal", "Back"];

// Add killed event handler to detect if soldier dies while observing
BA_observerKilledEH = BA_originalUnit addEventHandler ["Killed", {
    params ["_unit", "_killer"];

    if (BA_observerMode) then {
        // Detach camera so it stays at current position
        detach BA_observerCamera;
        ["Your soldier has been killed."] call BA_fnc_speak;

        // Check if there are other playable units in the group
        private _group = group _unit;
        private _aliveUnits = {alive _x} count units _group;

        if (_aliveUnits == 0) then {
            // No units left - mission failed
            sleep 2;
            ["All units lost. Mission failed."] call BA_fnc_speak;

            // Exit observer mode to let game handle mission end
            [] spawn {
                sleep 3;
                [] call BA_fnc_exitObserverMode;
            };
        };
    };
}];

// Set state
BA_observerMode = true;

// Initialize cursor at player's position
BA_cursorPos = getPos BA_observedUnit;
BA_cursorActive = true;

// Announce to player: Side. Group. Unit type. AI has control.
[format["%1. %2. %3. AI has control.", _sideName, _groupName, _unitType]] call BA_fnc_speak;
systemChat format["Observer Mode: %1 - %2 - %3 - AI has control", _sideName, _groupName, _unitType];

true
