# Operation Storm — Visual & Graphics Overhaul Design Specification

**Document ID**: `2026-09-05-visual-graphics-overhaul-design`  
**Status**: Validated Design Spec  
**Target Engine**: Godot 4.3+ (GDScript)  
**Aesthetic Theme**: Authentic War-Journal & Military Cartography (Hand-drawn ink outlines, paper parchment texture, cross-hatching, charcoal smoke, ink-wash blood splatters)

---

## 1. Executive Summary & Art Direction

### 1.1 The Vision
Transform *Operation Storm* from its initial prototype state into a visually cohesive, commercial-quality 2D top-down arcade shooter. The game’s presentation is styled as an authentic military field journal and tactical combat map from August 1995. Every on-screen element—from soldier silhouettes and armored vehicles to dirt roads, concrete bunkers, muzzle flashes, and blood pools—looks as if it were rendered with archival black ink, watercolor washes, and charcoal directly onto weathered military map parchment.

### 1.2 War-Journal Style Guide
- **Color Palette**:
  - *Paper Base*: Warm sepia parchment (`#EAE1CE`), aged edges (`#B59E7C`), coffee/moisture stains (`#8B6B48`).
  - *Allied Units (HV - Croatian Army)*: Muted olive-drab fatigue (`#4C5938`), woodland tan (`#857551`), Croatian checkerboard red-white emblem accents (`#C82828`, `#F5F5F0`).
  - *Hostile Forces (ARSK / Paramilitary)*: Dark slate-grey uniforms (`#3C4247`), crimson berets/helmets (`#8F2A2A`), Soviet steel weapon tones (`#2D2E30`).
  - *Combat FX*: Charcoal black smoke plumes (`#1E1E1E`), fiery orange-amber flame bursts (`#FF8C1A`, `#FFDE59`), dark red ink-wash blood (`#630D0D`, `#8B1515`), warm brass casings (`#D9A74A`).
- **Line Work**: Rough pen-and-ink contour outlines (1–2px line weight) with subtle ink jitter and cross-hatch shading on hard surfaces and structures.
- **Surface Textures**: Subtle fibrous paper grain overlay with ink-bleed feathering on high-contrast edges, simulating drawings made with fountain pens and brushes.

---

## 2. Character & Vehicle Visual System

### 2.1 Modular 2D Character Rig
To achieve fluid 360° mouse aiming while retaining natural walking animation and heavy recoil feedback, all infantry units (Player and Enemy classes) utilize a 3-layer modular hierarchy:

```
CharacterBody2D (Player / EnemyBase)
├── ShadowSprite
│   └── Oval ink-wash shadow; stretches and fades dynamically during dodge-rolls
├── LegsSprite
│   ├── 4-frame animated boot walking cycle (Idle, Step L, Pass, Step R)
│   └── Rotates independently to align with the WASD movement/velocity vector
├── TorsoContainer (Rotates 360° to track cursor or AI target)
│   ├── BodySprite (Hand-inked torso, webbing harness, pouches, distinctive headgear)
│   ├── WeaponSprite (Weapon model positioned in hands: M70, Shotgun, SMG, RPG, Sniper, PHP)
│   ├── MuzzleMarker (Spawn origin for projectiles, muzzle flash VFX, and dynamic light)
│   └── BrassEjectionMarker (Spawn point for ejected shell casings)
├── CollisionShape2D
└── VisualEffectsPlayer (Animation player for damage flash, recoil kickback, and roll tumble)
```

### 2.2 Soldier Archetype Silhouettes & Equipment

