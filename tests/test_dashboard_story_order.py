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
                "03 / California comparison",
                "04 / Regression benchmark",
                "05 / Gas-price association",
                "06 / County response",
                "07 / Stated preferences",
            ],
        )


if __name__ == "__main__":
    unittest.main()
