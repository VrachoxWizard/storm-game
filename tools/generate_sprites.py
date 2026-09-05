import zlib
import struct
import math
import os

def create_png(filename, width, height, pixels):
    raw_data = bytearray()
    for y in range(height):
        raw_data.append(0)  # Filter type 0 (None)
        for x in range(width):
            r, g, b, a = pixels[y * width + x]
            raw_data.extend([r, g, b, a])
    
    def chunk(tag, data):
        crc = zlib.crc32(tag + data) & 0xffffffff
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', crc)
    
    ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    idat = zlib.compress(bytes(raw_data), 9)
    
    png = (
        b'\x89PNG\r\n\x1a\n' +
        chunk(b'IHDR', ihdr) +
        chunk(b'IDAT', idat) +
        chunk(b'IEND', b'')
    )
    
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with open(filename, 'wb') as f:
        f.write(png)
    print(f"Created {filename} ({width}x{height})")

def generate_player():
    w, h = 36, 36
    cx, cy = 16, 18
    pixels = [(0, 0, 0, 0)] * (w * h)
    
    for y in range(h):
        for x in range(w):
            dx = x - cx
            dy = y - cy
            dist = math.hypot(dx, dy)
            
            # Rifle barrel pointing right (x from 18 to 34, y between 19 and 22)
            if 16 <= x <= 33 and 19 <= y <= 22:
                pixels[y * w + x] = (45, 45, 48, 255) # Gun barrel dark steel
                continue
            if 31 <= x <= 34 and 18 <= y <= 23:
                pixels[y * w + x] = (25, 25, 28, 255) # Flash hider / tip
                continue
            if 12 <= x <= 22 and 18 <= y <= 24:
                pixels[y * w + x] = (110, 70, 40, 255) # Wooden handguard / stock

            # Soldier hands
            if (math.hypot(x - 22, y - 20) <= 3) or (math.hypot(x - 14, y - 22) <= 3):
                pixels[y * w + x] = (210, 175, 140, 255)
                continue

            # Body / Torso (Circle radius ~13)
            if dist <= 13:
                # Helmet / Cap (Croatian camouflage tones: olive green, brown, tan)
                if dist <= 8:
                    if (x + y) % 5 in (0, 1):
                        pixels[y * w + x] = (68, 85, 52, 255) # Olive green
                    elif (x + y) % 5 == 2:
                        pixels[y * w + x] = (115, 95, 65, 255) # Tan
                    else:
                        pixels[y * w + x] = (50, 40, 30, 255) # Dark brown
                else:
                    # Shoulders / harness
                    pixels[y * w + x] = (55, 70, 45, 255) # Camo uniform
                # Outline
                if dist >= 12:
                    pixels[y * w + x] = (20, 25, 18, 255)
                    
    create_png('assets/sprites/player.png', w, h, pixels)

def generate_rifleman():
    w, h = 36, 36
    cx, cy = 16, 18
    pixels = [(0, 0, 0, 0)] * (w * h)
    
    for y in range(h):
        for x in range(w):
            dx = x - cx
            dy = y - cy
            dist = math.hypot(dx, dy)
            
            # Rifle barrel pointing right
            if 16 <= x <= 32 and 19 <= y <= 22:
                pixels[y * w + x] = (50, 50, 50, 255)
                continue
            if 12 <= x <= 20 and 19 <= y <= 23:
                pixels[y * w + x] = (90, 60, 35, 255)
                continue
                
            # Hands
            if (math.hypot(x - 22, y - 20) <= 3) or (math.hypot(x - 14, y - 22) <= 3):
                pixels[y * w + x] = (200, 160, 130, 255)
                continue

            # Body
            if dist <= 12:
                if dist <= 7:
                    # Red beret / cap
                    pixels[y * w + x] = (175, 35, 35, 255)
                else:
                    # Gray-olive combat uniform
                    pixels[y * w + x] = (80, 90, 75, 255)
                if dist >= 11:
                    pixels[y * w + x] = (30, 30, 30, 255)
                    
    create_png('assets/sprites/rifleman.png', w, h, pixels)

def generate_shotgunner():
    w, h = 36, 36
    cx, cy = 16, 18
    pixels = [(0, 0, 0, 0)] * (w * h)
    
    for y in range(h):
        for x in range(w):
            dx = x - cx
            dy = y - cy
            dist = math.hypot(dx, dy)
            
            # Heavy shotgun barrel (wider)
            if 16 <= x <= 30 and 18 <= y <= 23:
                pixels[y * w + x] = (40, 42, 45, 255)
                continue
            if 28 <= x <= 31 and 17 <= y <= 24:
                pixels[y * w + x] = (20, 20, 20, 255)
                continue
                
            # Hands
            if (math.hypot(x - 20, y - 20) <= 3) or (math.hypot(x - 13, y - 22) <= 3):
                pixels[y * w + x] = (195, 155, 125, 255)
                continue

            # Heavy armored body
            if dist <= 14:
                if dist <= 7:
                    pixels[y * w + x] = (140, 40, 40, 255) # Dark crimson helmet
                else:
                    pixels[y * w + x] = (50, 52, 58, 255) # Dark tactical armor
                if dist >= 13:
                    pixels[y * w + x] = (25, 25, 28, 255)
                    
    create_png('assets/sprites/shotgunner.png', w, h, pixels)