| Unit Archetype | Silhouette & Headgear | Uniform / Colors | Held Weapon & Distinctive Gear |
|---|---|---|---|
| **Player (Croatian Soldier)** | M59/85 steel helmet with Croatian checkerboard shield badge | Olive-drab camo fatigue, brown canvas webbing | Dynamic: Swaps between M70 rifle, Shotgun, SMG, RPG, Sniper, or Pistol |
| **Rifleman** | Red beret or field cap | Dark grey-olive tunic, canvas ammo pouches | Zastava M70 with wooden handguard & curved magazine |
| **Shotgunner** | Heavy flak jacket, reinforced dark crimson helmet | Charcoal flak vest, tactical leg holsters | Heavy Hawk 12ga pump-action shotgun |
| **Machine Gunner** | Slung ammo belt across chest, heavy steel helmet | Mud-splattered olive battle dress | M84 general-purpose machine gun with bipod |
| **Sniper** | Boonie hat with ghillie foliage strips | Mottled brush camouflage poncho | Scoped M48 Mauser; emits red laser targeting telegraph |
| **Officer** | Peaked officer service cap with gold insignia | Tailored slate-grey jacket, sidearm holster | PHP pistol; projects subtle tactical aura ring beneath feet |
| **Grenadier** | Cross-chest grenade bandolier | Reinforced combat fatigues, leather gloves | M75 stick/egg grenades; wind-up throw gesture |

### 2.3 Death & Defeat Transitions
- When HP reaches 0, units do not immediately vanish.
- A 0.25s ink-collapse animation triggers (character crumples downward, dropping their held weapon).
- A persistent inked casualty graphic / weapon drop decal is stamped to the terrain, blending seamlessly into the background map layer.

### 2.4 Armored Vehicles

#### B-80 Wheeled Armored Personnel Carrier (APC)
- **Chassis**: Hand-inked 8-wheeled armored hull (128×64 px) with camouflage splotches, mud guards, and rear troop deployment doors.
- **Tread/Wheel VFX**: Emits dirt road dust plumes while rolling; lays down subtle tire track decals.
- **Turret**: Independent roof-mounted 360° rotating machine gun cupola with twin barrels.
- **Damage States**:
  - *Intact*: Clean inked armor plating.
  - *Damaged (<50% HP)*: Scratched hull plates, exposed engine smoke wisps.
  - *Destroyed*: Smoldering, blackened open hull wreckage emitting persistent charcoal smoke and flickering fire.

#### T-55 Main Battle Tank
- **Chassis**: Massive heavy steel hull (160×96 px) with dual continuous track assemblies and side armor skirts.
- **Tracks**: Continuously leaves wide, textured mud/dirt track imprints on the ground while traversing.
- **Turret & Cannon**: Fully rotating heavy cast-steel turret with long rifled cannon barrel. Fires with massive barrel recoil kick, colossal muzzle blast, and a ground dust shockwave ring.
- **Engine Louvers (Weak Point)**: The rear engine deck is marked with distinctive inked ventilation grilles; taking damage from the rear triggers distinct metallic penetration spark VFX (3× damage).
- **Destroyed State**: Explodes with a screen-shaking blast; turret dislodges and rests beside the burning chassis.

---

## 3. Environment, Tactical Maps & Illustrated Props

### 3.1 Themed Mission Biomes
Each of the 5 campaign missions is set against a dedicated, authored field-map background:

1. **Mission 1: "First Thunder" (Staging Area — Dawn)**
   - *Terrain*: Compacted staging dirt, tire ruts, dry Balkan grass patches, perimeter barbed wire, tactical pencil grid lines along map margins.
   - *Atmosphere*: Golden early-morning sunrise lighting (`#E8DCB8`).
2. **Mission 2: "Breaking the Line" (Fortified Front — Overcast)**
   - *Terrain*: Deep churned trench mud, zigzagging trench earthworks, timber revetments, artillery craters, and puddle water reflections.
   - *Atmosphere*: Moody slate grey-green overcast sky (`#C4CCC4`).
3. **Mission 3: "Open Road" (Countryside Highway — Midday)**
   - *Terrain*: Paved two-lane asphalt highway running through rural farmland, dry stone field walls, ditch culverts, and dirt side paths.
   - *Atmosphere*: Bright, high-contrast Balkan summer daylight (`#F2EBE0`).
