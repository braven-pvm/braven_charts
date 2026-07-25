import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from PIL import Image, ImageDraw

import public_surface_visual_check as visual


class PublicSurfaceVisualCheckTest(unittest.TestCase):
    def test_identical_images_have_no_perceptual_difference(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            current = root / "current.png"
            baseline = root / "baseline.png"
            Image.new("RGB", (120, 80), "white").save(current)
            Image.new("RGB", (120, 80), "white").save(baseline)

            result = visual._visual_difference(
                current,
                baseline,
                root / "diff.png",
            )

            self.assertEqual(result["score"], 0)
            self.assertFalse((root / "diff.png").exists())

    def test_structural_change_exceeds_visual_threshold_and_writes_diff(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            current = root / "current.png"
            baseline = root / "baseline.png"
            before = Image.new("RGB", (160, 100), "white")
            after = before.copy()
            draw = ImageDraw.Draw(after)
            for x in range(0, 160, 12):
                draw.rectangle((x, 0, x + 5, 99), fill="black")
            before.save(baseline)
            after.save(current)

            result = visual._visual_difference(
                current,
                baseline,
                root / "diff.png",
            )

            self.assertGreater(result["score"], visual.DEFAULT_VISUAL_DIFF_THRESHOLD)
            self.assertTrue((root / "diff.png").is_file())

    def test_large_colour_change_exceeds_visual_threshold(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            current = root / "current.png"
            baseline = root / "baseline.png"
            Image.new("RGB", (120, 80), "black").save(current)
            Image.new("RGB", (120, 80), "white").save(baseline)

            result = visual._visual_difference(
                current,
                baseline,
                root / "diff.png",
            )

            self.assertEqual(result["edgeScore"], 0)
            self.assertEqual(result["colourScore"], 1)
            self.assertGreater(result["score"], visual.DEFAULT_VISUAL_DIFF_THRESHOLD)

    def test_ci_cannot_rewrite_reviewed_baselines(self) -> None:
        with tempfile.TemporaryDirectory() as directory, patch.dict(
            os.environ,
            {"CI": "true"},
        ):
            with self.assertRaisesRegex(
                RuntimeError,
                "cannot be updated in CI",
            ):
                visual._update_baselines([], Path(directory), Path(directory))

    def test_comparison_removes_stale_diff_artifacts(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            output = root / "output"
            baselines = root / "baselines"
            (output / "diffs").mkdir(parents=True)
            baselines.mkdir()
            (output / "diffs" / "stale.png").write_bytes(b"stale")
            Image.new("RGB", (120, 80), "white").save(output / "surface.png")
            Image.new("RGB", (120, 80), "white").save(
                baselines / "surface.png"
            )

            comparisons, failures = visual._compare_baselines(
                [{"screenshot": "surface.png"}],
                output,
                baselines,
                visual.DEFAULT_VISUAL_DIFF_THRESHOLD,
            )

            self.assertEqual(failures, [])
            self.assertEqual(comparisons[0]["score"], 0)
            self.assertFalse((output / "diffs" / "stale.png").exists())

    def test_readme_contract_counts_come_from_public_catalog(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            preview, _ = visual._render_readme(Path(directory))
            html = preview.read_text(encoding="utf-8")
            catalog = json.loads(
                (
                    visual.REPOSITORY_ROOT / "doc" / "public_catalog.json"
                ).read_text(encoding="utf-8")
            )
            gallery_groups: dict[str, int] = {}
            for entry in catalog["gallery"]:
                gallery_groups[entry["group"]] = (
                    gallery_groups.get(entry["group"], 0) + 1
                )

            self.assertIn(
                f'data-family-count="{len(catalog["chartFamilies"])}"',
                html,
            )
            self.assertIn(
                'data-gallery-columns="'
                + ",".join(str(count) for count in gallery_groups.values())
                + '"',
                html,
            )


if __name__ == "__main__":
    unittest.main()
