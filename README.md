# Operation Storm — 2D Arcade Shooter

A top-down 2D arcade shooter set during the Croatian Homeland War, specifically **Operation Storm (August 4-7, 1995)**. Built with **Godot 4** and **GDScript**.

## Game Overview

Play as a Croatian soldier through a 5-mission campaign covering the decisive military operation that ended the war. Features WASD movement, mouse-aimed shooting, pickup-based weapons, and a distinctive hand-drawn war-journal art style.

### Key Features

- **Top-down arcade action** — WASD movement, mouse aim/rotate/shoot, dodge-roll
- **5-mission campaign** — First Thunder → Breaking the Line → Open Road → The Heart → Victory
- **Authentic HV vs SVK factions** — Croatian HV (Hrvatska vojska) with šahovnica insignia vs Serbian SVK (Srpska vojska Krajine) with tricolor insignia; real brigades, corps, sectors, and dates
- **Real ammo economy** — Magazine + reserve pools; scarce RPG/M48; ammo crates refill reserve
- **Pickup-based weapons** — Find rifles, SMGs, shotguns, sniper rifles, RPGs on the battlefield
- **Diverse enemies & vehicles** — 6 SVK infantry classes with distinct AI, SVK M-80 IFVs, T-55 boss tank, bunkers and mortars
- **War-journal art style** — Hand-drawn ink-sketch visuals, watercolor wash palettes, and paper-grain overlay
- **Audio immersion** — Per-weapon SFX, tension/combat music crossfade, low-pass on critical HP, Croatian voice-line cues
- **Score system** — Per-mission scoring with kills, accuracy, vehicles, emplacements, and letter ranks

## War-Journal Visual Aesthetic & Art Pipeline

Operation Storm features a distinctive visual identity inspired by historical military field sketches, handwritten logs, and war-journal illustrations:

- **Ink Outlines & Cross-Hatching**: Hand-inked dark sepia contour linework (`#1C1814`) with varied-density cross-hatching to render volume, armor plating, clothing folds, and weapon mechanics.
- **Watercolor Wash Tones**: Muted olive drabs, military khakis, leather browns, and slate grays applied as layered washes, evoking weathered wartime illustrations.
- **Charcoal Smoke & VFX**: Multi-stage charcoal explosions erupt with fiery core bursts, heavy trailing dark plumes, ricochet sparks, and spent brass casings ejected across the ground.
- **Parchment Overlay Shader**: A custom fullscreen Godot 4 shader (`res://assets/shaders/paper_overlay.gdshader`) applies an aged parchment texture, border vignette, and subtle chromatic aberration shock waves during combat explosions and damage events.
- **Modular 2D Character Rigging**: Player and all 6 enemy soldier types feature decoupled, animated 4-frame leg sprites aligned with movement trajectory, 360-degree aiming torsos with weapon recoil kickback, squash/tumble dodge-rolling, and permanent casualty decals stamped upon death.
- **Armored Vehicles & Destruction**: The SVK M-80 IFV and T-55 Tank feature 360-degree rotating independent turrets, dynamic ground tread marks stamped as vehicles traverse terrain, rear engine louvers serving as 3x damage weak points, and burnt wreck destruction states with dynamic fire and smoke emitters.
- **Atmospheric 2D Lighting & Environments**: Per-mission `CanvasModulate` tints (dusty staging amber, cold Lika green-gray, pale highway daylight, urban sunset, and Knin fortress dusk) with transient point lights illuminating muzzle flashes, ricochets, and fiery detonations.
- **Sketched HUD & Stamped Reports**: Hand-inked health and ammo HUD frames, a drafted compass rose minimap, and red ink mission completion stamps ("ZADAĆA IZVRŠENA") on briefing and debriefing scrolls.

### Procedural Asset Generation Pipeline

All 47 high-definition visual assets (characters, vehicles, terrain maps, props, VFX, UI frames, faction flags & insignia) are generated deterministically using the built-in Python/Pillow tool pipeline:

