/*
 * Function: BA_fnc_navigateScanner
 * Navigates through scanner categories and objects.
 * Cursor stays in place; only the selection changes.
 *
 * Arguments:
 *   0: _action - Navigation action:
 *      "category_prev" - Previous category (Ctrl+PageUp)
 *      "category_next" - Next category (Ctrl+PageDown)
 *      "object_prev"   - Previous object in category (PageUp)
 *      "object_next"   - Next object in category (PageDown)
 *
 * Return Value:
 *   Boolean - true if navigation was successful
 *
 * Example:
 *   ["category_next"] call BA_fnc_navigateScanner;
 *   ["object_prev"] call BA_fnc_navigateScanner;
 */

params [["_action", "", [""]]];

// Ensure scanner is initialized
if (isNil "BA_scannerCategories") exitWith {
    ["Scanner not initialized."] call BA_fnc_speak;
    false
};

switch (_action) do {
    case "category_prev": {
        // Move to previous category
        BA_scannerCategoryIndex = BA_scannerCategoryIndex - 1;
        if (BA_scannerCategoryIndex < 0) then {
            BA_scannerCategoryIndex = (count BA_scannerCategories) - 1;
        };

        // Reset object index for new category
        BA_scannerObjectIndex = 0;

        // Refresh objects for new category
        [] call BA_fnc_scanObjects;

        // Get category name
        private _categoryData = BA_scannerCategories select BA_scannerCategoryIndex;
        private _categoryName = _categoryData select 0;
        private _objectCount = count BA_scannedObjects;

        // Announce category change
        [format ["%1, %2 objects", _categoryName, _objectCount]] call BA_fnc_speak;

        true
    };

    case "category_next": {
        // Move to next category
        BA_scannerCategoryIndex = BA_scannerCategoryIndex + 1;
        if (BA_scannerCategoryIndex >= count BA_scannerCategories) then {
            BA_scannerCategoryIndex = 0;
        };

        // Reset object index for new category
        BA_scannerObjectIndex = 0;

        // Refresh objects for new category
        [] call BA_fnc_scanObjects;

        // Get category name
        private _categoryData = BA_scannerCategories select BA_scannerCategoryIndex;
        private _categoryName = _categoryData select 0;
        private _objectCount = count BA_scannedObjects;

        // Announce category change
        [format ["%1, %2 objects", _categoryName, _objectCount]] call BA_fnc_speak;

        true
    };

    case "object_prev": {
        // Check if we have objects
        if (count BA_scannedObjects == 0) exitWith {
            private _categoryData = BA_scannerCategories select BA_scannerCategoryIndex;
            private _categoryName = _categoryData select 0;
            [format ["No %1 in range.", _categoryName]] call BA_fnc_speak;
            false
        };

        // Move to previous object (wrap around)
        BA_scannerObjectIndex = BA_scannerObjectIndex - 1;
        if (BA_scannerObjectIndex < 0) then {
            BA_scannerObjectIndex = (count BA_scannedObjects) - 1;
        };

        // Announce the object (cursor stays in place)
        [] call BA_fnc_announceScannedObject;

        true
    };

    case "object_next": {
        // Check if we have objects
        if (count BA_scannedObjects == 0) exitWith {
            private _categoryData = BA_scannerCategories select BA_scannerCategoryIndex;
            private _categoryName = _categoryData select 0;
            [format ["No %1 in range.", _categoryName]] call BA_fnc_speak;
            false
        };

        // Move to next object (wrap around)
        BA_scannerObjectIndex = BA_scannerObjectIndex + 1;
        if (BA_scannerObjectIndex >= count BA_scannedObjects) then {
            BA_scannerObjectIndex = 0;
        };

        // Announce the object (cursor stays in place)
        [] call BA_fnc_announceScannedObject;

        true
    };

    default {
        false
    };
};
