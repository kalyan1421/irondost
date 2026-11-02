#!/usr/bin/env python3
"""Build Apple App Store and Google Play assets from current app captures."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[3]
STORE = ROOT / "apps/customer/store"
CAPTURES = ROOT / "docs/ui-ux-audit/after"
BRAND = ROOT / "packages/brand/icons"
FONT_DISPLAY = ROOT / "docs/ui-ux-audit/fonts/Outfit.ttf"
FONT_BODY = ROOT / "docs/ui-ux-audit/fonts/Figtree.ttf"

SCREEN_SET = [
    ("01-services", "native-catalogue.png"),
    ("02-basket", "native-basket.png"),
    ("03-pickup", "native-schedule.png"),
    ("04-checkout", "native-checkout.png"),
    ("05-search", "native-search.png"),
]

APPLE_SIZE = (1260, 2736)
PLAY_SIZE = (1080, 1920)
MIST = (230, 238, 248)


def font(path: Path, size: int, variation: str | None = None) -> ImageFont.FreeTypeFont:
    result = ImageFont.truetype(str(path), size)
    if variation:
        result.set_variation_by_name(variation)
    return result


def crop_simulator_frame(path: Path) -> Image.Image:
    """Remove macOS Simulator chrome and the outer phone bezel from a capture."""
    image = Image.open(path).convert("RGB")
    # The Oct 5 iPhone 17 Pro captures are 782x1684. This rectangle contains
    # the full display, including the status bar, dynamic island and bottom nav.
    image = image.crop((60, 193, 722, 1628))

    # The simulator source includes the device's rounded display corners. The
    # store panel adds clean corners against its own background instead.
    alpha = Image.new("L", image.size, 0)
    ImageDraw.Draw(alpha).rounded_rectangle(
        (0, 0, image.width - 1, image.height - 1), radius=64, fill=255
    )
    flat = Image.new("RGB", image.size, "white")
    flat.paste(image, (0, 0), alpha)
    return flat


def create_screenshots() -> None:
    app_dir = STORE / "app-store/screenshots"
    play_dir = STORE / "google-play/screenshots"
    app_dir.mkdir(parents=True, exist_ok=True)
    play_dir.mkdir(parents=True, exist_ok=True)

    for directory in (app_dir, play_dir):
        for previous in directory.glob("*.png"):
            previous.unlink()

    for name, capture in SCREEN_SET:
        screen = crop_simulator_frame(CAPTURES / capture)

        # App Store's 6.9-inch portrait target has effectively the same aspect
        # ratio as the iPhone display. Fit the entire current UI to the target.
        apple = screen.resize(APPLE_SIZE, Image.Resampling.LANCZOS)
        apple.save(app_dir / f"{name}.png", optimize=True)

        # Google Play's recommended 9:16 panel is a little wider. Preserve the
        # whole UI at full height and center it on the brand mist background.
        play = Image.new("RGB", PLAY_SIZE, MIST)
        fitted_w = round(screen.width * PLAY_SIZE[1] / screen.height)
        fitted = screen.resize((fitted_w, PLAY_SIZE[1]), Image.Resampling.LANCZOS)
        play.paste(fitted, ((PLAY_SIZE[0] - fitted_w) // 2, 0))
        play.save(play_dir / f"{name}.png", optimize=True)


def create_feature_graphic() -> None:
    source = Image.open(STORE / "google-play/feature-art-source.png").convert("RGB")
    target = source.resize((1024, 500), Image.Resampling.LANCZOS)
    draw = ImageDraw.Draw(target, "RGBA")

    # An unobtrusive tint keeps white type readable without boxing the art.
    for x in range(0, 530):
        alpha = round(38 * (1 - x / 530))
        draw.line((x, 0, x, 500), fill=(14, 30, 61, alpha))

    display = font(FONT_DISPLAY, 68, "Bold")
    body = font(FONT_BODY, 24, "Medium")
    brand = font(FONT_DISPLAY, 22, "SemiBold")

    draw.rounded_rectangle((58, 55, 253, 96), radius=20, fill=(14, 30, 61, 120))
    draw.text((77, 61), "IRON DOST", font=brand, fill=(255, 255, 255, 255))
    draw.text((58, 132), "Laundry day,", font=display, fill=(255, 255, 255, 255))
    draw.text((58, 208), "handled.", font=display, fill=(255, 255, 255, 255))
    draw.rounded_rectangle((60, 307, 145, 315), radius=4, fill=(255, 201, 60, 255))
    draw.text((58, 342), "Pickup & delivery in Hyderabad", font=body, fill=(255, 255, 255, 255))

    target.save(STORE / "google-play/feature-graphic.png", optimize=True)


APPLE_HEADER_SIZE = (3840, 1646)


def create_app_store_header() -> None:
    """App Store product page header (3840 x 1646), from the same art as the Play feature graphic."""
    source = Image.open(STORE / "google-play/feature-art-source.png").convert("RGB")
    width, height = APPLE_HEADER_SIZE

    # The art is a little taller than the header, so trim equally from top and bottom instead of stretching it.
    crop_h = round(source.width * height / width)
    top = (source.height - crop_h) // 2
    target = source.crop((0, top, source.width, top + crop_h)).resize(
        APPLE_HEADER_SIZE, Image.Resampling.LANCZOS
    )
    target = target.filter(ImageFilter.UnsharpMask(radius=2, percent=60, threshold=2))
    draw = ImageDraw.Draw(target, "RGBA")

    # Sizes follow the header's height; the Play graphic is 500 px tall.
    k = height / 500
    clean_w = round(530 * k)
    for x in range(0, clean_w):
        alpha = round(38 * (1 - x / clean_w))
        draw.line((x, 0, x, height), fill=(14, 30, 61, alpha))

    display = font(FONT_DISPLAY, round(68 * k), "Bold")
    body = font(FONT_BODY, round(24 * k), "Medium")
    brand = font(FONT_DISPLAY, round(22 * k), "SemiBold")
    white = (255, 255, 255, 255)

    draw.rounded_rectangle(
        (round(58 * k), round(55 * k), round(253 * k), round(96 * k)),
        radius=round(20 * k),
        fill=(14, 30, 61, 120),
    )
    draw.text((round(77 * k), round(61 * k)), "IRON DOST", font=brand, fill=white)
    draw.text((round(58 * k), round(132 * k)), "Laundry day,", font=display, fill=white)
    draw.text((round(58 * k), round(208 * k)), "handled.", font=display, fill=white)
    draw.rounded_rectangle(
        (round(60 * k), round(307 * k), round(145 * k), round(315 * k)),
        radius=round(4 * k),
        fill=(255, 201, 60, 255),
    )
    draw.text((round(58 * k), round(342 * k)), "Pickup & delivery in Hyderabad", font=body, fill=white)

    target.save(STORE / "app-store/header-3840x1646.png", optimize=True)


def copy_icons() -> None:
    Image.open(BRAND / "ios/AppIcon.appiconset/AppIcon-1024.png").convert("RGB").save(
        STORE / "app-store/app-icon-1024.png", optimize=True
    )
    Image.open(BRAND / "android/play-store-512.png").convert("RGBA").save(
        STORE / "google-play/icon-512.png", optimize=True
    )


if __name__ == "__main__":
    copy_icons()
    create_screenshots()
    create_feature_graphic()
    create_app_store_header()
    print("Built App Store and Google Play assets.")
