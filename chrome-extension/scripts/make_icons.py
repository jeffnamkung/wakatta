"""Render the KotoLens icon (a lens over 言) at every size Chrome needs."""
from PIL import Image, ImageDraw, ImageFont
import os

OUT = os.path.join(os.path.dirname(__file__), "..", "src", "icons")
FONT_CANDIDATES = [
    "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc",
    "/System/Library/Fonts/Hiragino Sans GB.ttc",
    "/System/Library/Fonts/AppleSDGothicNeo.ttc",
]
ACCENT = (194, 65, 12, 255)
CREAM = (255, 247, 237, 255)


def font(size):
    for path in FONT_CANDIDATES:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def render(size, scale=8):
    S = size * scale
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pad = S * 0.04
    d.rounded_rectangle([pad, pad, S - pad, S - pad], radius=S * 0.22, fill=ACCENT)
    # Lens ring
    cx, cy, r = S * 0.44, S * 0.44, S * 0.27
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=CREAM)
    w = S * 0.075
    d.line([cx + r * 0.72, cy + r * 0.72, S * 0.83, S * 0.83], fill=CREAM, width=int(w))
    # 言 inside the lens
    f = font(int(r * 1.35))
    d.text((cx, cy + r * 0.03), "言", font=f, fill=ACCENT, anchor="mm")
    return img.resize((size, size), Image.LANCZOS)


os.makedirs(OUT, exist_ok=True)
for s in (16, 32, 48, 128):
    render(s).save(os.path.join(OUT, f"icon{s}.png"))
render(440).save(os.path.join(os.path.dirname(__file__), "..", "store", "icon-440.png"))
print("icons written")
