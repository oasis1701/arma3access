/*
 * Function: BA_fnc_navigateBAMenu
 * Navigates up or down in the BA Menu.
 *
 * Works across all menu levels with appropriate announcements.
 *
 * Arguments:
 *   0: STRING - Direction ("up" or "down")
 *
 * Return Value:
 *   None
 *
 * Example:
 *   ["up"] call BA_fnc_navigateBAMenu;
 *   ["down"] call BA_fnc_navigateBAMenu;
 */

params [["_direction", "down", [""]]];

// Don't navigate if menu not active
if (!BA_menuActive) exitWith {};

private _count = count BA_menuItems;
if (_count == 0) exitWith {};

// Update index with wrap-around
if (_direction == "up") then {
    BA_menuIndex = BA_menuIndex - 1;
    if (BA_menuIndex < 0) then { BA_menuIndex = _count - 1; };
} else {
    BA_menuIndex = BA_menuIndex + 1;
    if (BA_menuIndex >= _count) then { BA_menuIndex = 0; };
};

// Handle left/right tab switching (Level 1 only)
if (_direction == "left" || _direction == "right") exitWith {
    if (BA_menuLevel != 1) exitWith {};

    // Save current tab's index
    BA_menuTabIndex set [BA_menuTab, BA_menuIndex];

    // Switch tab with wraparound
    if (_direction == "left") then {
        BA_menuTab = BA_menuTab - 1;
        if (BA_menuTab < 0) then { BA_menuTab = (count BA_menuTabNames) - 1; };
    } else {
        BA_menuTab = BA_menuTab + 1;
        if (BA_menuTab >= count BA_menuTabNames) then { BA_menuTab = 0; };
    };

    // Rebuild items for new tab
    [true] call BA_fnc_openBAMenu;
};

// Announce based on current level
private _item = BA_menuItems select BA_menuIndex;

switch (BA_menuLevel) do {
    case 1: {
        private _name = _item select 0;

        // Settings tab items are [label, "toggle", action] — only 3 elements
        if (BA_menuTab == 1) exitWith {
            [format ["%1.", _name]] call BA_fnc_speak;
        };

        // Other tabs: items have 5+ elements
        private _magCount = _item select 3;
        private _type = _item select 4;

        private _announcement = if (_type == "weapon") then {
            private _magText = if (_magCount == 1) then { "magazine" } else { "magazines" };
            format ["%1, %2 %3.", _name, _magCount, _magText]
        } else {
            format ["%1.", _name]
        };
        [_announcement] call BA_fnc_speak;
    };
    case 2: {
        // Options: "[n] of [total]. [option]."
        private _label = _item select 0;
        [format ["%1.", _label]] call BA_fnc_speak;
    };
    case 3: {
        // Mag count: "[n] of [total]. [count]."
        private _value = _item select 1;
        [format ["%1.", _value]] call BA_fnc_speak;
    };
};
