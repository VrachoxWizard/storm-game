import os
import unittest
from PIL import Image

REQUIRED_ASSETS = [
    # Characters (10 assets)
    ("assets/sprites/characters/player_torso.png", (48, 48)),
    ("assets/sprites/characters/enemy_rifleman_torso.png", (48, 48)),
    ("assets/sprites/characters/enemy_shotgunner_torso.png", (48, 48)),
    ("assets/sprites/characters/enemy_mg_torso.png", (48, 48)),
    ("assets/sprites/characters/enemy_sniper_torso.png", (48, 48)),
    ("assets/sprites/characters/enemy_officer_torso.png", (48, 48)),
    ("assets/sprites/characters/enemy_grenadier_torso.png", (48, 48)),
    ("assets/sprites/characters/soldier_legs_sheet.png", (128, 32)),
    ("assets/sprites/characters/soldier_shadow.png", (32, 16)),
    ("assets/sprites/characters/casualty_decals.png", (64, 64)),
    # Vehicles (6 assets)
    ("assets/sprites/vehicles/apc_hull.png", (128, 64)),
    ("assets/sprites/vehicles/apc_turret.png", (48, 32)),
    ("assets/sprites/vehicles/apc_wreck.png", (128, 64)),
    ("assets/sprites/vehicles/tank_hull.png", (160, 96)),
    ("assets/sprites/vehicles/tank_turret.png", (112, 48)),
    ("assets/sprites/vehicles/tank_wreck.png", (160, 96)),
    # Terrain (5 assets)
    ("assets/sprites/terrain/terrain_staging.png", (512, 512)),
    ("assets/sprites/terrain/terrain_trenches.png", (512, 512)),
    ("assets/sprites/terrain/terrain_highway.png", (512, 512)),
    ("assets/sprites/terrain/terrain_urban.png", (512, 512)),
    ("assets/sprites/terrain/terrain_fortress.png", (512, 512)),
    # Props (18 assets)
    ("assets/sprites/props/building_roof_tiles.png", (160, 120)),
    ("assets/sprites/props/building_roof_tin.png", (140, 100)),
    ("assets/sprites/props/building_walls_tiles.png", (160, 28)),
    ("assets/sprites/props/building_walls_tin.png", (140, 28)),
    ("assets/sprites/props/bunker_concrete.png", (96, 72)),
    ("assets/sprites/props/sandbag_straight.png", (64, 24)),
    ("assets/sprites/props/sandbag_corner.png", (48, 48)),
    ("assets/sprites/props/ammo_crate_wooden.png", (32, 32)),
    ("assets/sprites/props/fuel_drum.png", (28, 28)),
    ("assets/sprites/props/barbed_wire.png", (64, 20)),
    ("assets/sprites/props/tree_ink_sketch.png", (80, 80)),
    ("assets/sprites/props/stone_wall.png", (64, 28)),
    ("assets/sprites/props/hay_bale.png", (28, 28)),
    ("assets/sprites/props/wrecked_car.png", (56, 28)),
    ("assets/sprites/props/telegraph_pole.png", (16, 32)),
    ("assets/sprites/props/road_sign.png", (14, 24)),
    ("assets/sprites/props/grass_tuft.png", (16, 16)),
    ("assets/sprites/props/stone_scatter.png", (20, 16)),
    # Held weapon sprites (9 assets)
    ("assets/sprites/weapons/m70_rifle.png", (40, 14)),
    ("assets/sprites/weapons/php_pistol.png", (16, 10)),
    ("assets/sprites/weapons/hawk_shotgun.png", (40, 14)),
    ("assets/sprites/weapons/skorpion_smg.png", (40, 14)),
    ("assets/sprites/weapons/m48_mauser.png", (40, 14)),
    ("assets/sprites/weapons/rpg7.png", (40, 14)),
    ("assets/sprites/weapons/m72_rpk.png", (40, 14)),
    ("assets/sprites/weapons/m76_dmr.png", (40, 14)),
    ("assets/sprites/weapons/m80_zolja.png", (40, 14)),
    # Pickups & legacy restyles (13 assets)
    ("assets/sprites/health_kit.png", (32, 32)),
    ("assets/sprites/large_health.png", (40, 40)),
    ("assets/sprites/ammo_crate.png", (32, 32)),
    ("assets/sprites/weapon_pickup.png", (32, 32)),
    ("assets/sprites/bullet.png", (16, 6)),
    ("assets/sprites/bullet_enemy.png", (16, 6)),
    ("assets/sprites/rocket.png", (24, 8)),
    ("assets/sprites/mortar.png", (48, 48)),
    ("assets/sprites/mine.png", (20, 20)),
    ("assets/sprites/minefield.png", (48, 48)),
    ("assets/sprites/grenade.png", (20, 20)),
    ("assets/sprites/warning_circle.png", (64, 64)),
    ("assets/sprites/armor_vest.png", (28, 28)),
    # VFX (7 assets)
    ("assets/sprites/vfx/muzzle_flash_m70.png", (32, 32)),
    ("assets/sprites/vfx/muzzle_flash_shotgun.png", (48, 32)),
    ("assets/sprites/vfx/explosion_charcoal.png", (64, 64)),
    ("assets/sprites/vfx/shell_casing_rifle.png", (8, 4)),
    ("assets/sprites/vfx/shell_casing_shotgun.png", (8, 6)),
    ("assets/sprites/vfx/blood_splatter_decals.png", (64, 64)),
    ("assets/sprites/vfx/scorch_mark.png", (64, 64)),
    # UI (5 assets)
    ("assets/sprites/ui/paper_parchment_bg.png", (512, 512)),
    ("assets/sprites/ui/hud_health_frame.png", (220, 32)),
    ("assets/sprites/ui/hud_ammo_frame.png", (180, 44)),
    ("assets/sprites/ui/minimap_compass.png", (48, 48)),
    ("assets/sprites/ui/stamp_mission_complete.png", (160, 64)),
    # Faction flags & insignia (official 2:1 flag ratio)
    ("assets/sprites/flag.png", (96, 48)),
    ("assets/sprites/factions/hv_flag.png", (96, 48)),
    ("assets/sprites/factions/svk_flag.png", (96, 48)),
    ("assets/sprites/factions/hv_insignia.png", (32, 32)),
    ("assets/sprites/factions/svk_insignia.png", (32, 32)),
]

