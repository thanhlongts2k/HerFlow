import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

def generate_moona_icon():
    # Render at 2048x2048 for supersampling, then resize to 1024x1024
    w, h = 2048, 2048
    bg_rgb = (30, 27, 46) # #1E1B2E

    # Create background image
    img = Image.new("RGBA", (w, h), (*bg_rgb, 255))
    draw = ImageDraw.Draw(img)

    # 1. Subtle radial ambient glow behind moon
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    
    cx, cy = w // 2 - 40, h // 2
    for r in range(700, 0, -15):
        alpha = int(45 * (1 - r / 700)**1.5)
        glow_draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(235, 87, 137, alpha))
    
    glow = glow.filter(ImageFilter.GaussianBlur(40))
    img = Image.alpha_composite(img, glow)

    # 2. Mathematical Crescent Moon with Gradient
    # Outer circle: center (cx1, cy1), radius r1
    # Inner cutout: center (cx2, cy2), radius r2
    r1 = 480
    c1x, c1y = w // 2 - 60, h // 2
    r2 = 430
    c2x, c2y = w // 2 + 100, h // 2 - 110

    # Grid for smooth vectorized moon calculation
    y, x = np.ogrid[:h, :w]
    d1 = np.sqrt((x - c1x)**2 + (y - c1y)**2)
    d2 = np.sqrt((x - c2x)**2 + (y - c2y)**2)

    # Anti-aliasing margin
    feather = 2.5
    mask1 = np.clip((r1 - d1) / feather + 0.5, 0, 1)
    mask2 = np.clip((d2 - r2) / feather + 0.5, 0, 1)
    moon_alpha = mask1 * mask2

    # Linear gradient for the crescent moon:
    # From Bottom-Left (Rose Magenta #E05388 = 224, 83, 136) 
    # to Top-Right (Soft Peach Gold #FFD6A5 = 255, 214, 165)
    t = (x / w * 0.7 + (h - y) / h * 0.7)
    t = np.clip(t - 0.2, 0, 1)
    
    color_start = np.array([238, 77, 135]) # Rose pink
    color_mid = np.array([255, 140, 165])   # Light petal pink
    color_end = np.array([255, 220, 160])   # Warm moonlight gold

    # Interpolate colors
    t_mid = 0.5
    r_chan = np.where(t < t_mid, 
                      color_start[0] + (color_mid[0] - color_start[0]) * (t / t_mid),
                      color_mid[0] + (color_end[0] - color_mid[0]) * ((t - t_mid) / (1 - t_mid)))
    g_chan = np.where(t < t_mid, 
                      color_start[1] + (color_mid[1] - color_start[1]) * (t / t_mid),
                      color_mid[1] + (color_end[1] - color_mid[1]) * ((t - t_mid) / (1 - t_mid)))
    b_chan = np.where(t < t_mid, 
                      color_start[2] + (color_mid[2] - color_start[2]) * (t / t_mid),
                      color_mid[2] + (color_end[2] - color_mid[2]) * ((t - t_mid) / (1 - t_mid)))

    moon_rgba = np.zeros((h, w, 4), dtype=np.uint8)
    moon_rgba[..., 0] = np.uint8(r_chan)
    moon_rgba[..., 1] = np.uint8(g_chan)
    moon_rgba[..., 2] = np.uint8(b_chan)
    moon_rgba[..., 3] = np.uint8(moon_alpha * 255)

    moon_img = Image.fromarray(moon_rgba, mode="RGBA")
    img = Image.alpha_composite(img, moon_img)

    # 3. Add a twinkling 4-point star nestled in the curve
    star_x, star_y = w // 2 + 190, h // 2 - 80
    star_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    star_draw = ImageDraw.Draw(star_img)

    # Star soft glow
    for r in range(120, 0, -8):
        a = int(60 * (1 - r / 120)**2)
        star_draw.ellipse([star_x - r, star_y - r, star_x + r, star_y + r], fill=(255, 240, 220, a))

    # 4-point diamond sparkle polygon
    r_long = 130
    r_short = 28
    points = [
        (star_x, star_y - r_long),
        (star_x + r_short, star_y - r_short),
        (star_x + r_long, star_y),
        (star_x + r_short, star_y + r_short),
        (star_x, star_y + r_long),
        (star_x - r_short, star_y + r_short),
        (star_x - r_long, star_y),
        (star_x - r_short, star_y - r_short),
    ]
    star_draw.polygon(points, fill=(255, 255, 255, 255))
    
    # Tiny companion star
    c_x, c_y = star_x + 110, star_y + 160
    r_c_long = 45
    r_c_short = 10
    c_points = [
        (c_x, c_y - r_c_long),
        (c_x + r_c_short, c_y - r_c_short),
        (c_x + r_c_long, c_y),
        (c_x + r_c_short, c_y + r_c_short),
        (c_x, c_y + r_c_long),
        (c_x - r_c_short, c_y + r_c_short),
        (c_x - r_c_long, c_y),
        (c_x - r_c_short, c_y - r_c_short),
    ]
    star_draw.polygon(c_points, fill=(255, 240, 245, 230))

    img = Image.alpha_composite(img, star_img)

    # 4. Downsample to 1024x1024 with high-quality Lanczos resampling
    final_icon = img.resize((1024, 1024), Image.Resampling.LANCZOS)
    output_path = "assets/icons/app_icon.png"
    final_icon.save(output_path, "PNG", optimize=True)
    final_icon.save("assets/icons/moona_logo.png", "PNG", optimize=True)
    print(f"[OK] Icon successfully generated at {output_path} and moona_logo.png (1024x1024)")

if __name__ == "__main__":
    generate_moona_icon()
