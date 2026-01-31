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

// Terminate the ghost sync loop
if (!isNil "BA_ghostSyncHandle") then {
    terminate BA_ghostSyncHandle;
    BA_ghostSyncHandle = nil;
};

// Check if original unit is still alive
private _unitAlive = alive BA_originalUnit;

// Final sync: ghost variables -> original unit (capture any changes made during observer mode)
if (_unitAlive && !isNull BA_originalUnit && !isNull BA_ghostUnit) then {
    private _ghostVars = allVariables BA_ghostUnit;
    {
        private _value = BA_ghostUnit getVariable _x;
        BA_originalUnit setVariable [_x, _value];
    } forEach _ghostVars;
};

// Rescue inventory from ghost to soldier (missions may give items to player)
if (!isNull BA_ghostUnit && !isNull BA_originalUnit && alive BA_originalUnit) then {
    // Transfer items (maps, GPS, quest items, etc.)
    {
        if !(_x in items BA_originalUnit) then {
            BA_originalUnit addItem _x;
        };
    } forEach (items BA_ghostUnit);

    // Transfer assigned items (NVGs, binoculars, etc.)
    {
        if !(_x in assignedItems BA_originalUnit) then {
            BA_originalUnit linkItem _x;
        };
    } forEach (assignedItems BA_ghostUnit);

    // Transfer magazines
    {
        BA_originalUnit addMagazine _x;
    } forEach (magazines BA_ghostUnit);
};

// Clean up camera if it exists (legacy, now using switchCamera instead)
if (!isNull BA_observerCamera) then {
    BA_observerCamera cameraEffect ["Terminate", "Back"];
    camDestroy BA_observerCamera;
};
BA_observerCamera = objNull;

// Remove killed event handler if unit is still alive
if (_unitAlive && !isNull BA_originalUnit) then {
    BA_originalUnit removeEventHandler ["Killed", BA_observerKilledEH];
};

// Switch player back to original unit (alive or dead)
if (!isNull BA_originalUnit) then {
    // Return control to original soldier - even if dead
    // This makes Arma's native respawn/death systems trigger
    selectPlayer BA_originalUnit;

    if (_unitAlive) then {
        ["Manual control restored."] call BA_fnc_speak;
        systemChat "Observer Mode: Manual control restored";
    } else {
        // Soldier is dead - Arma's respawn system will now see player as dead
        systemChat "Observer Mode: Soldier dead - respawn system active";
    };
} else {
    // Original unit no longer exists (deleted, etc.)
    ["Original soldier no longer exists."] call BA_fnc_speak;
    systemChat "Observer Mode: Original unit gone";
};

// Delete ghost unit
if (!isNull BA_ghostUnit) then {
    deleteVehicle BA_ghostUnit;
    BA_ghostUnit = objNull;
};

// Delete ghost group
if (!isNil "BA_ghostGroup" && {!isNull BA_ghostGroup}) then {
    deleteGroup BA_ghostGroup;
    BA_ghostGroup = grpNull;
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

// Reset edge case monitoring variables
BA_warnedIncapacitated = false;
BA_warnedCaptive = false;
BA_lastObservedVehicle = objNull;

true
