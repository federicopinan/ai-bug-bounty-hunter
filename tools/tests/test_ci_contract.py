"""Guard the workflow failures observed in the baseline GitHub Actions run."""

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]


class WorkflowContractTests(unittest.TestCase):
    def test_compose_has_final_newline(self):
        self.assertTrue((ROOT / "docker-compose.yml").read_bytes().endswith(b"\n"))

    def test_workflows_do_not_reference_known_node20_action_versions(self):
        obsolete = re.compile(
            r"uses:\s*(?:actions/checkout@v4|actions/setup-python@v5|"
            r"DavidAnson/markdownlint-cli2-action@v19)\b"
        )
        for workflow in sorted((ROOT / ".github/workflows").glob("*.yml")):
            with self.subTest(workflow=workflow.name):
                self.assertIsNone(obsolete.search(workflow.read_text()))

    def test_link_source_exclusions_use_path_option(self):
        workflow = (ROOT / ".github/workflows/lint.yml").read_text()
        for source in (
            r"^\.agents/", r"^payloads/", r"^programs/\{target\}/",
            r"^\.claude/skills/bug-bounty-init/assets/notes-template\.md$",
        ):
            with self.subTest(source=source):
                # These are input files, not URLs; --exclude cannot omit them.
                self.assertNotIn(f"--exclude '{source}'", workflow)
        self.assertIn("--exclude-path .agents", workflow)
        self.assertIn("--exclude-path payloads", workflow)
        self.assertIn("--offline", workflow)
        self.assertNotIn("continue-on-error", workflow)


if __name__ == "__main__":
    unittest.main()
