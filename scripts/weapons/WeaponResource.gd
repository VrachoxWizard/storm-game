class_name WeaponResource
extends Resource

## Defines the stats and behavior of a single weapon type.

@export var weapon_name: String = ""
@export var damage: int = 10
@export var fire_rate: float = 0.2  ## seconds between shots
@export var max_ammo: int = 30
@export var reload_time: float = 1.5
@export var spread_angle: float = 0.0  ## radians of random spread
@export var bullet_speed: float = 600.0
@export var is_automatic: bool = false  ## hold to fire vs tap
@export var projectile_count: int = 1  ## >1 for shotgun
@export var is_pistol: bool = false  ## permanent slot, unlimited ammo
@export var is_explosive: bool = false  ## RPG / splash projectiles
@export var explosion_radius: float = 0.0
@export var explosion_damage: int = 0
