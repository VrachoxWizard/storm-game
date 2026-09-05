# Operation Storm — 2D Arcade Shooter

A top-down 2D arcade shooter set during the Croatian Homeland War, specifically **Operation Storm (August 4-7, 1995)**. Built with **Godot 4** and **GDScript**.

## Game Overview

Play as a Croatian soldier through a 5-mission campaign covering the decisive military operation that ended the war. Features WASD movement, mouse-aimed shooting, pickup-based weapons, and a distinctive hand-drawn war-journal art style.

### Key Features

- **Top-down arcade action** — WASD movement, mouse aim/rotate/shoot
- **5-mission campaign** — Following the real chronology of Operation Storm
- **Pickup-based weapons** — Find rifles, SMGs, shotguns, sniper rifles, RPGs on the battlefield
- **Diverse enemies & vehicles** — 6 infantry classes, B-80 APCs, T-55 boss tank, fortified bunkers and mortars
- **War-journal art style** — Hand-drawn ink-sketch visuals, watercolor wash palettes, and paper-grain overlay
- **Score system** — Per-mission scoring with kills, accuracy, time, and letter ranks

## War-Journal Visual Aesthetic & Art Pipeline

Operation Storm features a distinctive visual identity inspired by historical military field sketches, handwritten logs, and war-journal illustrations:

- **Ink Outlines & Cross-Hatching**: Hand-inked dark sepia contour linework (`#1C1814`) with varied-density cross-hatching to render volume, armor plating, clothing folds, and weapon mechanics.
- **Watercolor Wash Tones**: Muted olive drabs, military khakis, leather browns, and slate grays applied as layered washes, evoking weathered wartime illustrations.
- **Charcoal Smoke & VFX**: Multi-stage charcoal explosions erupt with fiery core bursts, heavy trailing dark plumes, ricochet sparks, and spent brass casings ejected across the ground.
- **Parchment Overlay Shader**: A custom fullscreen Godot 4 shader (`res://assets/shaders/paper_overlay.gdshader`) applies an aged parchment texture, border vignette, and subtle chromatic aberration shock waves during combat explosions and damage events.
- **Modular 2D Character Rigging**: Player and all 6 enemy soldier types feature decoupled, animated 4-frame leg sprites aligned with movement trajectory, 360-degree aiming torsos with weapon recoil kickback, squash/tumble dodge-rolling, and permanent casualty decals stamped upon death.
- **Armored Vehicles & Destruction**: The B-80 APC and T-55 Tank feature 360-degree rotating independent turrets, dynamic ground tread marks stamped as vehicles traverse terrain, rear engine louvers serving as 3x damage weak points, and burnt wreck destruction states with dynamic fire and smoke emitters.
- **Atmospheric 2D Lighting & Environments**: Per-mission `CanvasModulate` tints (dusty staging amber, cold Lika green-gray, pale highway daylight, urban sunset, and Knin fortress dusk) with transient point lights illuminating muzzle flashes, ricochets, and fiery detonations.
- **Sketched HUD & Stamped Reports**: Hand-inked health and ammo HUD frames, a drafted compass rose minimap, and red ink mission completion stamps ("ZADAĆA IZVRŠENA") on briefing and debriefing scrolls.

### Procedural Asset Generation Pipeline

All 42 high-definition visual assets (characters, vehicles, terrain maps, props, VFX, UI frames) are generated deterministically using the built-in Python/Pillow tool pipeline:

```bash
# Generate all 42 war-journal sprite assets
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
│   └── weapons/         # Weapon base class, per-weapon logic
├── assets/              # All game assets
│   ├── fonts/           # Handwritten-style fonts
│   ├── shaders/         # Paper overlay and screen shaders
│   ├── sprites/         # Character, vehicle, terrain, prop, VFX, and UI sprites
│   └── audio/           # Sound effects, voice lines, ambient audio
├── tests/               # Automated test suites (visual, systems, asset validation)
├── tools/               # Procedural asset generator (generate_war_journal_assets.py)
├── docs/                # Documentation and design specs
└── project.godot        # Godot project file
```

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
chmod +x Run_Game.sh Open_In_Godot.sh   # first time only
./Run_Game.sh                           # play (auto-imports assets on first run)
./Open_In_Godot.sh                      # editor (recommended once after clone)
```

If audio or scripts fail on a fresh clone, run `./Open_In_Godot.sh` once so Godot finishes importing, then `./Run_Game.sh` again.

### Running Automated Tests

Run the master visual test suite and individual verification suites using the Godot headless console:

```powershell
# Master visual test runner
& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/run_all_visual_tests.gd --quit

# Individual visual test suites
& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/test_decal_manager.gd --quit
& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/test_combat_vfx.gd --quit
& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/test_character_rigs.gd --quit
& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/test_vehicles_visual.gd --quit
& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/test_missions_visual.gd --quit
& "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/test_ui_visual.gd --quit

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

## License

All rights reserved. This project and its contents are proprietary.