4. **Mission 4: "The Heart" (Petrinja Streets — Smoldering Afternoon)**
   - *Terrain*: Cobblestone streets, curbed pedestrian sidewalks, shattered brick rubble, collapsed masonry, barricaded avenues.
   - *Atmosphere*: Smoky amber haze with airborne ash flecks (`#D0BDAA`).
5. **Mission 5: "Victory" (Knin Fortress — Dusk)**
   - *Terrain*: Ancient medieval limestone flagstones, fortified bastion battlements, cannon embrasures, and the central flagpole plaza.
   - *Atmosphere*: Dramatic crimson-violet sunset glow (`#DEC0B0`).

### 3.2 Architectural Prefabs (Replacing Placeholder Rectangles)
- **Urban Buildings (Mission 4)**:
  - Illustrated roofs: Terracotta clay tiles with cross-hatched shading, corrugated tin patches, brick chimneys, and weathered copper flashings.
  - Inked drop shadows: 15–20px soft directional ink cast shadows along the southern and eastern edges of every building, giving genuine height.
  - Damaged corners: Blown-out walls revealing exposed red brick and mortar textures.
- **Concrete Bunkers & MG Nests (Missions 2, 4, 5)**:
  - Multi-sided reinforced concrete pillboxes with narrow dark embrasure firing slits.
  - Armored front arc with distinct sandbag reinforcement; timber rear entrance door indicating flanking opportunity.
- **Trench Networks (Mission 2)**:
  - Slatted wooden duckboards (boardwalks) laid over muddy soil, supported by sandbag parapets.

### 3.3 Tactical Cover & Prop Library
- **Sandbag Fortifications**: Modular straight (64×24 px), L-corner (48×48 px), and U-shaped revetments with detailed burlap folds and stitch seams.
- **Ammunition & Supply Crates**: Stenciled olive-green wooden crates with brass clasps, green metal footlockers.
- **Fuel & Oil Drums**: 55-gallon ribbed drums with rusted lids and hazard warning markings.
- **Anti-Vehicle Obstacles**: Inked steel Czech hedgehogs and concertina barbed wire rolls.
- **Foliage**: Balkan Scots pine trees and deciduous roadside trees drawn in loose ink brushstrokes with subtle wind sway.

---

## 4. Battlefield VFX, Decals & Dynamic Lighting

### 4.1 Persistent Decal System (`DecalManager`)
To give the combat arena lasting weight and history, a dedicated FIFO decal manager maintains up to 250 active ground decals with seamless performance:

- **Ink-Wash Blood Splatters**: Multi-droplet ink stains stamped beneath hit soldiers; pools expand slightly over 0.2s and persist throughout the battle.
- **Charcoal Scorch Marks**: Burnt radial craters stamped beneath grenade, rocket, tank cannon, and mortar detonations.
- **Spent Brass Shell Casings**: Fired casings eject with randomized lateral velocity, spin in the air, bounce once, and settle on the terrain.
- **Tread Marks**: Continuous tread segment decals deposited beneath moving APC wheels and tank tracks.
- **Bullet Impact Pockmarks**: Concrete chips and dirt puffs on cover obstacles.

### 4.2 Combat Particle Effects (`CombatVfx.gd`)
- **Weapon-Specific Muzzle Flashes**:
  - *Pistol (PHP)*: Snappy 12px ink-spire spark.
  - *Assault Rifle (M70)*: 24px double-star flame burst with lateral gas vents.
  - *Shotgun (Hawk)*: Wide 36px conical flame spray with heavy gunpowder cloud.
  - *Machine Gun (M84)*: Rapid cycling muzzle flame with heat mirage.
  - *Sniper (M48)*: Needle-sharp supersonic flash with lingering white vapor line.
  - *RPG & Tank Cannon*: Massive 64–80px fireball with flying sparks and dust shockwave ring.
