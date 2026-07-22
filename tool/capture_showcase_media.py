#!/usr/bin/env python3
"""Capture individual Braven Charts examples as package media.

Requirements:
    python -m pip install selenium Pillow

The script records the real Flutter web application with Chrome. Focused
interaction recordings use reusable Gallery charts, consistent crops, and no
promotional caption overlays. It writes compact GIF files suitable for the
README and pub.dev screenshots.
"""

from __future__ import annotations

import argparse
import io
import math
import shutil
import subprocess
import time
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageChops, ImageDraw, ImageFont, ImageOps
from selenium import webdriver
from selenium.webdriver.chrome.options import Options


VIEWPORT = (1440, 900)
MOBILE_VIEWPORT = (500, 1000)
INTERACTION_CROP = (280, 12, 1418, 518)
HERO_CROP = (280, 0, 1418, 688)
HERO_PANEL_CROP = (444, 228, 996, 672)
LIVE_CROP = (272, 300, 1110, 880)
INTERACTION_SIZE = (900, 400)
LIVE_SIZE = (754, 522)
FOCUSED_MEDIA_CROP = (120, 90, 1320, 810)
FOCUSED_MEDIA_SIZE = (800, 480)
PATH_WORKBENCH_CROP = (264, 112, 1120, 884)
FRAME_DURATION_MS = 110
BRAND = "#4F46E5"
INK = "#262230"
SURFACE = "#F8F7FC"

LEFT_CARD = (281, 20, 832, 463)
RIGHT_CARD = (865, 20, 1416, 463)
GALLERY_MOSAIC_ASSETS = (
    "gallery_baseline.png",
    "gallery_vo2_stage.png",
    "gallery_glow.png",
    "gallery_lactate.png",
    "gallery_live_sensor.png",
    "gallery_multi_sensor.png",
    "gallery_annotated.png",
    "gallery_dashboard.png",
    "gallery_temperature.png",
    "gallery_quarterly_pipeline.png",
    "gallery_experiment_cohorts.png",
    "gallery_revenue_forecast.png",
    "gallery_interpolation.png",
    "gallery_system_load.png",
    "gallery_profit_loss.png",
)


