import re
import unittest
from pathlib import Path


APP_PATH = Path(__file__).resolve().parents[1] / "app.R"


class DashboardStoryOrderTest(unittest.TestCase):
    def test_numbered_sections_follow_three_act_presentation(self):
        app_source = APP_PATH.read_text(encoding="utf-8")
        numbered_sections = re.findall(
            r'div\(class = "section-kicker", "(\d{2} / [^"]+)"\)',
            app_source,
        )

        self.assertEqual(
            numbered_sections,
            [
                "01 / Monthly market",
                "02 / Behavioral response",
                "03 / County response",
                "04 / California comparison",
                "05 / Regression benchmark",
                "06 / Gas-price association",
                "07 / Stated preferences",
            ],
        )

    def test_explanatory_copy_uses_reordered_section_numbers(self):
        app_source = APP_PATH.read_text(encoding="utf-8")

        expected_references = [
            "Sections 01, 02, 03, and 04 summarize recorded titles, driving,",
            "Section 05 compares observed share with a rolling-validated",
            "Sections 06 and 07 report coefficients with uncertainty.",
            "separately in Section 06. The benchmark does not prove that the",
        ]

        for reference in expected_references:
            with self.subTest(reference=reference):
                self.assertIn(reference, app_source)


if __name__ == "__main__":
    unittest.main()