- **Multi-Stage Billowing Explosions**:
  1. *Core Burst (0.00–0.08s)*: Blinding orange-white fire core expanding outward.
  2. *Shockwave (0.05–0.20s)*: Rapidly expanding ground dust distortion ring.
  3. *Charcoal Plume (0.15–0.60s)*: Thick black hand-drawn smoke curls billowing and breaking into wisps.
  4. *Debris Sprays (0.00–0.40s)*: High-speed dirt clumps, shrapnel sparks, and wooden splinters.
- **Rocket & Mortar Trajectory Trails**:
  - RPG-7 rockets emit a thick, twisting grey-black rocket motor smoke plume from launch to impact.
  - Mortar shells produce incoming shadow indicators and whistling drop arcs before detonating.
- **Wreckage Fires**:
  - Destroyed vehicles emit continuous looping charcoal smoke plumes and flickering orange fire tongues.

### 4.3 2D Dynamic Lighting & Atmospheric Shading
- **Mission Time-of-Day Grading (`CanvasModulate`)**:
  - Controls overall ambient light level and color temperature for each mission stage without obscuring gameplay readability.
- **Dynamic Point Lights (`PointLight2D`)**:
  - Muzzle flashes spawn 0.05s radius lights (150–400px, energy 1.2–2.5) illuminating the shooter, nearby obstacles, and ground.
  - Detonations emit a rapid 0.3s expanding light radius (800px) that washes the screen in warm amber light.
  - Burning vehicle wrecks have flickering point lights (energy oscillating between 0.7 and 1.1).
  - APCs and tanks feature forward cone headlights for dawn/dusk patrols.

---

## 5. UI, Shaders & War-Journal Polish

### 5.1 Enhanced Paper Overlay Shader (`paper_overlay.gdshader`)
- **Fibrous Parchment Texture**: Samples organic paper fibers, micro-creases, and tactile texture.
- **Aged Edge Vignette**: Soft sepia darkening with subtle moisture rings in the screen corners.
- **Ink-Bleed Convolution**: Softens high-contrast sprite boundaries slightly into the paper, making all rendered elements look printed or hand-drawn directly on the map.
- **Combat Shock Aberration**: High-impact explosions and damage cause a 0.08s micro-chromatic aberration twitch synced with screen shake.

### 5.2 Hand-Drawn Combat HUD (`HUD.tscn`, `HUD.gd`)
- **Sketched Health Gauge**:
  - Outlined in rough black pen hatching with a military red cross insignia.
  - As health depletes, pen cross-hatching fills scratch out.
  - When health drops below 25%, screen edges pulse with an animated charcoal vignette.
- **Inked Ammo & Weapon Badges**:
  - Drawn bullet silhouette tally marks for current magazine + stamped stencil digits for reserve ammo.
  - Weapon slots display clean top-down ink silhouettes of equipped firearms.
  - Throwable counter shows hand-inked M75 grenade and PMR mine stamps with clear numeric badges.
- **Tactical Field-Map Minimap (`Minimap.gd`)**:
  - Styled as a pinned map corner with pencil grid coordinate lines, map pin graphics, and compass rose.
  - Player indicated by a sharp blue ink arrow; hostiles marked by pulsing red ink stamps; objectives marked with the Croatian flag pin.

### 5.3 Briefing, Results & Menu Screens
- **Mission Briefings (`BriefingScreen.tscn`)**:
  - Open field notebook spread with authentic typed military dispatches, polaroid recon photos with paperclip graphics, and tactical map drawings showing historical Croatian and hostile troop movements with hand-drawn advance arrows.
- **Mission Results (`ResultsScreen.tscn`)**:
  - Official Croatian Army combat report form with red ink "MISSION ACCOMPLISHED" / "KIA" rubber-stamp effects, stamped statistics, and hand-drawn medal/ribbon illustrations for performance ranks (A, B, C, D).
- **Main & Pause Menus**:
  - Military field folder aesthetic with bookmark tabs and tactile paper rustle feedback on selection.

---

## 6. Technical Architecture & File Layout