FULLY_OPAQUE_BACKGROUNDS = [
    "assets/sprites/terrain/terrain_staging.png",
    "assets/sprites/terrain/terrain_trenches.png",
    "assets/sprites/terrain/terrain_highway.png",
    "assets/sprites/terrain/terrain_urban.png",
    "assets/sprites/terrain/terrain_fortress.png",
    "assets/sprites/ui/paper_parchment_bg.png",
]

CHARACTER_TORSOS = [
    "assets/sprites/characters/player_torso.png",
    "assets/sprites/characters/enemy_rifleman_torso.png",
    "assets/sprites/characters/enemy_shotgunner_torso.png",
    "assets/sprites/characters/enemy_mg_torso.png",
    "assets/sprites/characters/enemy_sniper_torso.png",
    "assets/sprites/characters/enemy_officer_torso.png",
    "assets/sprites/characters/enemy_grenadier_torso.png",
]

class TestWarJournalAssets(unittest.TestCase):
    def test_all_assets_exist_and_valid(self):
        for path, (exp_w, exp_h) in REQUIRED_ASSETS:
            self.assertTrue(os.path.exists(path), f"Asset missing: {path}")
            with Image.open(path) as img:
                self.assertEqual(img.mode, "RGBA", f"Asset not RGBA: {path}")
                self.assertEqual(img.size, (exp_w, exp_h), f"Incorrect size for {path}: {img.size} vs {(exp_w, exp_h)}")

    def test_background_textures_fully_opaque(self):
        """Verifies terrain field maps and UI parchment have 100% opacity across all pixels."""
        for path in FULLY_OPAQUE_BACKGROUNDS:
            with Image.open(path) as img:
                alpha_channel = img.getchannel("A")
                min_alpha, max_alpha = alpha_channel.getextrema()
                self.assertEqual(min_alpha, 255, f"Background {path} has semi-transparent pixels (min alpha {min_alpha})")
                self.assertEqual(max_alpha, 255, f"Background {path} max alpha is not 255")

    def test_character_and_vehicle_solid_bodies_opaque(self):
        """Verifies character torsos and vehicle hulls do not contain low-alpha punch holes in solid bodies."""
        for path in CHARACTER_TORSOS:
            with Image.open(path) as img:
                px = img.load()
                for y in range(19, 29):
                    for x in range(17, 24):
                        alpha = px[x, y][3]
                        self.assertEqual(alpha, 255, f"Character {path} has semi-transparent hole at ({x}, {y}) with alpha {alpha}")

        # APC Hull core
        with Image.open("assets/sprites/vehicles/apc_hull.png") as img:
            px = img.load()
            for y in range(24, 40):
                for x in range(40, 80):
                    alpha = px[x, y][3]
                    self.assertEqual(alpha, 255, f"APC hull has semi-transparent hole at ({x}, {y}) with alpha {alpha}")

        # Tank Hull core
        with Image.open("assets/sprites/vehicles/tank_hull.png") as img:
            px = img.load()
            for y in range(35, 60):
                for x in range(50, 100):
                    alpha = px[x, y][3]
                    self.assertEqual(alpha, 255, f"Tank hull has semi-transparent hole at ({x}, {y}) with alpha {alpha}")