```bash
# Generate all war-journal sprite assets (including faction flags/insignia)
python tools/generate_war_journal_assets.py

# Run unit tests validating asset dimensions, opacity, and RGBA modes
pytest tests/test_assets_generation.py
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Engine | Godot 4.x (Standard Edition) |
| Language | GDScript (Type-Hinted) |
| Shaders | Godot Shading Language (CanvasItem) |
| Asset Pipeline | Python 3 + Pillow (Procedural generation) |
| Target Platform | Desktop (Windows, Linux, macOS) |

## Project Structure

```
res://
├── scenes/              # All .tscn scene files
│   ├── effects/         # DecalManager persistent decals
│   ├── enemies/         # Enemy type scenes (Rifleman, Shotgunner, Sniper, MG, Officer, Grenadier, Bunker, Mortar)
│   ├── environment/     # Building roofs, bunker emplacements, props
│   ├── hazards/         # Minefield hazards
│   ├── missions/        # Campaign missions 1–5
│   ├── pickups/         # Health, ammo, weapon pickup scenes
│   ├── player/          # Player character scene
│   ├── ui/              # HUD, menus, briefing screens, results
│   ├── vehicles/        # APC, Tank scenes
│   └── weapons/         # Weapon and projectile scenes
├── scripts/             # All .gd script files
│   ├── autoloads/       # Singleton managers (GameManager, ScoreManager, SaveManager, SoundManager)
│   ├── effects/         # DecalManager, CombatVfx, VfxComponents
│   ├── enemies/         # Enemy AI, state machines
│   ├── missions/        # Mission controllers, checkpoints, objectives
│   ├── player/          # Player controller, weapon manager
│   ├── ui/              # UI controllers, PaperOverlay, Minimap
│   ├── vehicles/        # VehicleBase, Apc, Tank controllers
│   ├── weapons/         # WeaponResource, Projectile, ProjectilePool, rockets/grenades
├── assets/              # All game assets
│   ├── fonts/           # Handwritten-style fonts
│   ├── shaders/         # Paper overlay and screen shaders
│   ├── sprites/         # Character, vehicle, terrain, prop, VFX, and UI sprites
│   └── audio/           # Per-weapon SFX, impact, UI, music (title/tension/combat), ambient
├── tests/               # Automated test suites (visual, systems, asset validation)
├── tools/               # Procedural asset generator (generate_war_journal_assets.py)
├── docs/                # Documentation and design specs
├── Run_Game.bat / Run_Game.sh       # Play launcher (Windows / macOS; auto-finds Godot 4, first-run import)
├── Open_In_Godot.bat / Open_In_Godot.sh  # Editor launcher
└── project.godot        # Godot project file
```

## Campaign Missions

The campaign follows the real chronology of Operation Storm (Aug 4-7, 1995). Each mission is anchored to a real sector, HV brigade, and opposing SVK corps.

| # | Title | Date | Sector | HV Unit | SVK Unit | Focus |
|---|-------|------|--------|---------|----------|-------|
| 1 | First Thunder | Aug 4, dawn | Lika / Gospić | 9th Guards "Vukovi" / 4th Guards | 15th Lika Corps | Wave holdout at staging grounds |
| 2 | Breaking the Line | Aug 4-5 | Lika fortified line (Medak axis) | 9th Guards "Vukovi" | 15th Lika Corps | Destroy bunkers (ordered), breach east; reinforcements |
| 3 | Open Road | Aug 5 | Dalmatian approach (Sinj/Vrlika) | HV armored spearhead | 7th Dalmatian Corps | Stop SVK M-80 convoy, T-55, liberate Kijevo/Vrlika |
| 4 | The Heart | Aug 5, afternoon | Knin streets | 118th Brigade / 9th Guards | Knindže special detachment | Street segments under mortar fire, reach fortress approach |
| 5 | Victory | Aug 5, evening | Knin Fortress | HV assault detachment | Final SVK garrison | Approach climb → T-55 → courtyard → raise the šahovnica |

## Getting Started

### Prerequisites

- [Godot 4.x](https://godotengine.org/download/) (standard version, not .NET)
- [Python 3.10+](https://www.python.org/) with Pillow (for regenerating assets or running asset tests)

### Running the Game

1. Clone this repository
2. Install [Godot 4.x](https://godotengine.org/download/) (standard version, not .NET) — on macOS you can also `brew install --cask godot`
3. Launch with a quick script, or open `project.godot` in Godot and press F5

**Windows**
- `Run_Game.bat` — play the game
- `Open_In_Godot.bat` — open the editor

**macOS**
```bash
bash Run_Game.sh              # play (auto-imports assets on first run)
bash Open_In_Godot.sh         # editor (recommended once after clone)

# Optional: make them double-click / ./ runnable
chmod +x Run_Game.sh Open_In_Godot.sh
./Run_Game.sh
```

Prefer `bash Run_Game.sh` if the project was synced from Windows/OneDrive (execute bits are often stripped). If Godot is installed somewhere unusual: `GODOT_BIN="/path/to/Godot.app/Contents/MacOS/Godot" bash Run_Game.sh`.

`Run_Game.sh` always runs a Godot `--import` pass and will clear a broken `.godot/` cache if critical assets are missing. If audio/textures still fail after a pull, delete the local `.godot` folder and run `bash Run_Game.sh` again (or `bash Open_In_Godot.sh` once).

### Running Automated Tests

Run the master visual test suite and individual verification suites using the Godot headless console:

```powershell
# Run 9 gameplay, campaign and visual-structure suites sequentially
python tools/run_visual_tests.py