### 6.1 New & Modified Assets
```
assets/
├── shaders/
│   └── paper_overlay.gdshader         # Upgraded with fiber grain, ink bleed, shock aberration
├── sprites/
│   ├── characters/
│   │   ├── player_torso.png           # Inked Croatian soldier torso (48x48)
│   │   ├── enemy_rifleman_torso.png   # Inked Rifleman torso (48x48)
│   │   ├── enemy_shotgunner_torso.png # Inked Shotgunner torso (48x48)
│   │   ├── enemy_mg_torso.png         # Inked Machine Gunner torso (48x48)
│   │   ├── enemy_sniper_torso.png     # Inked Sniper torso (48x48)
│   │   ├── enemy_officer_torso.png    # Inked Officer torso (48x48)
│   │   ├── enemy_grenadier_torso.png  # Inked Grenadier torso (48x48)
│   │   ├── soldier_legs_sheet.png     # 4-frame boot walk cycle spritesheet (32x32 per frame)
│   │   ├── soldier_shadow.png         # Soft oval ink contact shadow (32x16)
│   │   └── casualty_decals.png        # Inked fallen soldier ground stamps
│   ├── vehicles/
│   │   ├── apc_hull.png               # B-80 8-wheeled hull (128x64)
│   │   ├── apc_turret.png             # Twin MG turret (48x32)
│   │   ├── apc_wreck.png              # Destroyed burning APC hull (128x64)
│   │   ├── tank_hull.png              # T-55 armored hull with tracks (160x96)
│   │   ├── tank_turret.png            # Rotating tank cannon turret (112x48)
│   │   └── tank_wreck.png             # Destroyed T-55 tank hull (160x96)
│   ├── terrain/
│   │   ├── terrain_staging.png        # Mission 1 staging earth & grid (512x512 seamless)
│   │   ├── terrain_trenches.png       # Mission 2 mud, timber & shell craters (512x512 seamless)
│   │   ├── terrain_highway.png        # Mission 3 rural road & roadside grass (512x512 seamless)
│   │   ├── terrain_urban.png          # Mission 4 cobblestone & street curbs (512x512 seamless)
│   │   └── terrain_fortress.png       # Mission 5 stone fortress flagstones (512x512 seamless)
│   ├── props/
│   │   ├── building_roof_tiles.png    # Urban cross-hatched tile roof prefab
│   │   ├── building_roof_tin.png      # Corrugated tin roof prefab
│   │   ├── bunker_concrete.png        # Concrete pillbox prefab with firing embrasures
│   │   ├── sandbag_straight.png       # Inked straight sandbag revetment (64x24)
│   │   ├── sandbag_corner.png         # Inked corner sandbag revetment (48x48)
│   │   ├── ammo_crate_wooden.png      # Inked military ammunition box (32x32)
│   │   ├── fuel_drum.png              # Inked 55-gal oil drum (28x28)
│   │   ├── barbed_wire.png            # Inked concertina wire coil (64x20)
│   │   └── tree_ink_sketch.png        # Inked Balkan pine tree top-down (80x80)
│   ├── vfx/
│   │   ├── muzzle_flash_m70.png       # Inked starburst flash
│   │   ├── muzzle_flash_shotgun.png   # Inked conical blast flash
│   │   ├── explosion_charcoal.png     # Multi-frame charcoal smoke puff
│   │   ├── shell_casing_rifle.png     # Spent brass rifle shell (8x4)
│   │   ├── shell_casing_shotgun.png   # Spent red/brass shotgun shell (8x6)
│   │   ├── blood_splatter_decals.png  # Sheet of 6 ink-wash blood stamps
│   │   └── scorch_mark.png            # Charred blast crater decal (64x64)
│   └── ui/
│       ├── paper_parchment_bg.png     # Seamless high-res paper texture (1024x1024)
│       ├── hud_health_frame.png       # Hand-sketched pen health meter frame
│       ├── hud_ammo_frame.png         # Hand-sketched ammo display frame
│       ├── minimap_compass.png        # Vintage nautical/military compass rose
│       └── stamp_mission_complete.png # Red ink "MISSION ACCOMPLISHED" seal stamp
```

