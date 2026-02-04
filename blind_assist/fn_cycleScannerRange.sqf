/*
 * Function: BA_fnc_cycleScannerRange
 * Cycles the scanner range through predefined values: 10 -> 50 -> 100 -> 500 -> 1000 meters.
 * Announces the new range and refreshes the object list.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Number - The new scanner range
 *
 * Example:
 *   [] call BA_fnc_cycleScannerRange;
 */

// Define range cycle values
private _ranges = [10, 50, 100, 500, 1000];

// Find current range index
private _currentIndex = _ranges find BA_scannerRange;

// If current range not in list (shouldn't happen), start at beginning
if (_currentIndex == -1) then {
    _currentIndex = 0;
} else {
    // Move to next range (wrap around)
    _currentIndex = _currentIndex + 1;
    if (_currentIndex >= count _ranges) then {
        _currentIndex = 0;
    };
};

// Set new range
BA_scannerRange = _ranges select _currentIndex;

// Refresh object list with new range
[] call BA_fnc_scanObjects;

// Get current category info for announcement
private _categoryData = BA_scannerCategories select BA_scannerCategoryIndex;
private _categoryName = _categoryData select 0;
private _objectCount = count BA_scannedObjects;

// Announce new range and object count
[format ["Scanner range: %1 meters. %2 %3.", BA_scannerRange, _objectCount, _categoryName]] call BA_fnc_speak;

BA_scannerRange
