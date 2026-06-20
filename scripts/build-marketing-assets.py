from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "marketing" / "source"
OUTPUT = ROOT / "assets" / "marketing"
FONT_BOLD = Path(r"C:\Windows\Fonts\malgunbd.ttf")
FONT_REGULAR = Path(r"C:\Windows\Fonts\malgun.ttf")


def font(path: Path, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(path), size=size)


def build_icon() -> None:
    source = Image.open(SOURCE / "momo-icon-keyart.png").convert("RGB")
    icon = ImageOps.fit(source, (512, 512), method=Image.Resampling.LANCZOS)
    border = Image.new("RGBA", icon.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(border)
    draw.rounded_rectangle(
        (8, 8, 504, 504),
        radius=82,
        outline=(255, 255, 255, 210),
        width=10,
    )
    icon = Image.alpha_composite(icon.convert("RGBA"), border)
    icon.save(OUTPUT / "game-icon-512.png", optimize=True)


def build_thumbnail() -> None:
    source = Image.open(SOURCE / "momo-thumbnail-keyart.png").convert("RGB")
    image = ImageOps.fit(source, (1920, 1080), method=Image.Resampling.LANCZOS).convert("RGBA")

    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw.rounded_rectangle((70, 105, 760, 925), radius=54, fill=(25, 10, 62, 176))
    draw.rounded_rectangle((98, 142, 430, 202), radius=30, fill=(255, 113, 139, 240))

    draw.text(
        (264, 172),
        "8–12 PLAYER PARTY",
        font=font(FONT_BOLD, 27),
        fill=(255, 255, 255, 255),
        anchor="mm",
    )
    draw.multiline_text(
        (110, 250),
        "MOMO'S\nART\nACADEMY",
        font=font(FONT_BOLD, 94),
        fill=(255, 255, 255, 255),
        spacing=1,
        stroke_width=3,
        stroke_fill=(72, 35, 145, 255),
    )
    draw.text(
        (112, 650),
        "DRAW  •  GUESS  •  CREATE",
        font=font(FONT_BOLD, 34),
        fill=(255, 207, 90, 255),
    )
    draw.multiline_text(
        (112, 723),
        "그림 그리고, 맞히고,\n함께 즐기는 아트 파티!",
        font=font(FONT_REGULAR, 35),
        fill=(245, 239, 255, 255),
        spacing=14,
    )
    image = Image.alpha_composite(image, overlay).convert("RGB")
    image.save(OUTPUT / "game-thumbnail-1920x1080.jpg", quality=94, optimize=True)


if __name__ == "__main__":
    OUTPUT.mkdir(parents=True, exist_ok=True)
    build_icon()
    build_thumbnail()
    print("Built game-icon-512.png and game-thumbnail-1920x1080.jpg")