def _hue_assert(testcase, pixel, channel, label):
    """Asserts a pixel leans strongly toward channel 'r', 'g' or 'b', or is 'white'."""
    r, g, b, a = pixel
    testcase.assertGreater(a, 200, f"{label}: pixel not opaque (alpha {a})")
    if channel == "r":
        testcase.assertGreater(r, 150, f"{label}: red band too dark {pixel}")
        testcase.assertGreater(r, g + 60, f"{label}: not red-dominant {pixel}")
        testcase.assertGreater(r, b + 60, f"{label}: not red-dominant {pixel}")
    elif channel == "b":
        testcase.assertGreater(b, r + 40, f"{label}: not blue-dominant {pixel}")
        testcase.assertGreater(b, g + 25, f"{label}: not blue-dominant {pixel}")
    elif channel == "white":
        testcase.assertGreater(min(r, g, b), 170, f"{label}: not bright enough for white band {pixel}")
        testcase.assertLess(abs(r - b), 60, f"{label}: white band too tinted {pixel}")


class TestFactionFlags(unittest.TestCase):
    """Heraldry correctness: Croatian šahovnica flag and SVK tricolor must be RIGHT."""

    def test_croatian_flag_bands_shield_and_crown(self):
        with Image.open("assets/sprites/factions/hv_flag.png") as img:
            px = img.load()
            w, h = img.size
            self.assertEqual((w, h), (96, 48), "Croatian flag must be 2:1 ratio")
            # Bands: red top, white middle, blue bottom (sample far left, away from shield)
            _hue_assert(self, px[8, 5], "r", "HR top band must be RED")
            _hue_assert(self, px[8, 24], "white", "HR middle band must be WHITE")
            _hue_assert(self, px[8, 43], "b", "HR bottom band must be BLUE")
            # Šahovnica checker top-left field must be RED (shield center x=48, checker starts ~39,14)
            _hue_assert(self, px[40, 14], "r", "Šahovnica top-left field must start RED")
            # Crown: pixels above the shield (y ~7) around center must be opaque (5 mini shields)
            crown_opaque = sum(1 for x in range(36, 61) if px[x, 7][3] > 100)
            self.assertGreater(crown_opaque, 8, "Crown of 5 shields missing above šahovnica")

    def test_svk_flag_tricolor_order(self):
        with Image.open("assets/sprites/factions/svk_flag.png") as img:
            px = img.load()
            self.assertEqual(img.size, (96, 48), "SVK flag must be 2:1 ratio")
            # Serbian tricolor: RED top, BLUE middle, WHITE bottom
            _hue_assert(self, px[20, 5], "r", "SVK top band must be RED")
            _hue_assert(self, px[20, 24], "b", "SVK middle band must be BLUE")
            _hue_assert(self, px[20, 43], "white", "SVK bottom band must be WHITE")

    def test_hv_insignia_has_shield_and_crown(self):
        with Image.open("assets/sprites/factions/hv_insignia.png") as img:
            px = img.load()
            # Center of the insignia should be checker red/white (not empty, not flat blue)
            reds = whites = 0
            for y in range(12, 22):
                for x in range(11, 21):
                    r, g, b, a = px[x, y]
                    if a > 200 and r > g + 50:
                        reds += 1
                    elif a > 200 and min(r, g, b) > 160:
                        whites += 1
            self.assertGreater(reds, 5, "Insignia lacks red checker fields")
            self.assertGreater(whites, 5, "Insignia lacks white checker fields")


if __name__ == "__main__":
    unittest.main()
