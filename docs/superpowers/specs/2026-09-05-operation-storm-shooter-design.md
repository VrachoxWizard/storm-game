# Operation Storm — 2D Arcade Shooter Design Spec

A top-down 2D arcade shooter set during the Croatian Homeland War, specifically the decisive Operation Storm (August 4-7, 1995). The player controls a Croatian soldier through a 5-mission campaign, using WASD movement and mouse aim/shoot in a hand-drawn war-journal art style. Built with Godot 4 and GDScript.

---

## Core Gameplay Loop

### Controls

- **WASD** — 8-directional movement (diagonal normalization applied)
- **Mouse position** — Player character rotation (always faces cursor)
- **Left click** — Shoot (hold for automatic weapons)
- **Right click / E** — Interact (pick up weapons, open doors)
- **R** — Reload
- **Space** — Dodge-roll (0.3s invincibility window, 1.5s cooldown between rolls)
- **1-3 keys** — Swap between carried weapons (max 3 slots: pistol + 2 pickups)

### Mission Flow

1. Briefing screen (journal page with hand-drawn map, objectives, context)
2. Spawn into mission map with default weapon (Zastava M70 rifle)
3. Push through the map, clearing enemies and completing objectives
4. Pick up weapons, ammo, and health kits from fallen enemies and caches
5. Reach/complete the mission objective (capture a point, destroy a target, survive a holdout)
6. Results screen — kills, accuracy, time, score, rank (A/B/C/D)

### Health System

- Health bar (no regeneration — arcade style)
- Health kit pickups restore chunks of health
- Getting hit causes brief screen shake + red vignette flash
- Death = restart from last checkpoint (2-3 checkpoints per mission)

---

## Campaign Structure — Operation Storm

The campaign follows the real chronology of Operation Storm (August 4-7, 1995). Each mission represents a key phase, with progressive difficulty and new enemy/mechanic introductions.

### Mission 1: "First Thunder" — Artillery Preparation (Aug 4, Dawn)

- **Setting**: Croatian army staging area near the frontlines
- **Objective**: Defend forward positions while the artillery barrage begins. Survive waves of counterattacking enemies
- **Gameplay**: Defensive holdout — introduces basic mechanics, infantry enemies only
- **Tone**: Tense anticipation, the war is about to turn
- **New Enemies**: Rifleman, Shotgunner

### Mission 2: "Breaking the Line" — Frontline Assault (Aug 4-5)

- **Setting**: Fortified enemy defensive line — trenches, bunkers, barbed wire
- **Objective**: Push through enemy fortifications, destroy bunker emplacements, clear the path
- **Gameplay**: Linear assault — introduces bunkers and MG emplacements. First RPG pickup
- **Tone**: Intense, chaotic, breakthrough moment
- **New Enemies**: Machine Gunner, Bunker/MG Nest

### Mission 3: "Open Road" — Armored Push (Aug 5-6)

- **Setting**: Open countryside roads, villages, crossroads
- **Objective**: Advance through enemy territory, neutralize armored vehicles, liberate a village
- **Gameplay**: More open map, introduces APCs and tanks. Mine pickups. Mixed infantry + vehicle combat
- **Tone**: Momentum building, liberation
- **New Enemies**: Sniper, APC, Tank, Minefield

### Mission 4: "The Heart" — Battle for Knin (Aug 5, Afternoon)

- **Setting**: Urban streets of Knin, the symbolic capital
- **Objective**: Fight through the city block by block, reach the Knin Fortress
- **Gameplay**: Dense urban combat, snipers in windows, barricades, mortar positions. All enemy types present
- **Tone**: Climactic, every corner is a fight
- **New Enemies**: Officer, Grenadier, Mortar Position

### Mission 5: "Victory" — The Flag on the Fortress (Aug 5, Evening)

- **Setting**: Knin Fortress exterior and interior
- **Objective**: Clear the final resistance, raise the Croatian flag on the fortress
- **Gameplay**: Final boss-like encounter — heavily fortified position with all threat types. Ends with a cinematic moment
- **Tone**: Triumphant, emotional, historic
- **New Enemies**: None — all types combined at maximum intensity

---

## Enemies & Combat

### Infantry Types

| Enemy | Behavior | First Appears |
|-------|----------|---------------|
| **Rifleman** | Basic soldier, moves toward player, fires in bursts | Mission 1 |
| **Shotgunner** | Rushes the player, deadly at close range, low HP | Mission 1 |
| **Machine Gunner** | Slower movement, high rate of fire, suppresses an area | Mission 2 |
| **Sniper** | Stationary or rooftop, laser sight warns player before shot, high damage | Mission 3 |
| **Officer** | Buffs nearby enemies (faster fire rate), priority target | Mission 4 |
| **Grenadier** | Throws grenades at player position with visible arc/warning circle | Mission 4 |

