# Operation Storm — 2D Arcade Shooter

A top-down 2D arcade shooter set during the Croatian Homeland War, specifically **Operation Storm (August 4-7, 1995)**. Built with **Godot 4** and **GDScript**.

## Game Overview

Play as a Croatian soldier through a 5-mission campaign covering the decisive military operation that ended the war. Features WASD movement, mouse-aimed shooting, pickup-based weapons, and a distinctive hand-drawn war-journal art style.

### Key Features

- **Top-down arcade action** — WASD movement, mouse aim/rotate/shoot
- **5-mission campaign** — Following the real chronology of Operation Storm
- **Pickup-based weapons** — Find rifles, SMGs, shotguns, sniper rifles, RPGs on the battlefield
- **Diverse enemies** — Infantry types, armored vehicles, fortified emplacements
- **War-journal art style** — Hand-drawn ink-sketch visuals with paper-grain overlay
- **Score system** — Per-mission scoring with kills, accuracy, time, and letter ranks

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Engine | Godot 4.x |
| Language | GDScript |
| Target Platform | Desktop (Windows, Linux, macOS) |

## Project Structure

```
res://
├── scenes/              # All .tscn scene files
│   ├── player/          # Player character scene
│   ├── enemies/         # Enemy type scenes
│   ├── vehicles/        # APC, Tank scenes
│   ├── weapons/         # Weapon and projectile scenes
│   ├── pickups/         # Health, ammo, weapon pickup scenes
│   ├── ui/              # HUD, menus, briefing screens
│   └── missions/        # One .tscn per mission level
├── scripts/             # All .gd script files
│   ├── autoloads/       # Singleton managers (GameManager, ScoreManager, SaveManager)
│   ├── player/          # Player controller, weapon manager
│   ├── enemies/         # Enemy AI, state machines
│   ├── weapons/         # Weapon base class, per-weapon logic
│   └── ui/              # UI controllers
├── assets/              # All game assets
│   ├── sprites/         # Character, weapon, environment sprites
│   ├── audio/           # Music, SFX, voice lines
│   ├── fonts/           # Handwritten-style fonts
│   └── tilesets/        # Tileset resources for TileMap
├── docs/                # Documentation
│   ├── superpowers/     # Design specs
│   └── ARCHITECTURE.md  # Technical architecture
└── project.godot        # Godot project file
```

## Getting Started

### Prerequisites

- [Godot 4.x](https://godotengine.org/download/) (standard version, not .NET)

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
./Run_Game.sh                           # play
./Open_In_Godot.sh                      # editor
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
