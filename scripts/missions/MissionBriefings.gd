class_name MissionBriefings
extends RefCounted

## Central briefing copy for all campaign missions — authentic Oluja chronology.

const BRIEFINGS: Array[Dictionary] = [
	{
		"title": "Mission 1: First Thunder",
		"date": "4. kolovoza 1995. — zora",
		"sector": "Lika / Gospić",
		"hv_unit": "9. gardijska brigada \"Vukovi\" / 4. gardijska brigada",
		"svk_unit": "15. lički korpus SVK",
		"description": "4. kolovoza 1995. — zora. Sektor Lika / Gospić.\n\nArtillery preparation — \"Prvi grom\" — opens Operation Storm. You fight with the HV 9th Guards \"Vukovi\" and 4th Guards at the staging grounds.\n\nHold the forward depot against counterattacks from the SVK 15th Lika Corps while HV artillery softens their line.\n\nSurvive the waves. Hold the line.\n\nZa dom!",
		"debrief": "The staging grounds held. SVK 15th Lika Corps probes were broken under HV Guards fire as the dawn barrage rolled inland. The road to the Lika fortified belt is open.",
	},
	{
		"title": "Mission 2: Breaking the Line",
		"date": "4.–5. kolovoza 1995.",
		"sector": "Lika fortified line — Medak axis",
		"hv_unit": "9. gardijska brigada \"Vukovi\"",
		"svk_unit": "15. lički korpus SVK",
		"description": "4.–5. kolovoza 1995. — Medak axis, Lika fortified line.\n\nSVK trenches, bunkers, and machine-gun nests of the 15th Lika Corps block the HV advance.\n\nFight with the 9th Guards \"Vukovi\": destroy bunker emplacements in order, clear a breach through the defensive belt, then push east. An RPG cache waits near the gap.\n\nNaprijed!",
		"debrief": "The Medak belt cracked. SVK bunkers fell under flanking fire and RPG strikes; HV infantry poured through the breach. The Lika corridor is broken.",
	},
	{
		"title": "Mission 3: Open Road",
		"date": "5. kolovoza 1995.",
		"sector": "Dalmatian approach — Sinj / Vrlika",
		"hv_unit": "HV armored spearhead",
		"svk_unit": "7. dalmatinski korpus SVK",
		"description": "5. kolovoza 1995. — Sinj / Vrlika approach.\n\nOpen roads and villages ahead. Armor from the SVK 7th Dalmatian Corps — M-80 IFVs and a T-55 — races to escape east.\n\nCut off the convoy with RPGs or mines, destroy the tank, then liberate the village crossroads at Kijevo / Vrlika.\n\nSloboda!",
		"debrief": "The SVK 7th Dalmatian Corps column was stopped on the highway. The M-80 and T-55 lie burning; the village crossroads are free. The road to Knin is clear.",
	},
	{
		"title": "Mission 4: The Heart",
		"date": "5. kolovoza 1995. — poslijepodne",
		"sector": "Knin — streets",
		"hv_unit": "118. brigada HV / 9. gardijska brigada",
		"svk_unit": "Knindže special detachment / street defenders",
		"description": "5. kolovoza 1995. — afternoon. Knin streets.\n\nFight block by block through the symbolic capital of the so-called Republika Srpska Krajina. SVK officers rally the defense; Knindže specials and mortars rain from rooftops.\n\nWith the 118th HV Brigade and 9th Guards: clear the streets, destroy the mortar battery, reach the fortress approaches.\n\nZa Hrvatsku!",
		"debrief": "Knin's streets are cleared. Mortar pits silenced, Knindže resistance broken. HV infantry stands at the foot of the fortress road.",
	},
	{
		"title": "Mission 5: Victory",
		"date": "5. kolovoza 1995. — večer",
		"sector": "Knin Fortress",
		"hv_unit": "HV assault detachment",
		"svk_unit": "Final SVK fortress garrison",
		"description": "5. kolovoza 1995. — evening. Knin Fortress.\n\nThe final SVK garrison holds the summit. Climb under fire, defeat the T-55 on the approach, clear the courtyard, and raise the Croatian šahovnica over the battlements.\n\nHistory waits on the walls of Knin.\n\nOluja!",
		"debrief": "The šahovnica flies over Knin Fortress. The last SVK resistance on the summit is broken. Operation Storm has struck its decisive blow — Republika Hrvatska reclaims its heart.",
	},
]


static func get_briefing(mission_index: int) -> Dictionary:
	if mission_index >= 0 and mission_index < BRIEFINGS.size():
		return BRIEFINGS[mission_index]
	return {"title": "Unknown Mission", "description": "", "debrief": ""}


static func get_debrief(mission_index: int) -> String:
	var briefing: Dictionary = get_briefing(mission_index)
	return str(briefing.get("debrief", ""))