def generate_bullet():
    w, h = 14, 6
    pixels = [(0, 0, 0, 0)] * (w * h)
    for y in range(h):
        for x in range(w):
            # Tracer bullet shape
            if x <= 10:
                # Golden core with bright center
                if 1 <= y <= 4:
                    pixels[y * w + x] = (255, 240, 120, 255)
                if y in (2, 3) and 2 <= x <= 8:
                    pixels[y * w + x] = (255, 255, 255, 255)
                if y in (0, 5):
                    pixels[y * w + x] = (230, 160, 40, 200)
            elif x <= 13:
                if 1 <= y <= 4:
                    pixels[y * w + x] = (255, 200, 50, 255)
    create_png('assets/sprites/bullet.png', w, h, pixels)

def generate_enemy_bullet():
    w, h = 14, 6
    pixels = [(0, 0, 0, 0)] * (w * h)
    for y in range(h):
        for x in range(w):
            if x <= 10:
                if 1 <= y <= 4:
                    pixels[y * w + x] = (255, 80, 60, 255)
                if y in (2, 3) and 2 <= x <= 8:
                    pixels[y * w + x] = (255, 220, 200, 255)
                if y in (0, 5):
                    pixels[y * w + x] = (200, 40, 30, 200)
            elif x <= 13:
                if 1 <= y <= 4:
                    pixels[y * w + x] = (255, 50, 30, 255)
    create_png('assets/sprites/bullet_enemy.png', w, h, pixels)

def generate_health_kit():
    w, h = 24, 24
    pixels = [(0, 0, 0, 0)] * (w * h)
    for y in range(h):
        for x in range(w):
            # Outer border
            if 2 <= x <= 21 and 2 <= y <= 21:
                # Base white/cream box
                pixels[y * w + x] = (240, 240, 235, 255)
                # Border
                if x in (2, 21) or y in (2, 21):
                    pixels[y * w + x] = (160, 160, 160, 255)
                # Red cross in center
                # vertical bar (x: 10-13, y: 6-17)
                # horizontal bar (x: 6-17, y: 10-13)
                if (10 <= x <= 13 and 6 <= y <= 17) or (6 <= x <= 17 and 10 <= y <= 13):
                    pixels[y * w + x] = (220, 35, 35, 255)
    create_png('assets/sprites/health_kit.png', w, h, pixels)

def generate_ammo_crate():
    w, h = 24, 24
    pixels = [(0, 0, 0, 0)] * (w * h)
    for y in range(h):
        for x in range(w):
            if 2 <= x <= 21 and 2 <= y <= 21:
                # Military olive green crate
                pixels[y * w + x] = (60, 85, 45, 255)
                if x in (2, 21) or y in (2, 21):
                    pixels[y * w + x] = (35, 50, 25, 255)
                # Metal corners
                if (x <= 5 or x >= 18) and (y <= 5 or y >= 18):
                    pixels[y * w + x] = (40, 40, 45, 255)
                # Stenciled gold bullets in middle
                if 8 <= x <= 15 and 9 <= y <= 14:
                    if (x % 3 != 0) and (y in (10, 11, 12, 13)):
                        pixels[y * w + x] = (230, 195, 60, 255)
    create_png('assets/sprites/ammo_crate.png', w, h, pixels)

def generate_weapon_pickup():
    w, h = 26, 26
    pixels = [(0, 0, 0, 0)] * (w * h)
    for y in range(h):
        for x in range(w):
            if 2 <= x <= 23 and 2 <= y <= 23:
                # Stained wooden weapon crate
                pixels[y * w + x] = (125, 80, 45, 255)
                if x in (2, 23) or y in (2, 23):
                    pixels[y * w + x] = (60, 40, 20, 255)
                # Brass reinforced bands
                if x in (6, 19) or y in (6, 19):
                    pixels[y * w + x] = (185, 140, 50, 255)
                # Gun silhouette
                if 8 <= x <= 17 and y == 13:
                    pixels[y * w + x] = (30, 30, 30, 255)
                if 9 <= x <= 11 and y in (14, 15):
                    pixels[y * w + x] = (30, 30, 30, 255)
    create_png('assets/sprites/weapon_pickup.png', w, h, pixels)

def generate_ground_tile():
    w, h = 64, 64
    pixels = [(0, 0, 0, 0)] * (w * h)
    for y in range(h):
        for x in range(w):
            # War-journal / tactical terrain texture (dry grass / dirt / military map grid)
            base_r, base_g, base_b = 62, 70, 52  # Olive dirt
            # Subtle noise variation
            noise = ((x * 13 + y * 29 + (x ^ y) * 7) % 19) - 9
            r = max(0, min(255, base_r + noise))
            g = max(0, min(255, base_g + noise))
            b = max(0, min(255, base_b + noise))
            
            # Subtle grid line every 64 pixels at border
            if x == 0 or y == 0 or x == 63 or y == 63:
                r, g, b = int(r * 0.85), int(g * 0.85), int(b * 0.85)
                
            pixels[y * w + x] = (r, g, b, 255)
    create_png('assets/sprites/ground_tile.png', w, h, pixels)

def generate_sandbag():
    w, h = 48, 20
    pixels = [(0, 0, 0, 0)] * (w * h)
    for y in range(h):
        for x in range(w):
            if 1 <= y <= 18 and 1 <= x <= 46:
                # Burlap sandbag color
                pixels[y * w + x] = (165, 140, 95, 255)
                if (x % 16 in (0, 15)) or (y % 10 in (0, 9)):
                    pixels[y * w + x] = (115, 95, 60, 255)
                if x in (1, 46) or y in (1, 18):
                    pixels[y * w + x] = (85, 70, 45, 255)
    create_png('assets/sprites/sandbag.png', w, h, pixels)

generate_player()
generate_rifleman()
generate_shotgunner()
generate_bullet()
generate_enemy_bullet()
generate_health_kit()
generate_ammo_crate()
generate_weapon_pickup()
generate_ground_tile()
generate_sandbag()
print("All sprites generated successfully!")
