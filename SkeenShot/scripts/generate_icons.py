#!/usr/bin/env python3
"""Generate SkeenShot app icons (camera viewfinder on Grok-blue)."""
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:
    raise SystemExit("Pillow required: pip3 install pillow")

ROOT = Path(__file__).resolve().parent.parent / "SkeenShot" / "Assets.xcassets" / "AppIcon.appiconset"
BLUE = (0, 122, 255)
WHITE = (255, 255, 255)


def draw_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), BLUE + (255,))
    draw = ImageDraw.Draw(img)
    margin = size * 0.18
    # outer viewfinder frame
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=size * 0.12,
        outline=WHITE,
        width=max(2, size // 32),
    )
    # inner lens circle
    cx = cy = size / 2
    r = size * 0.16
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=WHITE, width=max(2, size // 40))
    # corner brackets (viewfinder)
    b = size * 0.28
    t = max(2, size // 28)
    for x1, y1, x2, y2 in [
        (b, margin * 0.95, b + size * 0.12, margin * 0.95),
        (b, margin * 0.95, b, margin * 0.95 + size * 0.12),
        (size - b, margin * 0.95, size - b - size * 0.12, margin * 0.95),
        (size - b, margin * 0.95, size - b, margin * 0.95 + size * 0.12),
    ]:
        draw.line([x1, y1, x2, y2], fill=WHITE, width=t)
    return img


def main() -> None:
    ROOT.mkdir(parents=True, exist_ok=True)
    for name, size in [("AppIcon.png", 512), ("AppIcon@2x.png", 1024)]:
        draw_icon(size).save(ROOT / name)
    (ROOT / "Contents.json").write_text(
        """{
  "images" : [
    { "filename" : "AppIcon.png", "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "filename" : "AppIcon@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
""",
        encoding="utf-8",
    )
    print(f"Icons written to {ROOT}")


if __name__ == "__main__":
    main()