### 6.2 New & Modified Scripts
- `scripts/effects/DecalManager.gd` [NEW]: Singleton or scene manager for pooling and stamping blood, scorch, casing, and tread decals.
- `scripts/effects/CombatVfx.gd` [MODIFY]: Updated with multi-stage charcoal explosion spawning, weapon-specific muzzle flashes, bullet casing physics, and dynamic lighting triggers.
- `scripts/player/Player.gd` [MODIFY]: Integrated modular legs walk-cycle tracking, torso rotation, weapon recoil offsets, and dynamic shadow.
- `scripts/enemies/EnemyBase.gd` [MODIFY]: Integrated modular legs walk-cycle, torso aiming, and death collapse decal spawning.
- `scripts/vehicles/VehicleBase.gd`, `Apc.gd`, `Tank.gd` [MODIFY]: Added independent turret rotation, tread decal dropping, and destroyed burning wreck transitions.
- `scripts/ui/HUD.gd` [MODIFY]: Updated with sketched gauge styling and weapon silhouette slot graphics.
- `scripts/ui/PaperOverlay.gd` [MODIFY]: Updated to bind upgraded paper overlay shader uniforms.

---

## 7. Performance & Optimization Strategy

1. **Decal Pooling**: Decals are managed via a fixed-size FIFO buffer (max 250 items). Older decals fade out smoothly (0.5s tween) before being recycled, preventing unbounded node creation or memory leaks.
2. **Particle Efficiency**: Particle systems for smoke and dust utilize Godot 4 `GPUParticles2D` with low individual particle counts (8–16 per emitter) combined with rich hand-drawn textures to achieve high visual volume without CPU overhead.
3. **Lighting Budget**: Dynamic `PointLight2D` nodes for muzzle flashes and explosions are transient (duration ≤ 0.25s) and limited to active on-screen combatants. Ambient lighting is handled in a single pass via `CanvasModulate`.
4. **Draw Call Minimization**: Terrain uses seamless tile textures on full-map `TextureRect` layers; props and cover share unified texture atlases where possible.

---

## 8. Verification & Test Plan

### 8.1 Visual & Aesthetic Verification
- **Aesthetic Cohesion**: Inspect player, enemies, vehicles, cover, terrain, and UI in all 5 missions to confirm uniform war-journal style (ink outlines, muted colors, paper grain).
- **Legs & Torso Alignment**: Test WASD strafing (e.g., walking right while aiming left) to ensure legs rotate in the movement direction while the torso smoothly tracks the cursor.
- **Recoil & Feedback**: Verify each weapon (PHP, M70, Hawk, SMG, Sniper, RPG) displays visible barrel recoil, accurate muzzle flash size, casing ejection, and dynamic point-light illumination.
- **Explosions & Scorch**: Detonate grenades, rockets, and vehicle wrecks; verify the 3-stage blast (flash → shockwave → charcoal cloud) and verify scorch decals persist on terrain.
- **Decal Buffer Stability**: Fire repeatedly and defeat 40+ enemies to verify decals recycle cleanly at the 250 cap without frame drops.

### 8.2 Mission Biome & Structure Verification
- Verify Mission 1 (Dawn staging), Mission 2 (Trenches), Mission 3 (Highway), Mission 4 (Petrinja urban with illustrated buildings replacing ColorRects), and Mission 5 (Fortress flagstones) render with their respective ambient lighting and terrain themes.
- Confirm building and bunker collisions precisely match the visual footprints of the new illustrated structures.

### 8.3 Automated & Headless Checks
- Run Godot 4 editor script checks or headless test runner to ensure all scene files (`.tscn`), resources (`.tres`), and GDScript files load cleanly with zero parse or runtime errors.