### Vehicles

| Vehicle | Behavior | Counter |
|---------|----------|---------|
| **APC** | Patrols roads, drops infantry, has a mounted gun | RPG pickup (2-3 hits) |
| **Tank** | Slow, rotates turret to track player, devastating cannon shot | RPG (4-5 hits) or mines |

Vehicles telegraph their attacks — turret rotation sound, engine rumble — so the player can react. They are mini-boss encounters, not constant threats.

### Emplacements

| Emplacement | Behavior | Counter |
|-------------|----------|---------|
| **Bunker / MG Nest** | Fixed position, sweeps fire in an arc, armored front | Flank to hit weak rear, or grenade/RPG |
| **Mortar Position** | Off-screen or distant, drops shells on marked areas (red circles) | Push forward to reach and destroy |
| **Minefield** | Marked with subtle visual hints (disturbed ground), explodes on contact | Careful movement, or shoot to detonate from distance |

### Enemy AI (Simple Arcade Style)

- State machine: **Patrol** → **Alert** (sees/hears player) → **Chase/Attack** → **Dead**
- Enemies push aggressively — arcade action, not tactical simulation
- Difficulty scales through enemy count, spawn rate, and type mix — not smarter AI
- Max ~30-40 active enemies on screen at once; spawn/despawn off-screen

---

## Weapons & Pickups

### Weapons

| Weapon | Type | Behavior | Rarity |
|--------|------|----------|--------|
| **Zastava M70** | Assault Rifle | Default weapon. Semi-auto, reliable, medium damage | Starting weapon |
| **HS Produkt PHP** | Pistol | Fast fire rate, low damage, unlimited ammo (fallback) | Always carried |
| **Škorpion vz.61** | SMG | High fire rate, low accuracy, shreds at close range | Common drop |
| **M48 Mauser** | Sniper Rifle | Slow, bolt-action, very high damage, tight accuracy | Uncommon drop |
| **Hawk 12ga** | Shotgun | Wide spread, devastating close range, slow reload | Common drop |
| **RPG** | Rocket Launcher | Explosive, destroys vehicles/emplacements, very limited ammo (2-4 shots) | Rare — placed at key points |
| **M75 Hand Grenade** | Throwable | Arc throw, area damage, 3-second fuse with visible indicator | Pickup stacks (max 5) |

### Pickup Items

| Pickup | Effect | Visual |
|--------|--------|--------|
| **Ammo Crate** | Refills current weapon ammo | Green wooden box |
| **Health Kit** | Restores 30% health | White box with red cross |
| **Large Health Kit** | Restores 70% health | Larger white box, rare |
| **Armor Vest** | Reduces damage taken by 50% until depleted | Blue vest icon |
| **Mine** | Place on ground, explodes when enemy/vehicle crosses | Metal disc, max 3 carried |

### Weapon Rules

- Player carries: **pistol** (permanent slot) + **2 weapon slots** (swappable)
- Picking up a weapon when slots are full **swaps** with the currently equipped weapon (dropped on ground)
- Each weapon has its own ammo pool — ammo crates refill the currently held weapon
- Weapons dropped by enemies have partial ammo

---

## Art & Audio Direction

### Visual Style — "War Journal"

- **Palette**: Muted, desaturated tones — earthy browns, olive greens, dusty yellows, washed-out blues. Splashes of red for blood/explosions and Croatian checkerboard red-white
- **Line work**: Rough ink-sketch outlines on all sprites, like hand-drawn illustrations. Slightly uneven, organic lines — not clean vector art
- **Textures**: Paper-grain overlay on the entire screen, subtle — like looking at a drawn journal page
- **Environment**: Top-down maps drawn in the same sketch style. Buildings are hatched, roads have pencil-texture, trees are loose ink blobs
- **Characters**: Small but expressive sprites (~32-48px). Croatian soldiers in olive/camo, enemies in darker uniforms. Distinct silhouettes per enemy type
- **Effects**: Muzzle flashes as quick ink-splatter bursts. Explosions as rough charcoal clouds. Blood as ink splatters on the ground

### UI Style

- **HUD**: Minimal, drawn in the same journal style — health bar looks like a sketched gauge, ammo count in handwritten font
- **Briefing screens**: Full journal pages — hand-drawn tactical maps, handwritten mission text, coffee-stain effects, worn edges
- **Mission results**: Stamped text (like military documents), rank displayed as a hand-drawn medal
- **Menus**: Paper/notebook aesthetic, buttons look like tabbed pages

