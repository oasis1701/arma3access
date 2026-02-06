/*
 * fn_updateEnemyNerf.sqf - Per-frame enemy nerf update
 *
 * Called every frame, throttled to 1Hz.
 * Scans for hostile units aware of the player and reduces their aiming skills.
 * Only nerfs aiming (accuracy, shake, speed) - leaves other skills intact
 * so enemies still behave naturally (flanking, cover, etc.) but miss more.
 */

// Throttle to 1Hz
if (time - BA_lastEnemyNerfTime < BA_enemyNerfInterval) exitWith {};
BA_lastEnemyNerfTime = time;

// Get the player unit (observer mode or direct control)
private _playerUnit = if (BA_observerMode) then { BA_originalUnit } else { player };

// Safety check
if (isNull _playerUnit || !alive _playerUnit) exitWith {};

private _playerSide = side _playerUnit;
private _playerPos = getPosATL _playerUnit;
private _nerfCount = 0;

// Scan all units for hostile enemies aware of the player
{
    private _enemy = _x;

    // Skip if already nerfed
    if (_enemy in BA_nerfedEnemies) then { continue };

    // Must be alive
    if (!alive _enemy) then { continue };

    // Must be within 1000m
    private _dist = _enemy distance _playerUnit;
    if (_dist > 1000) then { continue };

    // Must be hostile (friendship < 0.6 = enemy)
    if ((side _enemy) getFriend _playerSide >= 0.6) then { continue };

    // Must be aware of the player (knowsAbout >= 1.5)
    private _awareness = _enemy knowsAbout _playerUnit;
    if (_awareness < 1.5) then { continue };

    // Apply aiming nerfs
    _enemy setSkill ["aimingAccuracy", 0];
    _enemy setSkill ["aimingShake", 0];
    _enemy setSkill ["aimingSpeed", 0];

    // Track to avoid redundant calls
    BA_nerfedEnemies pushBack _enemy;
    _nerfCount = _nerfCount + 1;

    // Log the nerf
    diag_log format ["[BA EnemyNerf] Nerfed: %1 at %2m (knowsAbout: %3)", typeOf _enemy, round _dist, _awareness];

} forEach allUnits;

// Prune dead/null units from tracking array
private _before = count BA_nerfedEnemies;
BA_nerfedEnemies = BA_nerfedEnemies select { !isNull _x && alive _x };
private _pruned = _before - count BA_nerfedEnemies;

// Log status if anything changed
if (_nerfCount > 0 || _pruned > 0) then {
    diag_log format ["[BA EnemyNerf] Tracking %1 nerfed enemies, %2 pruned dead", count BA_nerfedEnemies, _pruned];
};
