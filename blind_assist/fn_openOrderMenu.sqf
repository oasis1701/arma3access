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

// Must be in observer mode or focus mode
if (!BA_observerMode && !BA_focusMode) exitWith {
    ["Observer or focus mode required"] call BA_fnc_speak;
    false
};

// Get the unit for type detection
private _unitForDetection = objNull;
if (!isNil "BA_selectedOrderGroup" && {!isNull BA_selectedOrderGroup}) then {
    _unitForDetection = leader BA_selectedOrderGroup;
} else {
    if (BA_observerMode) then {
        _unitForDetection = BA_observedUnit;
    } else {
        // Focus mode: use stashed squad unit if available
        if (!isNil "BA_pendingSquadUnit" && {!isNull BA_pendingSquadUnit}) then {
            _unitForDetection = BA_pendingSquadUnit;
        } else {
            _unitForDetection = player;
        };
    };
};

// "Order All" in focus mode: BA_pendingSquadUnit is null → show group-wide menu
if (BA_focusMode && (isNil "BA_pendingSquadUnit" || {isNull BA_pendingSquadUnit})) exitWith {
    BA_orderMenuItems = [
        ["Stop", "stop_all"],
        ["Dismount All", "dismount_all"],
        ["Regroup", "regroup"],
        ["Hold Fire", "hold_fire"],
        ["Fire at Will", "fire_at_will"]
    ];
    BA_orderMenuActive = true;
    BA_orderMenuIndex = 0;
    BA_orderMenuUnitType = "squad_all";
    private _firstItem = (BA_orderMenuItems select 0) select 0;
    private _message = format["Squad orders. 1. %1. Arrows to navigate, Enter to select, Escape to cancel.", _firstItem];
    [_message] call BA_fnc_speak;
    true
};

if (isNull _unitForDetection) exitWith {
    ["No unit selected"] call BA_fnc_speak;
    false
};
BA_orderMenuUnitType = [_unitForDetection] call BA_fnc_detectUnitType;

// Populate menu based on unit type
BA_orderMenuItems = switch (BA_orderMenuUnitType) do {
    case "infantry": {
        [
            ["Move", "move"],
            ["Sneak", "sneak"],
            ["Assault", "assault"],
            ["Sweep", "sweep"],
            ["Garrison", "garrison"],
            ["Find Cover", "find_cover"],
            ["Regroup", "regroup"],
            ["Heal Up", "heal"],
            ["Hold Fire", "hold_fire"],
            ["Fire at Will", "fire_at_will"]
        ]
    };
    case "helicopter": {
        [
            ["Move", "heli_move"],
            ["Land", "heli_land"],
            ["Stop", "heli_stop"],
            ["Altitude 50m", "heli_alt_50"],
            ["Altitude 150m", "heli_alt_150"],
            ["Altitude 300m", "heli_alt_300"],
            ["Loiter 300m", "heli_loiter_300"],
            ["Loiter 600m", "heli_loiter_600"],
            ["Loiter 900m", "heli_loiter_900"],
            ["Defend Position", "heli_defend"],
            ["Attack Area", "heli_attack_area"],
            ["Attack and Return", "heli_strafe"]
        ]
    };
    case "jet": {
        [
            ["Move", "jet_move"],
            ["Patrol Small 1km", "jet_patrol_small"],
            ["Patrol Medium 2km", "jet_patrol_med"],
            ["Patrol Large 4km", "jet_patrol_large"],
            ["Strike Target", "jet_strike"],
            ["Loiter", "jet_loiter"],
            ["Altitude Low 200m", "jet_alt_low"],
            ["Altitude Medium 500m", "jet_alt_med"],
            ["Altitude High 1000m", "jet_alt_high"],
            ["Return to Base", "jet_rtb"]
        ]
    };
    case "armed_vehicle": {
        [
            ["Move", "vehicle_move"],
            ["Dismount All", "dismount_all"],
            ["Hold Fire", "hold_fire"],
            ["Fire at Will", "fire_at_will"]
        ]
    };
    case "unarmed_vehicle": {
        [
            ["Move", "vehicle_move"],
            ["Dismount All", "dismount_all"]
        ]
    };
    // Other unit types - temporarily disabled, show basic move only
    case "artillery";
    case "static";
    default {
        [
            ["Move", "vehicle_move"]
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