### Audio Direction

- **Music**: Somber, patriotic undertones. Acoustic guitar, strings, subtle military drums. Quiet during stealth moments, swelling during climactic pushes. Elements of Croatian folk music
- **SFX**: Punchy, satisfying weapon sounds. Distinct audio per weapon type. Environmental sounds (wind, distant artillery, radio chatter)
- **Voice**: Optional — brief Croatian voice lines for the player ("Naprijed!", "Pokrivaj me!") add authenticity without heavy voice acting budget

### Camera

- Top-down with slight zoom that pulls back during intense combat (more enemies visible) and tightens during quieter moments

---

## Technical Architecture (Godot 4)

### Scene Tree Structure

```
Main (Node)
├── GameManager (Autoload Singleton)
│   ├── SceneLoader — handles transitions between missions/menus
│   ├── ScoreManager — tracks kills, accuracy, time per mission
│   └── SaveManager — mission unlock progress, high scores
├── UI (CanvasLayer)
│   ├── HUD — health, ammo, weapon slots, grenade count
│   ├── PauseMenu
│   ├── BriefingScreen
│   └── ResultsScreen
└── World (Node2D) — swapped per mission
    ├── TileMap — ground, walls, environment
    ├── Player (CharacterBody2D)
    │   ├── Sprite2D + AnimationPlayer
    │   ├── WeaponManager — handles weapon slots, switching, firing
    │   ├── CollisionShape2D
    │   └── Camera2D
    ├── Enemies (Node2D) — container
    │   ├── EnemyBase (CharacterBody2D) — shared base class
    │   └── Spawner nodes — triggered by area or events
    ├── Vehicles (Node2D) — container
    ├── Emplacements (Node2D) — container
    ├── Pickups (Node2D) — weapon/health/ammo drops
    ├── Projectiles (Node2D) — bullet pool
    └── Objectives (Node2D) — trigger zones for mission goals
```

### Key Systems

| System | Implementation |
|--------|---------------|
| **Movement** | `CharacterBody2D.move_and_slide()`, input vector from WASD, `look_at(get_global_mouse_position())` for rotation |
| **Shooting** | Instanced `Area2D` projectiles (or Raycast for hitscan weapons). Fire rate controlled by `Timer` nodes |
| **Enemy AI** | Simple state machine (Patrol → Alert → Chase → Attack → Dead) in `_physics_process` |
| **Pickups** | `Area2D` with `body_entered` signal. Pickup scenes inherit from base `Pickup` class |
| **Checkpoints** | `Area2D` triggers that save player state (health, weapons, ammo). Death respawns at last checkpoint |
| **Objectives** | Event-driven — `Area2D` zones or enemy-count triggers emit signals to `GameManager` |
| **Screen effects** | `CanvasModulate` for paper overlay, `AnimationPlayer` for hit flash/shake on `Camera2D` |
| **Tilemap** | Godot 4 `TileMap` with terrain layers (ground, walls, obstacles). Collision auto-generated from tile properties |

### File Structure

```
res://
├── scenes/
│   ├── player/         # Player.tscn
│   ├── enemies/        # EnemyBase.tscn, Rifleman.tscn, etc.
│   ├── vehicles/       # APC.tscn, Tank.tscn
│   ├── weapons/        # Projectile.tscn, weapon scenes
│   ├── pickups/        # HealthKit.tscn, AmmoCrate.tscn, etc.
│   ├── ui/             # HUD.tscn, BriefingScreen.tscn, etc.
│   └── missions/       # Mission1.tscn through Mission5.tscn
├── scripts/
│   ├── autoloads/      # GameManager.gd, ScoreManager.gd, SaveManager.gd
│   ├── player/         # Player.gd, WeaponManager.gd
│   ├── enemies/        # EnemyBase.gd, state machine scripts
│   ├── weapons/        # WeaponBase.gd, per-weapon scripts
│   └── ui/             # HUD.gd, BriefingScreen.gd
├── assets/
│   ├── sprites/        # All character, weapon, environment sprites
│   ├── audio/          # Music, SFX, voice
│   ├── fonts/          # Handwritten-style fonts
│   └── tilesets/       # Tileset resources
└── project.godot
```

### Performance Considerations

- **Object pooling** for bullets — reuse instead of instance/free constantly
- **Enemy spawn limits** — max ~30-40 active enemies at once, spawn/despawn off-screen
- **TileMap collision layers** to separate player, enemies, bullets, pickups
- **Collision layers**: Player (1), Enemies (2), Player Bullets (3), Enemy Bullets (4), Pickups (5), Environment (6), Vehicles (7)
