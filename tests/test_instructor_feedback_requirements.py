import unittest
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
APP_PATH = PROJECT_ROOT / "app.R"
REPORT_PATH = PROJECT_ROOT / "report" / "final_report.Rmd"


class InstructorFeedbackRequirementsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.app_source = APP_PATH.read_text(encoding="utf-8")
        cls.report_source = REPORT_PATH.read_text(encoding="utf-8")

    def test_app_presents_data_sources_units_and_sample_sizes(self):
        expected_copy = [
            "Data and sample",
            "Analysis unit",
            "Sample size",
            'tableOutput("data_sample_table")',
            "2,541,732",
            "114 months",
            "18 respondents",
            "123 usable ratings",
        ]

        for copy in expected_copy:
            with self.subTest(copy=copy):
                self.assertIn(copy, self.app_source)

    def test_app_offers_an_analysis_dataset_bundle(self):
        expected_files = [
            "data_dictionary.csv",
            "washington_titles_monthly.csv",
            "washington_county_monthly.csv",
            "washington_gas_monthly.csv",
            "washington_unemployment_monthly.csv",
            "washington_electricity_monthly.csv",
            "washington_policy_monthly.csv",
            "washington_vmt_monthly.csv",
            "quarterly_controls.csv",
            "conjoint_survey.csv",
        ]

        self.assertIn("downloadButton(", self.app_source)
        self.assertIn('"download_data_bundle",', self.app_source)
        self.assertIn(
            "output$download_data_bundle <- downloadHandler(",
            self.app_source,
        )
        for file_name in expected_files:
            with self.subTest(file_name=file_name):
                self.assertIn(file_name, self.app_source)
                self.assertTrue((PROJECT_ROOT / "data" / file_name).is_file())

    def test_app_compares_method_strengths_and_limitations(self):
        expected_copy = [
            "Method strengths and limitations",
            "Multiple regression benchmark",
            "Interrupted time series",
            "Gas-price regression",
            "Rating-based conjoint analysis",
            "Strength",
            "Limitation",
        ]

        for copy in expected_copy:
            with self.subTest(copy=copy):
                self.assertIn(copy, self.app_source)

    def test_report_surfaces_data_and_method_tables(self):
        expected_copy = [
            "### Data sources, units, and sample sizes",
            "| Dataset | Source | Analysis unit | Coverage | Sample size |",
            "2,541,732",
            "18 respondents",
            "123 usable ratings",
            "### Method strengths and limitations",
            "| Method | Role in this project | Strength | Limitation |",
            "Multiple regression benchmark",
            "Rating-based conjoint analysis",
        ]

        for copy in expected_copy:
            with self.subTest(copy=copy):
                self.assertIn(copy, self.report_source)


if __name__ == "__main__":
    unittest.main()
