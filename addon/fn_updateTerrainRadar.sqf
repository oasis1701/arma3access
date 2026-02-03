/*
 * Function: BA_fnc_updateTerrainRadar
 * Per-frame update for terrain radar audio sweep.
 *
 * Performs ray casting across a 90-degree arc following the soldier's view
 * direction (pitch + yaw). Each sample produces a beep with:
 * - Stereo pan based on horizontal angle (-1.0 left to +1.0 right)
 * - Volume based on distance (logarithmic falloff)
 * - Tone based on material type (wall, wood, metal, flesh, etc.)
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_updateTerrainRadar;
 */

// Quick exit if disabled
if (!BA_terrainRadarEnabled) exitWith {};

// Get the soldier to use for ray casting
private _soldier = if (BA_observerMode) then {
    BA_originalUnit
} else {
    player
};

if (isNull _soldier || !alive _soldier) exitWith {};

// Calculate sweep progress (0.0 to 1.0)
private _elapsed = diag_tickTime - BA_terrainRadarSweepStart;
private _progress = _elapsed / BA_terrainRadarSweepTime;

// Check if sweep completed - loop back
if (_progress >= 1.0) then {
    BA_terrainRadarSweepStart = diag_tickTime;
    BA_terrainRadarLastSample = -1;
    _progress = 0;
};

// Calculate current sample index
private _sampleIndex = floor (_progress * BA_terrainRadarSampleCount);

// Only process new samples
if (_sampleIndex == BA_terrainRadarLastSample) exitWith {};
BA_terrainRadarLastSample = _sampleIndex;

// Calculate angle offset for this sample
// Sweep from -45 degrees (left) to +45 degrees (right)
private _normalizedSample = _sampleIndex / (BA_terrainRadarSampleCount - 1);  // 0 to 1
private _angleOffset = -45 + (_normalizedSample * 90);  // -45 to +45 degrees

// Get soldier's eye position and camera direction
private _eyePos = eyePos _soldier;
private _cameraDir = getCameraViewDirection _soldier;  // Includes pitch

// Calculate horizontal (yaw) angle from camera direction
private _cameraYaw = (_cameraDir select 0) atan2 (_cameraDir select 1);  // Radians

// Calculate the ray direction with horizontal offset
// Convert angle offset to radians and apply to camera yaw
private _rayYaw = _cameraYaw + ((_angleOffset * pi) / 180);

// Use camera pitch for vertical component
private _horizMag = sqrt ((_cameraDir select 0)^2 + (_cameraDir select 1)^2);
private _vertComponent = _cameraDir select 2;

// Construct ray direction vector
private _rayDir = [
    _horizMag * sin _rayYaw,
    _horizMag * cos _rayYaw,
    _vertComponent
];

// Normalize ray direction
private _rayMag = vectorMagnitude _rayDir;
if (_rayMag > 0) then {
    _rayDir = _rayDir vectorMultiply (1 / _rayMag);
};

// Calculate ray end point
private _rayEnd = _eyePos vectorAdd (_rayDir vectorMultiply BA_terrainRadarMaxRange);

// Cast ray using lineIntersectsSurfaces
// Returns array of [intersectPosASL, surfaceNormal, intersectObj, parentObject, surfaceType]
private _intersects = lineIntersectsSurfaces [
    _eyePos,
    _rayEnd,
    _soldier,          // Ignore the soldier
    objNull,           // No second object to ignore
    true,              // Sort by distance
    1,                 // Max results
    "GEOM",            // LOD - geometry for accurate collision
    "NONE"             // No special flags
];

// Process intersection result
if (count _intersects > 0) then {
    private _hit = _intersects select 0;
    private _hitPos = _hit select 0;
    private _hitObj = _hit select 2;
    private _surfaceType = _hit select 4;

    // Calculate distance
    private _distance = _eyePos distance _hitPos;

    // Calculate stereo pan from angle offset (-45 to +45 -> -1.0 to +1.0)
    private _pan = _angleOffset / 45;

    // Determine material from surface type or object
    private _material = "default";

    // Get surface type - use different method for terrain vs objects
    private _surfaceStr = "";
    if (isNull _hitObj) then {
        // Hit terrain - use surfaceType command on position (more reliable)
        _surfaceStr = toLower (surfaceType _hitPos);
    } else {
        // Hit object - use lineIntersectsSurfaces result if available
        if (!isNil "_surfaceType" && {_surfaceType isEqualType ""}) then {
            _surfaceStr = toLower _surfaceType;
        };
    };

    // Material detection based on surface type string
    if (_surfaceStr != "") then {
        if ("grass" in _surfaceStr || "soil" in _surfaceStr || "sand" in _surfaceStr || "dirt" in _surfaceStr || "gdt" in _surfaceStr) then {
            // "gdt" catches Arma's terrain types like #GdtGrass, #GdtRock, etc.
            // Further refine gdt types
            if ("rock" in _surfaceStr || "stone" in _surfaceStr || "gravel" in _surfaceStr) then {
                _material = "concrete";  // Rocky terrain
            } else {
                _material = "grass";  // Default terrain to grass
            };
        } else {
            if ("concrete" in _surfaceStr || "asphalt" in _surfaceStr || "rock" in _surfaceStr || "stone" in _surfaceStr) then {
                _material = "concrete";
            } else {
                if ("wood" in _surfaceStr || "plank" in _surfaceStr) then {
                    _material = "wood";
                } else {
                    if ("metal" in _surfaceStr || "iron" in _surfaceStr || "steel" in _surfaceStr) then {
                        _material = "metal";
                    } else {
                        if ("water" in _surfaceStr) then {
                            _material = "water";
                        } else {
                            if ("glass" in _surfaceStr) then {
                                _material = "glass";
                            };
                        };
                    };
                };
            };
        };
    };

    // Check if hit object is a person or use object type fallback
    if (!isNull _hitObj) then {
        if (_hitObj isKindOf "Man") then {
            _material = "man";
        } else {
            // Check object type for additional material hints (only if still default)
            if (_material == "default") then {
                if (_hitObj isKindOf "House" || _hitObj isKindOf "Building") then {
                    _material = "concrete";
                } else {
                    if (_hitObj isKindOf "Tree" || _hitObj isKindOf "Bush") then {
                        _material = "wood";
                    } else {
                        if (_hitObj isKindOf "Car" || _hitObj isKindOf "Tank" || _hitObj isKindOf "Air") then {
                            _material = "metal";
                        };
                    };
                };
            };
        };
    };

    // Debug output to RPT log
    if (BA_terrainRadarDebug) then {
        private _objName = if (isNull _hitObj) then { "terrain" } else { typeOf _hitObj };
        diag_log format ["RADAR [%1] %2deg pan:%3 dist:%4m mat:%5 surf:%6 obj:%7",
            _sampleIndex,
            round _angleOffset,
            _pan toFixed 2,
            round _distance,
            _material,
            _surfaceStr,
            _objName
        ];
    };

    // Send beep command to DLL
    // Format: radar_beep:pan,distance,material
    private _cmd = format ["radar_beep:%1,%2,%3", _pan, _distance, _material];
    "nvda_arma3_bridge" callExtension _cmd;

} else {
    // No hit - send silent beep (distance = max range means very quiet)
    private _pan = _angleOffset / 45;

    // Debug output to RPT log
    if (BA_terrainRadarDebug) then {
        diag_log format ["RADAR [%1] %2deg NO HIT (max range)", _sampleIndex, round _angleOffset];
    };

    private _cmd = format ["radar_beep:%1,%2,none", _pan, BA_terrainRadarMaxRange];
    "nvda_arma3_bridge" callExtension _cmd;
};
