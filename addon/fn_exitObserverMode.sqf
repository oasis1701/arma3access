/*
 * Function: BA_fnc_exitObserverMode
 * Exits observer mode - returns manual control to the player.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Boolean - true if successfully exited observer mode
 *
 * Example:
 *   [] call BA_fnc_exitObserverMode;
 */

// Don't exit if not in observer mode
if (!BA_observerMode) exitWith {
    ["Already in manual control."] call BA_fnc_speak;
    false
};

// Check if original unit is still alive
private _unitAlive = alive BA_originalUnit;

// Remove camera effect first
BA_observerCamera cameraEffect ["Terminate", "Back"];

// Destroy camera
camDestroy BA_observerCamera;
BA_observerCamera = objNull;

// Remove killed event handler if unit is still alive
if (_unitAlive && !isNull BA_originalUnit) then {
    BA_originalUnit removeEventHandler ["Killed", BA_observerKilledEH];
};

// Switch player back to original unit (if alive) or handle death
if (_unitAlive && !isNull BA_originalUnit) then {
    // Return control to original soldier
    selectPlayer BA_originalUnit;
    ["Manual control restored."] call BA_fnc_speak;
    systemChat "Observer Mode: Manual control restored";
} else {
    // Soldier is dead - let normal respawn/death handling occur
    // Player stays as ghost temporarily until respawn system takes over
    ["Soldier is dead. Exiting observer mode."] call BA_fnc_speak;
    systemChat "Observer Mode: Soldier dead - exiting";
};

// Delete ghost unit
if (!isNull BA_ghostUnit) then {
    deleteVehicle BA_ghostUnit;
    BA_ghostUnit = objNull;
};

// Deactivate cursor
BA_cursorActive = false;
BA_cursorPos = [0, 0, 0];

// Clear state
BA_observerMode = false;
BA_originalUnit = objNull;
BA_observedUnit = objNull;
BA_currentGroup = grpNull;
BA_currentUnitIndex = 0;

true
