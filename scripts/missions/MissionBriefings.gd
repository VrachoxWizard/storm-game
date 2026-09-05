class_name MissionBriefings
extends RefCounted

## Central briefing copy for all campaign missions.

const BRIEFINGS: Array[Dictionary] = [
	{
		"title": "Mission 1: First Thunder",
		"description": "August 4, 1995 — Dawn.\n\nThe artillery barrage has begun. Operation Storm is underway.\n\nYour task: Hold the forward positions against enemy counterattacks while our forces prepare the main assault. Survive the waves. Hold the line.\n\nZa dom!",
	},
	{
		"title": "Mission 2: Breaking the Line",
		"description": "August 4-5, 1995 — Frontline.\n\nEnemy fortifications block the advance — trenches, bunkers, and machine-gun nests.\n\nDestroy the bunker emplacements, clear a path through the defensive line, and push forward. An RPG cache awaits near the breach.\n\nNaprijed!",
	},
	{
		"title": "Mission 3: Open Road",
		"description": "August 5-6, 1995 — Countryside.\n\nOpen roads and villages ahead. Armored vehicles and snipers threaten the advance.\n\nNeutralize the APC and tank, clear minefields carefully, and liberate the village crossroads.\n\nSloboda!",
	},
	{
		"title": "Mission 4: The Heart",
		"description": "August 5, 1995 — Knin streets.\n\nFight block by block through the symbolic capital. Officers rally the defense; mortars rain from rooftops.\n\nClear the streets, destroy the mortar battery, and reach the fortress approaches.\n\nZa Hrvatsku!",
	},
	{
		"title": "Mission 5: Victory",
		"description": "August 5, 1995 — Evening. Knin Fortress.\n\nThe final resistance holds the summit. Climb under fire, defeat the T-55, clear the courtyard, and raise the Croatian flag.\n\nHistory waits on the battlements.\n\nOluja!",
	},
]


static func get_briefing(mission_index: int) -> Dictionary:
	if mission_index >= 0 and mission_index < BRIEFINGS.size():
		return BRIEFINGS[mission_index]
	return {"title": "Unknown Mission", "description": ""}
