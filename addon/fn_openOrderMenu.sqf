/*
 * Function: BA_fnc_openOrderMenu
 * Opens the order menu for the currently observed unit.
 *
 * Detects unit type and populates appropriate menu items.
 * Announces the menu opening via NVDA.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Boolean - true if menu opened successfully, false otherwise
 *
 * Example:
 *   [] call BA_fnc_openOrderMenu;
 */

// Must be in observer mode
if (!BA_observerMode) exitWith {
    ["Not in observer mode"] call BA_fnc_speak;
    false
};

// Must have an observed unit
if (isNull BA_observedUnit) exitWith {
    ["No unit selected"] call BA_fnc_speak;
    false
};

// Detect unit type
BA_orderMenuUnitType = [BA_observedUnit] call BA_fnc_detectUnitType;

// Populate menu based on unit type
BA_orderMenuItems = switch (BA_orderMenuUnitType) do {
    case "infantry": {
        [
            ["Move", "move"],
            ["Sneak", "sneak"],
            ["Assault", "assault"],
            ["Garrison", "garrison"],
            ["Hold Fire", "hold_fire"],
            ["Fire at Will", "fire_at_will"]
        ]
    };
    // Other unit types - temporarily disabled, show basic move only
    case "helicopter";
    case "jet";
    case "armed_vehicle";
    case "unarmed_vehicle";
    case "artillery";
    case "static";
    default {
        [
            ["Move", "move"]
        ]
    };
};

// Set menu state
BA_orderMenuActive = true;
BA_orderMenuIndex = 0;

// Build announcement
private _unitTypeName = switch (BA_orderMenuUnitType) do {
    case "infantry": { "Infantry" };
    case "helicopter": { "Helicopter" };
    case "jet": { "Jet" };
    case "armed_vehicle": { "Armed Vehicle" };
    case "unarmed_vehicle": { "Transport" };
    case "artillery": { "Artillery" };
    case "static": { "Static Gun" };
    default { "Unit" };
};

private _firstItem = (BA_orderMenuItems select 0) select 0;
private _message = format["%1 orders. 1. %2. Arrows to navigate, Enter to select, Escape to cancel.", _unitTypeName, _firstItem];

[_message] call BA_fnc_speak;

true
