# Technical Architecture

## System Diagram

```mermaid
graph TB
    subgraph Autoloads["Autoload Singletons"]
        GM["GameManager"]
        SM["ScoreManager"]
        SV["SaveManager"]
        SND["SoundManager"]
    end

    subgraph Effects["World FX under Main"]
        DM["DecalManager"]
        CV["CombatVfx"]
        PP["ProjectilePool"]
        PO["PaperOverlay"]
    end

    subgraph UI["UI Layer"]
        HUD["HUD"]
        PM["PauseMenu"]
        BS["BriefingScreen"]
        RS["ResultsScreen"]
        MM["MainMenu"]
    end

    subgraph World["World Container"]
        PlayerNode["Player + WeaponManager"]
        Enemies["EnemyBase roster"]
        Vehicles["VehicleBase"]
        Objectives["ObjectiveTracker"]
    end

    GM --> World
    GM --> UI
    SM --> RS
    SV --> GM
    SND --> PlayerNode
    SND --> Enemies
    PlayerNode --> PP
    Enemies --> PP
    PlayerNode --> HUD
    CV --> DM
```

## Game State Flow

```mermaid
stateDiagram-v2
    [*] --> MainMenu
    MainMenu --> Briefing
    Briefing --> Gameplay
    Gameplay --> Paused: ESC
    Paused --> Gameplay: ESC
    Paused --> MainMenu: Quit
    Gameplay --> Results: Objective complete
    Results --> Briefing: Next mission
    Results --> MainMenu: Continue
```

## Enemy State Machine

```mermaid
stateDiagram-v2
    [*] --> PATROL
    PATROL --> ALERT: Player detected
    ALERT --> CHASE: Alert timer 0.4-0.8s
    CHASE --> ATTACK: In attack range
    ATTACK --> CHASE: Player out of range
    ATTACK --> DEAD: Health <= 0
    CHASE --> DEAD: Health <= 0
    PATROL --> DEAD: Health <= 0
    ALERT --> DEAD: Health <= 0
    DEAD --> [*]
```

## Core Systems Detail

### Player System

`CharacterBody2D` with modular rig (`ShadowSprite` / `LegsSprite` / `TorsoContainer`):

- WASD movement, mouse-aim torso, dodge-roll i-frames
- Health + armor, grenades/mines, checkpoint save/restore
- Death lock until respawn; screen shake respects settings

### Weapon System

`WeaponManager` manages 3 slots with **magazine + reserve** ammo:

- Reload draws from reserve; pistol unlimited
- Ammo crates refill reserve; weapon pickups grant total rounds
- Per-weapon SFX via `SoundManager.play_weapon_shoot`

### Projectile Pools

- Player: 100-bullet pool on Player
- Enemy/vehicle: `ProjectilePool` on `Main/Projectiles` (80+)
- Rockets/grenades instantiate under Projectiles and are freed on mission exit

### Combat VFX & Decals

- `CombatVfx`: muzzle flashes (capped lights), explosions, ricochets, blood/dust
- `DecalManager`: FIFO 250 blood/scorch/casings/treads; cleared on mission exit

### Audio

- Buses: Master, Music (low-pass), SFX (low-pass)
- Crossfade music (title / tension / combat), ambient wind bed
- Pitch-varied per-weapon and impact SFX

### Objectives

`ObjectiveTracker` supports DESTROY / AREA / KILL_COUNT / SURVIVE with optional **sequential** gating.

### Collision Layers

| Layer | Name | Used By |
|-------|------|---------|
| 1 | Player | Player CharacterBody2D |
| 2 | Enemies | Enemy soldiers |
| 3 | PlayerBullets | Player projectiles |
| 4 | EnemyBullets | Enemy projectiles |
| 5 | Pickups | Health, ammo, weapons |
| 6 | Environment | Walls, sandbags, buildings |
| 7 | Vehicles | APC, Tank |

## Mission Titles (canonical)

Aligned with `GameManager.MISSION_NAMES` and the design spec:

1. First Thunder
2. Breaking the Line
3. Open Road
4. The Heart
5. Victory
