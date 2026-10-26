"""Exercise the workflow's actual diagnostic shell body without GitHub access."""

import hashlib
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]


class LinkReportTests(unittest.TestCase):
    def test_report_output_preserves_file(self):
        workflow = (ROOT / ".github/workflows/lint.yml").read_text()
        section = workflow.split("      - name: Show link report\n", 1)[1]
        self.assertIn("        if: always()\n", section)
        body = section.split("        run: |\n", 1)[1]
        script = "\n".join(line[10:] for line in body.splitlines()) + "\n"
        for contents in (None, b"", b"broken local link\n"):
            with self.subTest(contents=contents), tempfile.TemporaryDirectory() as tmp:
                report = Path(tmp) / "lychee/out.md"
                if contents is not None:
                    report.parent.mkdir()
                    report.write_bytes(contents)
                before = hashlib.sha256(report.read_bytes()).digest() if report.exists() else None
                result = subprocess.run(
                    ["bash", "-e", "-c", script], cwd=tmp,
                    capture_output=True, timeout=10,
                )
                expected = contents if contents is not None else (
                    b"No link report produced; inspect the Run lychee step output.\n"
                )
                self.assertEqual((result.returncode, result.stdout, result.stderr), (0, expected, b""))
                after = hashlib.sha256(report.read_bytes()).digest() if report.exists() else None
                self.assertEqual(before, after)
