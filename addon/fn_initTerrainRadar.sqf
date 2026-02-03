/*
 * Function: BA_fnc_initTerrainRadar
 * Initializes the terrain radar audio system state variables.
 *
 * The terrain radar scans the environment in front of the player and produces
 * spatial audio beeps indicating obstacles, terrain, and materials. This helps
 * blind players navigate by creating a mental picture of their surroundings.
 *
 * Features:
 * - 90-degree sweep arc (45 left to 45 right)
 * - Stereo panning based on angle
 * - Volume based on distance (loud = close, quiet = far)
 * - Tone/waveform based on material type
 * - Follows soldier's view direction (pitch + yaw)
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_initTerrainRadar;
 */

// State variables
BA_terrainRadarEnabled = false;      // Whether radar is active
BA_terrainRadarEHId = -1;            // EachFrame event handler ID
BA_terrainRadarSweepStart = 0;       // diag_tickTime when sweep began
BA_terrainRadarLastSample = -1;      // Last sample index sent
BA_terrainRadarDebug = false;        // Debug output (Ctrl+Shift+W)

// Configuration (adjustable)
BA_terrainRadarMaxRange = 100;       // Max detection range (meters)
BA_terrainRadarSweepTime = 1.0;      // Sweep duration (seconds)
BA_terrainRadarSampleCount = 45;     // Samples per sweep (2-degree resolution)
BA_terrainRadarLoudDistance = 0.5;   // Distance for full volume (meters)
BA_terrainRadarQuietDistance = 100;  // Distance for minimum volume (meters)

// Log initialization
diag_log "Blind Assist: Terrain Radar system initialized";
