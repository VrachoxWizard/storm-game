# Code Conventions

Project-specific conventions for Operation Storm. All AI agents and contributors must follow these.

## GDScript Style

### Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Variables | snake_case | `max_health`, `fire_rate` |
| Functions | snake_case | `take_damage()`, `fire_weapon()` |
| Signals | snake_case (past tense verb) | `health_changed`, `enemy_died` |
| Constants | SCREAMING_SNAKE_CASE | `MAX_AMMO`, `BULLET_SPEED` |
| Enums | PascalCase name, SCREAMING_SNAKE_CASE values | `enum State { PATROL, CHASE }` |
| Classes | PascalCase | `EnemyBase`, `WeaponManager` |
| Nodes | PascalCase | `Player`, `Sprite2D`, `CollisionShape2D` |
| Files | snake_case | `enemy_base.gd`, `weapon_manager.gd` |
| Scenes | PascalCase | `Player.tscn`, `EnemyBase.tscn` |

### Type Hints

Always use type hints for function parameters, return types, and variable declarations:

```gdscript
# Good
var health: int = 100
var speed: float = 200.0
var is_alive: bool = true

func take_damage(amount: int) -> void:
    health -= amount

func get_direction() -> Vector2:
    return Vector2.ZERO

# Bad — no type hints
var health = 100
func take_damage(amount):
    health -= amount
```

### Node References

```gdscript
# Good — use @onready
@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer

# Bad — get_node in _ready
func _ready() -> void:
    sprite = get_node("Sprite2D")  # Don't do this
```

### Export Variables

```gdscript
# Good — documented exports with types
## Maximum health points for this entity.
@export var max_health: int = 100

## Movement speed in pixels per second.
@export var speed: float = 200.0

## The projectile scene to instance when firing.
@export var projectile_scene: PackedScene
```

### Signal Declarations

```gdscript
# Good — typed signals
signal health_changed(new_health: int)
signal died
signal weapon_switched(weapon_index: int)

# Emit with typed arguments
health_changed.emit(health)
```

## File Organization

### Script Structure Order

Every GDScript file should follow this order:

```gdscript
class_name ClassName       # 1. Class name (if needed)
extends BaseClass          # 2. Extends

## Brief description of what this script does.

# --- Signals ---
signal my_signal

# --- Enums ---
enum State { IDLE, ACTIVE }

# --- Constants ---
const MAX_VALUE: int = 100

# --- Exports ---
@export var my_property: int = 0

# --- Public Variables ---
var health: int = 100

# --- Private Variables ---
var _internal_state: State = State.IDLE

# --- @onready ---
@onready var sprite: Sprite2D = $Sprite2D

# --- Built-in Callbacks ---
func _ready() -> void:
    pass

func _process(delta: float) -> void:
    pass

func _physics_process(delta: float) -> void:
    pass

func _unhandled_input(event: InputEvent) -> void:
    pass

# --- Public Methods ---
func take_damage(amount: int) -> void:
    pass

# --- Private Methods ---
func _update_state() -> void:
    pass
```

### File Size Limit

- Keep scripts **under 300 lines**
- If a script is growing large, split responsibilities into child nodes with their own scripts
- Example: Player movement, weapon handling, and health are separate scripts/nodes

## Scene Conventions

### Naming Scenes

- Scene files use PascalCase: `Player.tscn`, `Rifleman.tscn`, `HealthKit.tscn`
- Root node name matches the scene file name
- Script attached to root node matches in snake_case: `Player.tscn` → `player.gd`

### Scene Inheritance

- Enemy types inherit from `EnemyBase.tscn`
- Weapon pickups inherit from `PickupBase.tscn`
- Override `@export` properties in the inherited scene for type-specific values

### Minimap / Objective Groups

Nodes registered in these groups appear on the tactical minimap:

| Group | Color | Used by |
|-------|-------|---------|
| `enemies` | Red | `EnemyBase` |
| `bunker` / `emplacement` | Purple | Bunkers, mortars |
| `vehicle` | Blue | APC, Tank |
| `objective` | Gold | Active `ObjectiveMarker` beacons |
| `flag` | Gold | `FlagObjective` and flag-mode markers |

Mission controllers should drive guidance through `ObjectiveGuidance` / `MissionHelpers.bind_objective_guidance()` rather than manually painting HUD arrows.

## Signals Over Direct References

Prefer signals for communication between independent systems:

```gdscript
# Good — loosely coupled via signal
# In Player.gd:
signal health_changed(new_health: int)

# In HUD.gd:
func _ready() -> void:
    player.health_changed.connect(_on_health_changed)

# Bad — tight coupling
# In Player.gd:
func take_damage(amount: int) -> void:
    health -= amount
    get_node("/root/Main/UI/HUD").update_health(health)  # Don't do this
```

## Git Conventions

### Commit Messages

Use conventional commits:

```
feat: add shotgun weapon type
fix: player clipping through walls on dodge-roll
docs: update architecture diagram
refactor: extract enemy state machine to separate script
asset: add rifleman sprite sheet
```

## Documentation Update Policy (Required)

- **Update docs after bigger changes**: If you make a major gameplay/system/UI change (new feature, new autoload, new resource type, input remap, mission logic change, balance changes, new/changed assets), you **must** update the relevant `.md` documentation in the same change.
- **Docs to keep current**:
  - **Gameplay/UX changes**: `README.md` (player-facing), and `docs/ARCHITECTURE.md` when systems/flows change.
  - **Code/architecture changes**: `docs/ARCHITECTURE.md`, and `AGENTS.md` when core systems/patterns change.
  - **Rules/conventions changes**: `docs/CONVENTIONS.md`.
- **Commit expectation**: Documentation updates should be included in the same PR/commit series as the code changes (`docs:` when docs-only).

### What to Commit

- ✅ `.gd` scripts, `.tscn` scenes, `.tres` resources
- ✅ Asset files (sprites, audio, fonts)
- ✅ `project.godot`, `.gdignore`
- ✅ Documentation (`.md` files)
- ❌ `.godot/` directory (generated cache)
- ❌ `.import/` files (auto-generated by Godot, but some workflows include them)
- ❌ OS-specific files (`.DS_Store`, `Thumbs.db`)

## Testing Approach

- Manual playtesting is the primary testing method (standard for Godot projects)
- Use `print()` and Godot's debugger for development debugging
- Remove or gate debug prints behind a `DEBUG` constant before release
- Test each enemy type, weapon, and pickup individually in isolated test scenes before integrating into missions
