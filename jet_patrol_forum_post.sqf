// Jet Patrol Script - Makes an existing jet patrol an area and attack ground targets
// Problem: The jet patrols correctly but won't engage ground targets (tanks, etc.)
// The jet CAN see the targets (reveal works), but won't fire weapons.
// Jet is B_Plane_CAS_01_dynamicLoadout_F (A-164 Wipeout) with full loadout (AGMs, bombs, rockets, cannon)

// _group = group of the jet
// _vehicle = the jet
// _targetPos = center of patrol area (where player placed cursor)
// _radius = patrol radius (1000, 2000, or 4000 meters)

// Clear existing waypoints
while {count waypoints _group > 0} do { deleteWaypoint [_group, 0]; };

// Set altitude (500m default)
private _altitude = _vehicle getVariable ["BA_jetAltitude", 500];
_vehicle flyInHeightASL [_altitude, _altitude, _altitude];

private _radius = 2000;

// Create 3 random SAD waypoints within radius (based on Rydygier's patrol script)
for "_i" from 1 to 3 do {
    private _angle = random 360;
    private _dist = _radius * sqrt(random 1);  // sqrt for even distribution
    private _wpPos = _targetPos getPos [_dist, _angle];
    _wpPos set [2, _altitude];  // Set waypoint altitude

    private _wp = _group addWaypoint [_wpPos, 0];
    _wp setWaypointType "SAD";
};

// CYCLE waypoint to loop patrol
private _wpCycle = _group addWaypoint [_targetPos, 0];
_wpCycle setWaypointType "CYCLE";

_group setCurrentWaypoint (waypoints _group select 0);

// Reveal enemies in patrol area to aircraft group
// (aircraft at altitude can't perceive ground targets naturally)
[_group, _targetPos, _radius] spawn {
    params ["_grp", "_center", "_rad"];
    while {count units _grp > 0} do {
        {
            if (side _x != side _grp && _x distance2D _center < _rad) then {
                _grp reveal [_x, 4];  // 4 = maximum knowledge
            };
        } forEach allUnits;
        sleep 10;
    };
};

// ============================================================================
// WHAT WORKS:
// - Jet patrols the area correctly
// - Jet sees the enemies (nearTargets returns them after reveal)
// - Jet descends to combat altitude when spotting enemies
//
// WHAT DOESN'T WORK:
// - Jet won't fire weapons at ground targets
// - Just keeps orbiting even though it "knows" about the enemy
//
// QUESTION:
// Why won't the AI jet engage ground targets with SAD waypoints, even after
// using reveal with knowledge level 4? Works fine for spawned jets in other scripts.
//
// SETUP:
// - Jet: B_Plane_CAS_01_dynamicLoadout_F (A-164 Wipeout)
// - Spawned in editor with: special="FLY" at 2000m altitude
// - Has full weapons loadout (checked with: weapons vehicle _jet)
//   - Gatling_30mm_Plane_CAS_01_F
//   - Missile_AGM_02_Plane_CAS_01_F (6x AGMs)
//   - Bomb_04_Plane_CAS_01_F (4x bombs)
//   - Rocket_04_HE_Plane_CAS_01_F (7x HE rockets)
//   - Rocket_04_AP_Plane_CAS_01_F (7x AP rockets)
// - Enemy: OPFOR tanks on the ground
// ============================================================================
