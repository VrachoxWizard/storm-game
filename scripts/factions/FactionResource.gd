class_name FactionResource
extends Resource

## Data-driven faction identity for HV (Croatian) and SVK (Serbian Krajina) forces.

const SIDE_HV: int = 0
const SIDE_SVK: int = 1

## 0 = HV (Hrvatska vojska), 1 = SVK (Srpska vojska Krajine).
@export_enum("HV", "SVK") var side: int = SIDE_HV
## Full display name, e.g. "Hrvatska vojska" or "Srpska vojska Krajine".
@export var display_name: String = ""
## Short code shown in UI, e.g. "HV" or "SVK".
@export var short_name: String = ""
@export var flag_texture: Texture2D = null
@export var insignia_texture: Texture2D = null
## Primary uniform tint applied as a soft modulate on torso sprites.
@export var uniform_tint: Color = Color(1, 1, 1, 1)
## Secondary accent used for armbands / minimap blips.
@export var accent_color: Color = Color(0.75, 0.12, 0.12, 1)
## Named unit labels keyed by class id (rifleman, officer, etc.).
@export var unit_names: Dictionary = {}


func get_unit_label(unit_key: String) -> String:
	if unit_names.has(unit_key):
		return str(unit_names[unit_key])
	return short_name if short_name != "" else display_name


func is_hv() -> bool:
	return side == SIDE_HV


func is_svk() -> bool:
	return side == SIDE_SVK