def _font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    windows_fonts = Path("C:/Windows/Fonts")
    candidates = [
        windows_fonts / ("segoeuib.ttf" if bold else "segoeui.ttf"),
        windows_fonts / ("arialbd.ttf" if bold else "arial.ttf"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size=size)
    return ImageFont.load_default(size=size)


CAPTION_FONT = _font(20, bold=True)


def _driver(
    *,
    disable_gpu: bool = True,
    viewport: tuple[int, int] = VIEWPORT,
) -> webdriver.Chrome:
    options = Options()
    options.binary_location = "C:/Program Files/Google/Chrome/Application/chrome.exe"
    arguments = [
        "--headless=new",
        "--hide-scrollbars",
        "--force-device-scale-factor=1",
        f"--window-size={viewport[0]},{viewport[1]}",
        "--no-first-run",
        "--no-default-browser-check",
        "--run-all-compositor-stages-before-draw",
        "--disable-features=PaintHolding",
    ]
    if disable_gpu:
        arguments.append("--disable-gpu")
    for argument in arguments:
        options.add_argument(argument)

    driver = webdriver.Chrome(options=options)
    driver.execute_cdp_cmd(
        "Emulation.setDeviceMetricsOverride",
        {
            "width": viewport[0],
            "height": viewport[1],
            "deviceScaleFactor": 1,
            "mobile": False,
        },
    )
    return driver


def _mobile_showcase_still(base_url: str, output_dir: Path) -> None:
    """Capture the automatic phone showcase at a repeatable narrow viewport."""
    driver = _driver(viewport=MOBILE_VIEWPORT)
    try:
        _load(driver, f"{base_url}?page=range-area-charts")
        # Entrance motion is part of the phone showcase. Wait for the settled
        # frame so labels and geometry are complete in static package media.
        time.sleep(2)
        image = Image.open(io.BytesIO(driver.get_screenshot_as_png())).convert("RGB")
        output_dir.mkdir(parents=True, exist_ok=True)
        image.save(
            output_dir / "mobile_showcase.png",
            format="PNG",
            optimize=True,
        )
    finally:
        driver.quit()


def _load(driver: webdriver.Chrome, url: str) -> None:
    driver.get(url)
    deadline = time.monotonic() + 20
    while time.monotonic() < deadline:
        if driver.title == "Braven Charts Showcase":
            break
        time.sleep(0.2)
    time.sleep(5)


def _mouse(
    driver: webdriver.Chrome,
    event_type: str,
    x: float,
    y: float,
    **extra: object,
) -> None:
    payload: dict[str, object] = {
        "type": event_type,
        "x": x,
        "y": y,
        "modifiers": 0,
    }
    payload.update(extra)
    driver.execute_cdp_cmd("Input.dispatchMouseEvent", payload)


def _shift(driver: webdriver.Chrome, pressed: bool) -> None:
    driver.execute_cdp_cmd(
        "Input.dispatchKeyEvent",
        {
            "type": "keyDown" if pressed else "keyUp",
            "key": "Shift",
            "code": "ShiftLeft",
            "windowsVirtualKeyCode": 16,
            "nativeVirtualKeyCode": 16,
            "modifiers": 8 if pressed else 0,
        },
    )


def _draw_cursor(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    points = [(x, y), (x + 4, y + 22), (x + 10, y + 15), (x + 16, y + 27),
              (x + 21, y + 24), (x + 15, y + 13), (x + 24, y + 12)]
    draw.polygon(points, fill="#FFFFFF", outline=INK, width=2)


def _decorate(
    image: Image.Image,
    caption: str,
    cursor: tuple[int, int] | None,
    crop: tuple[int, int, int, int],
    caption_right: bool = False,
) -> Image.Image:
    image = image.crop(crop).convert("RGB")
    draw = ImageDraw.Draw(image)
    box = draw.textbbox((0, 0), caption, font=CAPTION_FONT)
    width = box[2] - box[0] + 32
    height = box[3] - box[1] + 22
    left = image.width - width - 18 if caption_right else 18
    top = 16
    draw.rounded_rectangle(
        (left, top, left + width, top + height),
        radius=height // 2,
        fill=SURFACE,
        outline=BRAND,
        width=2,
    )
    draw.text(
        (left + 16, top + 9),
        caption,
        font=CAPTION_FONT,
        fill=INK,
        stroke_width=0,
    )
    if cursor is not None:
        crop_x, crop_y = crop[:2]
        _draw_cursor(draw, cursor[0] - crop_x, cursor[1] - crop_y)
    return image


def _frame(
    driver: webdriver.Chrome,
    caption: str,
    cursor: tuple[int, int] | None,
    crop: tuple[int, int, int, int],
    caption_right: bool = False,
) -> Image.Image:
    screenshot = Image.open(io.BytesIO(driver.get_screenshot_as_png()))
    return _decorate(screenshot, caption, cursor, crop, caption_right)


def _raw_frame(
    driver: webdriver.Chrome,
    cursor: tuple[int, int] | None,
    crop: tuple[int, int, int, int],
) -> Image.Image:
    """Capture a chart-focused frame without promotional caption overlays."""
    image = Image.open(io.BytesIO(driver.get_screenshot_as_png()))
    image = image.crop(crop).convert("RGB")
    if cursor is not None:
        draw = ImageDraw.Draw(image)
        crop_x, crop_y = crop[:2]
        _draw_cursor(draw, cursor[0] - crop_x, cursor[1] - crop_y)
    return image


def _hold(
    driver: webdriver.Chrome,
    frames: list[Image.Image],
    caption: str,
    cursor: tuple[int, int] | None,
    count: int,
    crop: tuple[int, int, int, int],
    caption_right: bool = False,
) -> None:
    for _ in range(count):
        frames.append(_frame(driver, caption, cursor, crop, caption_right))
        time.sleep(FRAME_DURATION_MS / 1000)


def _raw_hold(
    driver: webdriver.Chrome,
    frames: list[Image.Image],
    cursor: tuple[int, int] | None,
    count: int,
    crop: tuple[int, int, int, int],
) -> None:
    for _ in range(count):
        frames.append(_raw_frame(driver, cursor, crop))
        time.sleep(FRAME_DURATION_MS / 1000)


def _save(
    frames: Iterable[Image.Image],
    output: Path,
    output_size: tuple[int, int],
) -> None:
    materialized = [
        frame.resize(output_size, Image.Resampling.LANCZOS).quantize(
            colors=64,
            method=Image.Quantize.MEDIANCUT,
            dither=Image.Dither.FLOYDSTEINBERG,
        )
        for frame in frames
    ]
    output.parent.mkdir(parents=True, exist_ok=True)
    materialized[0].save(
        output,
        format="GIF",
        save_all=True,
        append_images=materialized[1:],
        duration=FRAME_DURATION_MS,
        loop=0,
        optimize=True,
        disposal=2,
    )
    size_mb = output.stat().st_size / (1024 * 1024)
    print(f"Wrote {output} ({len(materialized)} frames, {size_mb:.2f} MB)")


def _save_png(
    driver: webdriver.Chrome,
    output: Path,
    crop: tuple[int, int, int, int] | None = None,
    max_left_dark_fraction: float | None = None,
) -> None:
    image: Image.Image | None = None
    for attempt in range(5):
        candidate = Image.open(
            io.BytesIO(driver.get_screenshot_as_png())
        ).convert("RGB")
        if crop is not None:
            candidate = candidate.crop(crop)
        if max_left_dark_fraction is None:
            image = candidate
            break

        left_half = candidate.crop((0, 0, candidate.width // 2, candidate.height))
        pixels = left_half.getdata()
        dark_pixels = sum(1 for red, green, blue in pixels if max(red, green, blue) < 48)
        dark_fraction = dark_pixels / (left_half.width * left_half.height)
        if dark_fraction <= max_left_dark_fraction:
            image = candidate
            break

        print(
            f"Retrying {output.name}: incomplete canvas capture "
            f"({dark_fraction:.1%} dark pixels on attempt {attempt + 1})"
        )
        driver.execute_script("window.scrollBy(0, 1); window.scrollBy(0, -1);")
        time.sleep(2)

    if image is None:
        raise RuntimeError(f"Could not capture a complete canvas for {output}")
    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output, format="PNG", optimize=True)
    print(f"Wrote {output} ({image.width}x{image.height})")


def _save_composited_png(
    driver: webdriver.Chrome,
    output: Path,
    crop: tuple[int, int, int, int],
) -> None:
    """Combine stable frames to recover intermittently omitted canvas tiles."""
    frames: list[Image.Image] = []
    route = driver.current_url
    for attempt in range(3):
        if attempt > 0:
            _load(driver, route)
        frame = Image.open(io.BytesIO(driver.get_screenshot_as_png())).convert(
            "RGB"
        )
        frames.append(frame.crop(crop))

    image = frames[0]
    for frame in frames[1:]:
        image = ImageChops.darker(image, frame)
    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output, format="PNG", optimize=True)
    print(f"Wrote {output} ({image.width}x{image.height}, 3-load composite)")


def _save_gallery_mosaic(output_dir: Path) -> None:
    columns = 3
    rows = 5
    card_size = (551, 443)
    gap = 16
    mosaic = Image.new(
        "RGB",
        (
            columns * card_size[0] + (columns + 1) * gap,
            rows * card_size[1] + (rows + 1) * gap,
        ),
        SURFACE,
    )
    for index, filename in enumerate(GALLERY_MOSAIC_ASSETS):
        card = Image.open(output_dir / filename).convert("RGB")
        card = ImageOps.contain(card, card_size, Image.Resampling.LANCZOS)
        column = index % columns
        row = index // columns
        left = gap + column * (card_size[0] + gap)
        top = gap + row * (card_size[1] + gap)
        left += (card_size[0] - card.width) // 2
        top += (card_size[1] - card.height) // 2
        mosaic.paste(card, (left, top))
    output = output_dir / "gallery_mosaic.png"
    mosaic.save(output, format="PNG", optimize=True)
    print(f"Wrote {output} ({mosaic.width}x{mosaic.height})")


def _scroll(driver: webdriver.Chrome, delta_y: int) -> None:
    _mouse(
        driver,
        "mouseWheel",
        1300,
        450,
        deltaX=0,
        deltaY=delta_y,
        buttons=0,
        pointerType="mouse",
    )
    time.sleep(0.7)


def _hero_still(
    driver: webdriver.Chrome,
    base_url: str,
    output_dir: Path,
) -> None:
    """Capture the flagship chart with an active tracking tooltip."""
    _load(driver, base_url)
    _scroll(driver, 420)
    _mouse(driver, "mouseMoved", 590, 360)
    time.sleep(0.8)
    _save_png(
        driver,
        output_dir / "hero_chart.png",
        HERO_CROP,
        max_left_dark_fraction=0.12,
    )


def _hero_panel_stills(
    driver: webdriver.Chrome,
    base_url: str,
    output_dir: Path,
) -> None:
    """Capture the two package hero panels at README-friendly ratios."""
    for query, filename in (
        ("hero-threshold", "hero_threshold.png"),
        ("hero-duration", "hero_power_duration.png"),
    ):
        _load(driver, f"{base_url}?capture={query}")
        _save_png(driver, output_dir / filename, HERO_PANEL_CROP)


def _path_workbench_stills(
    base_url: str,
    output_dir: Path,
) -> None:
    """Capture the release Line and Area motion workbench routes."""
    for page, filename, disable_gpu in (
        ("line-charts", "line_motion_workbench.png", False),
        ("area-charts", "area_motion_workbench.png", False),
    ):
        driver = _driver(disable_gpu=disable_gpu)
        try:
            # Discard one warm-up route so CanvasKit has materialized every
            # compositor tile before the release image is recorded.
            _load(driver, f"{base_url}?page=chart-types")
            route = f"{base_url}?page={page}&preset=motion&view=split"
            _load(driver, route)
            _save_composited_png(
                driver,
                output_dir / filename,
                PATH_WORKBENCH_CROP,
            )
        finally:
            driver.quit()


def _gallery_stills_intro(
    driver: webdriver.Chrome,
    base_url: str,
    output_dir: Path,
) -> None:
    """Capture the first advanced-composition row."""

    # Advanced row 1: baseline response and VO2 stage analysis.
    _load(driver, base_url)
    _scroll(driver, 780)
    _save_png(
        driver,
        output_dir / "gallery_baseline.png",
        (281, 323, 832, 766),
    )
    _save_png(
        driver,
        output_dir / "gallery_vo2_stage.png",
        (865, 323, 1416, 766),
    )


def _gallery_stills_remainder(
    driver: webdriver.Chrome,
    base_url: str,
    output_dir: Path,
) -> None:
    """Capture the remaining Gallery cards after the first advanced row."""
    # Advanced row 2: dark glow treatment and lactate small multiples.
    _scroll(driver, 780)
    _save_png(driver, output_dir / "gallery_glow.png", LEFT_CARD)
    _save_png(driver, output_dir / "gallery_lactate.png", RIGHT_CARD)

    # Advanced row 3: live sensor viewport and normalized crosshair tracking.
    _scroll(driver, 475)
    _save_png(driver, output_dir / "gallery_live_sensor.png", LEFT_CARD)
    _save_png(driver, output_dir / "gallery_multi_sensor.png", RIGHT_CARD)

    # Advanced row 4: annotations and a dense analytics dashboard.
    _scroll(driver, 305)
    _save_png(
        driver,
        output_dir / "gallery_annotated.png",
        (281, 191, 832, 634),
    )
    _save_png(
        driver,
        output_dir / "gallery_dashboard.png",
        (865, 191, 1416, 634),
    )

    # Building-block rows: distinct series types and styling treatments.
    _scroll(driver, 780)
    _save_png(
        driver,
        output_dir / "gallery_monthly_revenue.png",
        (281, 29, 832, 433),
    )
    _save_png(
        driver,
        output_dir / "gallery_temperature.png",
        (865, 29, 1416, 433),
    )
    _save_png(
        driver,
        output_dir / "gallery_quarterly_pipeline.png",
        (281, 465, 832, 869),
    )
    _save_png(
        driver,
        output_dir / "gallery_experiment_cohorts.png",
        (865, 465, 1416, 869),
    )

    _scroll(driver, 780)
    _save_png(
        driver,
        output_dir / "gallery_revenue_forecast.png",
        (281, 121, 832, 525),
    )
    _save_png(
        driver,
        output_dir / "gallery_interpolation.png",
        (865, 121, 1416, 525),
    )

    # Reload before the final row so browser wheel coalescing cannot leave a
    # sliver of the preceding row in the crop.
    _load(driver, base_url)
    _scroll(driver, 4200)
    _save_png(
        driver,
        output_dir / "gallery_system_load.png",
        (281, 459, 832, 863),
    )
    _save_png(
        driver,
        output_dir / "gallery_profit_loss.png",
        (865, 459, 1416, 863),
    )
    _save_gallery_mosaic(output_dir)


def _gallery_stills(
    driver: webdriver.Chrome,
    base_url: str,
    output_dir: Path,
) -> None:
    """Capture a chart-only hero and the Gallery's real compositions."""
    _hero_still(driver, base_url, output_dir)
    _gallery_stills_intro(driver, base_url, output_dir)
    _gallery_stills_remainder(driver, base_url, output_dir)


def _native_stills(output_dir: Path, group: str | None = None) -> None:
    """Capture static PNGs through BravenChartController.capturePreview()."""
    repository = Path(__file__).resolve().parent.parent
    output = output_dir.resolve()
    flutter = shutil.which("flutter")
    if flutter is None:
        raise RuntimeError("Flutter is required to capture native chart media.")
    command = [
        flutter,
        "test",
        "--no-pub",
        f"--dart-define=PUBDEV_MEDIA_OUTPUT_DIR={output}",
        "tool/capture_pubdev_static_media_test.dart",
    ]
    if group == "pie":
        command.extend(["--plain-name", "capture pub.dev Pie media"])
    elif group == "donut":
        command.extend(["--plain-name", "capture pub.dev Donut media"])
    elif group == "concentric":
        command.extend(
            ["--plain-name", "capture pub.dev Concentric Donut media"]
        )
    elif group == "polar":
        command.extend(["--plain-name", "capture pub.dev Polar Column media"])
    elif group == "bar":
        command.extend(["--plain-name", "capture pub.dev Bar media"])
    elif group == "scatter":
        command.extend(["--plain-name", "capture pub.dev Scatter media"])
    elif group == "range-area":
        command.extend(["--plain-name", "capture pub.dev Range Area media"])
    elif group == "synchronized":
        command.extend(
            ["--plain-name", "capture pub.dev synchronized Cartesian composition"]
        )
    elif group == "hero":
        command.extend(["--plain-name", "capture pub.dev flagship hero media"])
    elif group == "interaction":
        command.extend(["--plain-name", "capture pub.dev interaction media"])
    elif group == "type-strip":
        command.extend(["--plain-name", "capture pub.dev chart type strip"])
    elif group == "cartesian-0.10":
        command.extend(["--plain-name", "capture pub.dev 0.10.0 Cartesian media"])
    elif group == "grammar-0.12":
        command.extend(["--plain-name", "capture pub.dev 0.12.0 Chart Grammar media"])
    subprocess.run(
        command,
        cwd=repository,
        check=True,
    )


def _donut_gallery_still(
    driver: webdriver.Chrome,
    base_url: str,
    output_dir: Path,
) -> None:
    """Capture three reusable Donut compositions without app chrome."""
    _load(driver, f"{base_url}?capture=donut-gallery")
    time.sleep(6)
    driver.execute_script("window.scrollBy(0, 1); window.scrollBy(0, -1);")
    time.sleep(1)
    _save_png(
        driver,
        output_dir / "gallery_donut_collection.png",
        (16, 16, VIEWPORT[0] - 16, VIEWPORT[1] - 16),
        max_left_dark_fraction=0.45,
    )


def _legacy_interaction(
    driver: webdriver.Chrome,
    base_url: str,
    output: Path,
) -> None:
    _load(driver, base_url)
    _mouse(
        driver,
        "mouseWheel",
        1300,
        350,
        deltaX=0,
        deltaY=420,
        buttons=0,
        pointerType="mouse",
    )
    time.sleep(1)
    frames: list[Image.Image] = []
    start = (470, 290)
    _mouse(driver, "mouseMoved", *start)
    _hold(
        driver,
        frames,
        "4 axes · tracking · annotations",
        start,
        5,
        INTERACTION_CROP,
        True,
    )

    for step in range(20):
        point = (470 + step * 38, 290 - int(55 * (step % 6) / 6))
        _mouse(driver, "mouseMoved", *point)
        frames.append(
            _frame(
                driver,
                "4 axes · tracking · annotations",
                point,
                INTERACTION_CROP,
                True,
            )
        )
        time.sleep(FRAME_DURATION_MS / 1000)

    center = (850, 310)
    _shift(driver, True)
    for _ in range(3):
        _mouse(
            driver,
            "mouseWheel",
            *center,
            deltaX=0,
            deltaY=-250,
            buttons=0,
            pointerType="mouse",
            modifiers=8,
        )
        time.sleep(0.24)
        frames.append(
            _frame(
                driver,
                "Shift + wheel to zoom",
                center,
                INTERACTION_CROP,
                True,
            )
        )
    _shift(driver, False)
    time.sleep(0.5)
    _hold(
        driver,
        frames,
        "Shift + wheel to zoom",
        center,
        6,
        INTERACTION_CROP,
        True,
    )

    drag_start = (980, 330)
    _mouse(driver, "mouseMoved", *drag_start)
    _mouse(
        driver,
        "mousePressed",
        *drag_start,
        button="left",
        buttons=1,
        clickCount=1,
    )
    for step in range(1, 13):
        point = (980 - step * 15, 330)
        _mouse(driver, "mouseMoved", *point, button="left", buttons=1)
        time.sleep(FRAME_DURATION_MS / 1000)
        frames.append(
            _frame(
                driver,
                "Drag to pan · scrollbar follows",
                point,
                INTERACTION_CROP,
                True,
            )
        )
    drag_end = (800, 330)
    _mouse(
        driver,
        "mouseReleased",
        *drag_end,
        button="left",
        buttons=0,
        clickCount=1,
    )
    _hold(
        driver,
        frames,
        "Drag to pan · scrollbar follows",
        drag_end,
        6,
        INTERACTION_CROP,
        True,
    )

    # Return close to the starting viewport so the loop does not visibly jump.
    _mouse(driver, "mouseMoved", *drag_end)
    _mouse(
        driver,
        "mousePressed",
        *drag_end,
        button="left",
        buttons=1,
        clickCount=1,
    )
    for step in range(1, 9):
        point = (800 + step * 22.5, 330)
        _mouse(driver, "mouseMoved", *point, button="left", buttons=1)
        frames.append(
            _frame(
                driver,
                "Drag to pan · scrollbar follows",
                point,
                INTERACTION_CROP,
                True,
            )
        )
    _mouse(
        driver,
        "mouseReleased",
        980,
        330,
        button="left",
        buttons=0,
        clickCount=1,
    )
    _shift(driver, True)
    for _ in range(3):
        _mouse(
            driver,
            "mouseWheel",
            *center,
            deltaX=0,
            deltaY=190,
            buttons=0,
            pointerType="mouse",
            modifiers=8,
        )
        time.sleep(0.24)
        frames.append(
            _frame(
                driver,
                "One chart, full analytical control",
                center,
                INTERACTION_CROP,
                True,
            )
        )
    _shift(driver, False)
    time.sleep(0.5)
    _hold(
        driver,
        frames,
        "One chart, full analytical control",
        center,
        6,
        INTERACTION_CROP,
        True,
    )
    _save(frames, output, INTERACTION_SIZE)


def _tracking_demo(
    driver: webdriver.Chrome,
    base_url: str,
    output: Path,
) -> None:
    """Record one concise pass across a real multi-axis Gallery chart."""
    _load(driver, f"{base_url}?capture=interaction-session")
    frames: list[Image.Image] = []
    start = (310, 430)
    _mouse(driver, "mouseMoved", *start)
    _raw_hold(driver, frames, start, 5, FOCUSED_MEDIA_CROP)

    for step in range(22):
        progress = step / 21
        point = (
            round(310 + progress * 800),
            round(430 - 70 * math.sin(progress * math.pi)),
        )
        _mouse(driver, "mouseMoved", *point)
        frames.append(_raw_frame(driver, point, FOCUSED_MEDIA_CROP))
        time.sleep(FRAME_DURATION_MS / 1000)

    _raw_hold(driver, frames, (1110, 430), 8, FOCUSED_MEDIA_CROP)
    _save(frames, output, FOCUSED_MEDIA_SIZE)


def _zoom_pan_demo(
    driver: webdriver.Chrome,
    base_url: str,
    output: Path,
) -> None:
    """Record focused wheel zoom and drag-to-pan behavior."""
    _load(driver, f"{base_url}?capture=interaction-duration")
    frames: list[Image.Image] = []
    center = (760, 440)
    _mouse(driver, "mouseMoved", *center)
    _raw_hold(driver, frames, center, 5, FOCUSED_MEDIA_CROP)

    _shift(driver, True)
    for _ in range(2):
        _mouse(
            driver,
            "mouseWheel",
            *center,
            deltaX=0,
            deltaY=-220,
            buttons=0,
            pointerType="mouse",
            modifiers=8,
        )
        time.sleep(0.22)
        frames.append(_raw_frame(driver, center, FOCUSED_MEDIA_CROP))
    _shift(driver, False)
    _raw_hold(driver, frames, center, 5, FOCUSED_MEDIA_CROP)

    drag_start = (980, 470)
    _mouse(driver, "mouseMoved", *drag_start)
    _mouse(
        driver,
        "mousePressed",
        *drag_start,
        button="left",
        buttons=1,
        clickCount=1,
    )
    for step in range(1, 13):
        point = (980 - step * 13, 470)
        _mouse(driver, "mouseMoved", *point, button="left", buttons=1)
        frames.append(_raw_frame(driver, point, FOCUSED_MEDIA_CROP))
        time.sleep(FRAME_DURATION_MS / 1000)
    drag_end = (824, 470)
    _mouse(
        driver,
        "mouseReleased",
        *drag_end,
        button="left",
        buttons=0,
        clickCount=1,
    )
    _raw_hold(driver, frames, drag_end, 8, FOCUSED_MEDIA_CROP)
    _save(frames, output, FOCUSED_MEDIA_SIZE)


def _donut_selection_demo(
    driver: webdriver.Chrome,
    base_url: str,
    output: Path,
) -> None:
    """Record durable Donut selection and center-content changes."""
    _load(driver, f"{base_url}?capture=donut-revenue")
    frames: list[Image.Image] = []
    first = (950, 440)
    _mouse(driver, "mouseMoved", *first)
    _raw_hold(driver, frames, first, 5, FOCUSED_MEDIA_CROP)

    for point in ((950, 440), (610, 650), (460, 390)):
        _mouse(driver, "mouseMoved", *point)
        _mouse(
            driver,
            "mousePressed",
            *point,
            button="left",
            buttons=1,
            clickCount=1,
        )
        _mouse(
            driver,
            "mouseReleased",
            *point,
            button="left",
            buttons=0,
            clickCount=1,
        )
        resting = (720, 175)
        _mouse(driver, "mouseMoved", *resting)
        _raw_hold(driver, frames, resting, 8, FOCUSED_MEDIA_CROP)

    _save(frames, output, FOCUSED_MEDIA_SIZE)


def _live_stream(driver: webdriver.Chrome, base_url: str, output: Path) -> None:
    _load(driver, f"{base_url}?page=live-stream")
    frames: list[Image.Image] = []
    cursor = (760, 650)
    _mouse(driver, "mouseMoved", *cursor)
    _raw_hold(driver, frames, cursor, 22, LIVE_CROP)

    pause = (1275, 286)
    _mouse(driver, "mouseMoved", *pause)
    _mouse(
        driver,
        "mousePressed",
        *pause,
        button="left",
        buttons=1,
        clickCount=1,
    )
    _mouse(
        driver,
        "mouseReleased",
        *pause,
        button="left",
        buttons=0,
        clickCount=1,
    )
    _raw_hold(driver, frames, None, 22, LIVE_CROP)

    _mouse(driver, "mouseMoved", *pause)
    _mouse(
        driver,
        "mousePressed",
        *pause,
        button="left",
        buttons=1,
        clickCount=1,
    )
    _mouse(
        driver,
        "mouseReleased",
        *pause,
        button="left",
        buttons=0,
        clickCount=1,
    )
    _raw_hold(driver, frames, None, 28, LIVE_CROP)
    _save(frames, output, LIVE_SIZE)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--url",
        default="https://braven-pvm.github.io/braven_charts/",
        help="Showcase base URL, without query parameters.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("doc/screenshots"),
    )
    parser.add_argument(
        "--capture",
        choices=(
            "all",
            "interaction",
            "tracking",
            "zoom-pan",
            "selection",
            "live-stream",
            "stills",
            "hero",
            "pie",
            "bar",
            "scatter",
            "range-area",
            "synchronized",
            "interaction-still",
            "type-strip",
            "donut",
            "concentric",
            "polar",
            "line-area",
            "cartesian-0.10",
            "grammar-0.12",
            "mobile-0.13",
        ),
        default="all",
        help="Capture all media, a focused animation, or the static set.",
    )
    args = parser.parse_args()
    base_url = args.url.rstrip("/") + "/"

    if args.capture == "pie":
        _native_stills(args.output_dir, "pie")
        return
    if args.capture == "bar":
        _native_stills(args.output_dir, "bar")
        return
    if args.capture == "scatter":
        _native_stills(args.output_dir, "scatter")
        return
    if args.capture == "range-area":
        _native_stills(args.output_dir, "range-area")
        return
    if args.capture == "synchronized":
        _native_stills(args.output_dir, "synchronized")
        return
    if args.capture == "interaction-still":
        _native_stills(args.output_dir, "interaction")
        return
    if args.capture == "type-strip":
        _native_stills(args.output_dir, "type-strip")
        return
    if args.capture == "donut":
        _native_stills(args.output_dir, "donut")
        return
    if args.capture == "concentric":
        _native_stills(args.output_dir, "concentric")
        return
    if args.capture == "polar":
        _native_stills(args.output_dir, "polar")
        return
    if args.capture == "hero":
        _native_stills(args.output_dir, "hero")
        return
    if args.capture == "line-area":
        _path_workbench_stills(base_url, args.output_dir)
        return
    if args.capture == "cartesian-0.10":
        _native_stills(args.output_dir, "cartesian-0.10")
        return
    if args.capture == "grammar-0.12":
        _native_stills(args.output_dir, "grammar-0.12")
        return
    if args.capture == "mobile-0.13":
        _mobile_showcase_still(base_url, args.output_dir)
        return

    driver = _driver()
    try:
        if args.capture in ("all", "interaction", "tracking"):
            _tracking_demo(
                driver,
                base_url,
                args.output_dir / "tracking_demo.gif",
            )
        if args.capture in ("all", "interaction", "zoom-pan"):
            _zoom_pan_demo(
                driver,
                base_url,
                args.output_dir / "zoom_pan_demo.gif",
            )
        if args.capture in ("all", "selection"):
            _donut_selection_demo(
                driver,
                base_url,
                args.output_dir / "donut_selection_demo.gif",
            )
        if args.capture in ("all", "live-stream"):
            _live_stream(
                driver,
                base_url,
                args.output_dir / "live_stream_demo.gif",
            )
        if args.capture in ("all", "stills"):
            _gallery_stills(driver, base_url, args.output_dir)
    finally:
        driver.quit()

    if args.capture in ("all", "stills"):
        _native_stills(args.output_dir)
    if args.capture == "all":
        _path_workbench_stills(base_url, args.output_dir)


if __name__ == "__main__":
    main()
