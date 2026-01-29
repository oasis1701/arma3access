/*
 * Function: BA_fnc_navigateLandmarksMenu
 * Navigates the landmarks menu in the specified direction.
 *
 * Arguments:
 *   0: _direction - "up", "down", "left", or "right"
 *
 * Return Value:
 *   None
 *
 * Example:
 *   ["down"] call BA_fnc_navigateLandmarksMenu;
 */

params [["_direction", "", [""]]];

if (!BA_landmarksMenuActive) exitWith {};

private _categoryNames = ["Geography", "Tactical", "NATO", "Extras"];
private _categoryCount = count BA_landmarksCategories;

switch (_direction) do {
    // Left/Right - switch categories
    case "left": {
        BA_landmarksCategoryIndex = BA_landmarksCategoryIndex - 1;
        if (BA_landmarksCategoryIndex < 0) then {
            BA_landmarksCategoryIndex = _categoryCount - 1;
        };

        private _currentCategory = _categoryNames select BA_landmarksCategoryIndex;
        private _currentItems = BA_landmarksItems select BA_landmarksCategoryIndex;
        private _itemCount = count _currentItems;
        private _currentIndex = BA_landmarksItemIndex select BA_landmarksCategoryIndex;

        private _announcement = format ["%1 category, %2 items. ", _currentCategory, _itemCount];

        if (_itemCount > 0) then {
            private _item = _currentItems select _currentIndex;
            private _description = [_item] call BA_fnc_getLandmarkDescription;
            _announcement = _announcement + format ["%1. %2.", _currentIndex + 1, _description];
        } else {
            _announcement = _announcement + "No items.";
        };

        [_announcement] call BA_fnc_speak;
    };

    case "right": {
        BA_landmarksCategoryIndex = BA_landmarksCategoryIndex + 1;
        if (BA_landmarksCategoryIndex >= _categoryCount) then {
            BA_landmarksCategoryIndex = 0;
        };

        private _currentCategory = _categoryNames select BA_landmarksCategoryIndex;
        private _currentItems = BA_landmarksItems select BA_landmarksCategoryIndex;
        private _itemCount = count _currentItems;
        private _currentIndex = BA_landmarksItemIndex select BA_landmarksCategoryIndex;

        private _announcement = format ["%1 category, %2 items. ", _currentCategory, _itemCount];

        if (_itemCount > 0) then {
            private _item = _currentItems select _currentIndex;
            private _description = [_item] call BA_fnc_getLandmarkDescription;
            _announcement = _announcement + format ["%1. %2.", _currentIndex + 1, _description];
        } else {
            _announcement = _announcement + "No items.";
        };

        [_announcement] call BA_fnc_speak;
    };

    // Up/Down - navigate within category
    case "up": {
        private _currentItems = BA_landmarksItems select BA_landmarksCategoryIndex;
        private _itemCount = count _currentItems;

        if (_itemCount == 0) exitWith {
            ["No items in this category."] call BA_fnc_speak;
        };

        private _currentIndex = BA_landmarksItemIndex select BA_landmarksCategoryIndex;
        _currentIndex = _currentIndex - 1;
        if (_currentIndex < 0) then {
            _currentIndex = _itemCount - 1;
        };
        BA_landmarksItemIndex set [BA_landmarksCategoryIndex, _currentIndex];

        private _item = _currentItems select _currentIndex;
        private _description = [_item] call BA_fnc_getLandmarkDescription;
        [format ["%1. %2.", _currentIndex + 1, _description]] call BA_fnc_speak;
    };

    case "down": {
        private _currentItems = BA_landmarksItems select BA_landmarksCategoryIndex;
        private _itemCount = count _currentItems;

        if (_itemCount == 0) exitWith {
            ["No items in this category."] call BA_fnc_speak;
        };

        private _currentIndex = BA_landmarksItemIndex select BA_landmarksCategoryIndex;
        _currentIndex = _currentIndex + 1;
        if (_currentIndex >= _itemCount) then {
            _currentIndex = 0;
        };
        BA_landmarksItemIndex set [BA_landmarksCategoryIndex, _currentIndex];

        private _item = _currentItems select _currentIndex;
        private _description = [_item] call BA_fnc_getLandmarkDescription;
        [format ["%1. %2.", _currentIndex + 1, _description]] call BA_fnc_speak;
    };
};
