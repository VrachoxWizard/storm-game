#!/usr/bin/env python3
"""
Master Visual Test Runner for Operation Storm.
Executes all 6 headless Godot visual test suites and reports overall pass/fail status.
"""

import os
import subprocess
import sys

GODOT_BIN = r"C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"

TESTS = [
    ("Decal Manager", "tests/test_decal_manager.gd"),
    ("Combat VFX & Dynamic Lighting", "tests/test_combat_vfx.gd"),
    ("Character Rigs & Animations", "tests/test_character_rigs.gd"),
    ("Vehicles & Destruction", "tests/test_vehicles_visual.gd"),
    ("Environment & Maps", "tests/test_missions_visual.gd"),
    ("UI & Paper Shader", "tests/test_ui_visual.gd"),
    ("Player Bullet Firing & Damage", "tests/test_bullet_firing.gd"),
]

def main() -> int:
    print("=" * 60)
    print("Operation Storm - Visual Overhaul Full Test Runner")
    print("=" * 60)

    failed = []
    for name, script_path in TESTS:
        print(f"\n[RUNNING] {name} ({script_path})...")
        cmd = [GODOT_BIN, "--headless", "--script", script_path, "--quit"]
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding="utf-8", errors="replace")
        stdout = res.stdout.strip()
        stderr = res.stderr.strip()

        if res.returncode == 0:
            print(f"[PASS] {name}")
            if stdout:
                for line in stdout.splitlines():
                    if "PASS" in line or "Testing" in line or "===" in line:
                        print(f"  {line}")
        else:
            print(f"[FAIL] {name} (exit code {res.returncode})")
            if stdout:
                print(stdout)
            if stderr:
                print(stderr)
            failed.append(name)

    print("\n" + "=" * 60)
    if not failed:
        print(f"ALL {len(TESTS)} VISUAL TEST SUITES PASSED CLEANLY!")
        print("=" * 60)
        return 0
    else:
        print(f"FAILURES DETECTED in {len(failed)} test suites:")
        for f in failed:
            print(f"  - {f}")
        print("=" * 60)
        return 1

if __name__ == "__main__":
    sys.exit(main())
