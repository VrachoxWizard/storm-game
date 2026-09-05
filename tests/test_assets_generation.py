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
    # Props (9 assets)
    ("assets/sprites/props/building_roof_tiles.png", (160, 120)),
    ("assets/sprites/props/building_roof_tin.png", (140, 100)),
    ("assets/sprites/props/bunker_concrete.png", (96, 72)),
    ("assets/sprites/props/sandbag_straight.png", (64, 24)),
    ("assets/sprites/props/sandbag_corner.png", (48, 48)),
    ("assets/sprites/props/ammo_crate_wooden.png", (32, 32)),
    ("assets/sprites/props/fuel_drum.png", (28, 28)),
    ("assets/sprites/props/barbed_wire.png", (64, 20)),
    ("assets/sprites/props/tree_ink_sketch.png", (80, 80)),
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

if __name__ == "__main__":
    unittest.main()