# Master visual test runner (headless Godot compilation check)
& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/run_all_visual_tests.gd

# Individual visual test suites
& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/test_decal_manager.gd
& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/test_combat_vfx.gd
& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/test_character_rigs.gd
& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/test_vehicles_visual.gd
& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/test_missions_visual.gd
& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/test_ui_visual.gd

# Asset generator unit tests
pytest tests/test_assets_generation.py
```

### Development

- Open the project in Godot 4 editor (`Open_In_Godot.bat` / `Open_In_Godot.sh`)
- Main scene entry point: `res://scenes/Main.tscn`
- Autoload singletons are registered in Project Settings → Autoload

## Documentation

- [Design Spec](docs/superpowers/specs/2026-09-05-operation-storm-shooter-design.md) — Full game design document
- [Architecture](docs/ARCHITECTURE.md) — Technical architecture and system details
- [Conventions](docs/CONVENTIONS.md) — Code style and project conventions
- **Documentation policy**: after any bigger gameplay/system/UI change, update the relevant `.md` docs in the same change (see `docs/CONVENTIONS.md`).

## License

All rights reserved. This project and its contents are proprietary.


## Gameplay repair pass — 6 September 2026

The camera now uses a stable tactical scale with map bounds. Enemy counts no longer change zoom. The five maps have authored roads, cover, buildings and ramparts; Mission 1 uses staggered east, south and northern-pincer attacks. Infantry pursue assault orders and use short obstacle probes, bunkers retain flankable firing arcs, and aimed grenades reach their selected landing point.

Weapon cooldowns survive switching, repeated reload requests do not restart reloads, and dead players cannot move or fire. Checkpoint recovery resets transient actions and grants two seconds of protection. Fast bullets use swept collision and apply one hit, including tank rear weak points. RPG splash damage is now 100 so armor encounters match the available equipment more closely.

Hidden encounter stages disable physics collisions as well as visibility. Urban street blocks are required objectives. Out-of-order destruction and standing in an exit before its prerequisite clears no longer stall progression. The convoy waits for the player to reach the ambush approach; an escape returns to briefing rather than counting as a destruction. The final flag only unlocks after the courtyard and requires holding E or right mouse.

Run `python tools/run_visual_tests.py` for all suites. The runner rejects assertion failures and runtime errors, and reports shutdown resource warnings separately rather than hiding them. See `docs/verification-2026-09-06.md` for test scope and remaining limitations.


## Authenticity overhaul — 6 September 2026

The campaign is now explicitly anchored to the real Oluja chronology (Aug 4-7, 1995) with authentic Croatian HV vs Serbian SVK (Republika Srpska Krajina) faction identity.

- **FactionResource system** (`scripts/factions/FactionResource.gd` + `resources/factions/hv_faction.tres`, `svk_faction.tres`): data-driven faction identity (side, display name, flag, insignia, uniform tint, accent color, unit names) wired into `EnemyBase`, `VehicleBase`, `Player`, briefing UI, and minimap.
- **Briefings & debriefs**: all 5 mission briefings rewritten with real dates, sectors, HV brigades, SVK corps, and Croatian battle cries (`Za dom!`, `Naprijed!`, `Sloboda!`, `Za Hrvatsku!`, `Oluja!`); narrative debrief paragraphs on the results screen; `GameManager.MISSION_META` exposes sector/brigade/SVK-corp/date.
- **Visuals**: proper 5×5 šahovnica flag (replacing red/white bands); new SVK tricolor flag + SAO Krajina insignia; SVK armbands on all enemy sprites; bearded officer/grenadier militia; HV brigade patch on player; M4 terrain relabeled Petrinja → Knin.
- **Vehicles**: B-80 APC renamed to **SVK M-80 IFV** with SVK tricolor hull marking.
- **Audio**: M75 hand grenade named in code/HUD; `Škorpion vz.61` diacritic fixed; `SoundManager.play_voice_line()` remaps Croatian cues (`Naprijed!`, `Pokrivaj me!`, `Za dom!`, `Oluja!`) onto existing SFX.
- **Bug fixes**: tank weak-point double-damage, sniper ignoring respawn i-frames, dry-fire on valid reload, shotgun pellet loss, enemy bullet pool unbounded growth, steering freeze, rocket detonation on any Area2D, bunker armor using player position, APC deploy without assault order, M4 hardcoded HUD total, M5 ObjectiveTracker desync, Officer aura identity check, burst stale callbacks, accuracy skewed by pellets/explosives, settings not persisted, SaveManager overwriting defaults, burning-wreck particle leak. See `docs/authenticity-overhaul-2026-09-06.md` for the full list.
