/*
 * Function: BA_fnc_scanObjects
 * Scans for objects near the cursor position based on current category and range.
 * Results are sorted by distance from cursor.
 *
 * Arguments:
 *   None (uses global state variables)
 *
 * Return Value:
 *   Array - List of objects found (also stored in BA_scannedObjects)
 *
 * Example:
 *   [] call BA_fnc_scanObjects;
 */

// Ensure scanner is initialized
if (isNil "BA_scannerCategories") exitWith {
    BA_scannedObjects = [];
    []
};

// Get current category data
private _categoryData = BA_scannerCategories select BA_scannerCategoryIndex;
private _categoryTypes = _categoryData select 1;
private _filterTag = _categoryData select 2;

// Get cursor position for search center
private _searchPos = if (!isNil "BA_cursorPos") then { BA_cursorPos } else { getPos player };

// Collect all objects matching the category types within range
private _allObjects = [];

{
    private _type = _x;
    private _found = nearestObjects [_searchPos, [_type], BA_scannerRange];
    _allObjects append _found;
} forEach _categoryTypes;

// Remove duplicates (same object might match multiple types)
_allObjects = _allObjects arrayIntersect _allObjects;

// For infantry categories, also include dead bodies and filter out animals
if ((_filterTag find "infantry") == 0) then {
    private _deadBodies = allDeadMen select {
        (_x distance _searchPos) <= BA_scannerRange
    };
    _allObjects append _deadBodies;
    _allObjects = _allObjects arrayIntersect _allObjects;

    // Filter out animals (snakes, rabbits, etc.)
    _allObjects = _allObjects select { !(_x isKindOf "Animal") };

    // Filter out ghost unit (observer mode invisible player)
    if (!isNil "BA_ghostUnit" && {!isNull BA_ghostUnit}) then {
        _allObjects = _allObjects - [BA_ghostUnit];
    };
};

// Filter out clutter objects (by classname only)
_allObjects = _allObjects select {
    private _type = toLower (typeOf _x);
    // Remove fences and barbed wire by classname
    !(_type find "fence" >= 0) &&
    !(_type find "razorwire" >= 0)
};

// Apply category filter if tag is set
if (_filterTag != "") then {
    _allObjects = _allObjects select {
        [_x, _filterTag] call BA_fnc_scannerFilter
    };
};

// Sort by distance from cursor
_allObjects = [_allObjects, [], {_x distance _searchPos}, "ASCEND"] call BIS_fnc_sortBy;

// Store results
BA_scannedObjects = _allObjects;

// Reset object index if it's out of bounds
if (BA_scannerObjectIndex >= count BA_scannedObjects) then {
    BA_scannerObjectIndex = 0;
};

// Return the list
BA_scannedObjects
