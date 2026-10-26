"""Exercise public evidence commands only in disposable repository copies."""

import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


class EvidenceIntegrityTests(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory(prefix="hunter-integrity-")
        self.addCleanup(self.scratch.cleanup)
        self.root = Path(self.scratch.name) / "repo"
        scripts = Path(__file__).resolve().parents[1] / "scripts"
        shutil.copytree(scripts, self.root / "tools" / "scripts")
        self.vault = self.root / "programs/example.test/vulns/poc/finding-1"

    def command(self, script, *args):
        return subprocess.run(
            [sys.executable, str(self.root / "tools/scripts" / script), *args],
            cwd=self.root, capture_output=True, text=True, timeout=10,
            env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"},
        )

    def initialize(self):
        result = self.command(
            "evidence-vault.py", "init", "example.test", "finding-1",
            "--title", "Controlled IDOR", "--severity", "High",
            "--type", "IDOR", "--endpoint", "/invoices/1",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return result

    def add_evidence(self):
        source = Path(self.scratch.name) / "request.http"
        source.write_text("GET /invoices/1 HTTP/1.1\nHost: example.test\n")
        result = self.command(
            "evidence-vault.py", "add", "example.test", "finding-1",
            "--file", str(source), "--kind", "request",
        )
        self.assertEqual(result.returncode, 0, result.stderr)

    def snapshot(self):
        return {
            str(p.relative_to(self.root)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in self.root.rglob("*") if p.is_file()
        }

    def test_existing_vault_initialization_is_rejected_without_mutation(self):
        self.initialize()
        self.add_evidence()
        before = self.snapshot()
        result = self.command(
            "evidence-vault.py", "init", "example.test", "finding-1",
            "--title", "Replacement", "--severity", "Low",
            "--type", "Other", "--endpoint", "/other",
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("already exists", json.loads(result.stderr)["error"])
        self.assertEqual(result.stdout, "")
        self.assertEqual(self.snapshot(), before)

    def test_init_add_list_and_report_keep_existing_success_contract(self):
        self.initialize()
        self.add_evidence()
        listed = self.command("evidence-vault.py", "list", "example.test", "finding-1")
        self.assertEqual(listed.returncode, 0, listed.stderr)
        metadata = json.loads(listed.stdout)["metadata"]
        self.assertEqual(metadata["title"], "Controlled IDOR")
        self.assertEqual(len(metadata["evidence"]), 1)
        result = self.command("build-report.py", "example.test", "finding-1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        output = json.loads(result.stdout)
        self.assertEqual(output, {"ok": True, "report": "reports/example.test-finding-1.md"})
        self.assertIn("Controlled IDOR", (self.root / output["report"]).read_text())

    def test_dangling_report_symlink_is_rejected_without_external_write(self):
        self.initialize()
        reports = self.root / "reports"
        reports.mkdir()
        outside = Path(self.scratch.name) / "must-not-be-created.md"
        link = reports / "example.test-finding-1.md"
        link.symlink_to(outside)
        before = self.snapshot()
        result = self.command("build-report.py", "example.test", "finding-1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("escapes reports directory", json.loads(result.stderr)["error"])
        self.assertEqual(result.stdout, "")
        self.assertFalse(outside.exists())
        self.assertTrue(link.is_symlink())
        self.assertEqual(self.snapshot(), before)

    def test_existing_report_symlink_is_rejected_without_external_mutation(self):
        self.initialize()
        reports = self.root / "reports"
        reports.mkdir()
        outside = Path(self.scratch.name) / "sentinel.md"
        outside.write_text("preserve")
        (reports / "example.test-finding-1.md").symlink_to(outside)
        result = self.command("build-report.py", "example.test", "finding-1")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(outside.read_text(), "preserve")

    def test_occupied_vault_preserves_empty_orphan_and_file_destinations(self):
        for kind in ("empty", "orphan", "file"):
            with self.subTest(kind=kind):
                finding = "occupied-" + kind
                vault = self.vault.parent / finding
                vault.parent.mkdir(parents=True, exist_ok=True)
                if kind == "file":
                    vault.write_text("sentinel")
                else:
                    vault.mkdir()
                    if kind == "orphan":
                        (vault / "request.http").write_text("preserve evidence")
                before = self.snapshot()
                result = self.command(
                    "evidence-vault.py", "init", "example.test", finding,
                    "--title", "Proof", "--severity", "High",
                    "--type", "IDOR", "--endpoint", "/1",
                )
                self.assertEqual(result.returncode, 1)
                self.assertEqual(result.stdout, "")
                self.assertIn("already exists", json.loads(result.stderr)["error"])
                self.assertEqual(self.snapshot(), before)

    def test_report_overwrite_preserves_output_and_content(self):
        self.initialize()
        self.add_evidence()
        first = self.command("build-report.py", "example.test", "finding-1")
        self.assertEqual(first.returncode, 0, first.stderr)
        report = self.root / json.loads(first.stdout)["report"]
        expected = report.read_bytes()
        report.write_text("old report")
        second = self.command("build-report.py", "example.test", "finding-1")
        self.assertEqual(
            (second.returncode, second.stdout, second.stderr),
            (first.returncode, first.stdout, first.stderr),
        )
        self.assertEqual(report.read_bytes(), expected)

    def test_dangling_internal_report_link_keeps_previous_behavior(self):
        self.initialize()
        reports = self.root / "reports"
        reports.mkdir()
        destination = reports / "destination.md"
        link = reports / "example.test-finding-1.md"
        link.symlink_to(destination)
        result = self.command("build-report.py", "example.test", "finding-1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertTrue(link.is_symlink())
        self.assertIn("Controlled IDOR", destination.read_text())


if __name__ == "__main__":
    unittest.main()
