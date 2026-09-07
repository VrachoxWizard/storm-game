class_name WeaponResource
extends Resource

## Defines the stats and behavior of a single weapon type.

## Stable identifier used by crosshair, SFX and VFX instead of fragile name matching.
@export var weapon_id: StringName = &"m70"
@export var weapon_name: String = ""
@export var damage: int = 10
@export var fire_rate: float = 0.2  ## seconds between shots
@export var max_ammo: int = 30  ## magazine capacity
@export var starting_reserve: int = 60  ## spare rounds at pickup / mission start
@export var reload_time: float = 1.5
@export var spread_angle: float = 0.0  ## radians of random spread
@export var bullet_speed: float = 600.0
@export var is_automatic: bool = false  ## hold to fire vs tap
@export var projectile_count: int = 1  ## >1 for shotgun
@export var is_pistol: bool = false  ## permanent slot, unlimited ammo
@export var is_explosive: bool = false  ## RPG / splash projectiles
@export var explosion_radius: float = 0.0
@export var explosion_damage: int = 0
## Sprite shown in the player's hands (WeaponSprite node). Facing +X, grip at left.
@export var held_sprite: Texture2D
## Radians of extra spread added per shot while the trigger is held (0 = no bloom).
@export var bloom_per_shot: float = 0.0
## Maximum extra spread from sustained fire.
@export var max_bloom: float = 0.0
## Single-shot disposable launcher (M80 Zolja): discarded automatically after firing.
@export var is_disposable: bool = false
