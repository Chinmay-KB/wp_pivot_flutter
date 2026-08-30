import hashlib
import json
import tempfile
import unittest
import zipfile
from pathlib import Path

import publication


class PublicationTests(unittest.TestCase):
    @property
    def mirror(self):
        return Path(publication.read_json(publication.STUDY / "study.json")["bindings"]["glance_app"])

    def build_fixture(self, root: Path) -> Path:
        snapshot = root / "snapshot"
        publication.build(snapshot, self.mirror)
        return snapshot

    def test_native_source_audit_matches_current_bytes_and_records_old_limit(self):
        audit = publication.audit_native_sources(self.mirror)
        self.assertEqual(19, len(audit["source_files"]))
        # Three settled alphabet-selection replacements supplement the retained
        # invalid predecessor trials, so the immutable audit count grows.
        self.assertEqual(88, audit["trial_manifests"])
        self.assertEqual(2, len(audit["older_adapter_trials"]))

    def test_media_allowlist_is_exact_and_verified(self):
        self.assertEqual({"items": 22, "canonical": 20, "supplemental": 2}, publication.validate_media())

    def test_portable_study_redacts_all_bindings(self):
        source = publication.read_json(publication.STUDY / "study.json")
        result = publication.portable_study(source)
        rendered = json.dumps(result)
        self.assertNotIn("C:" + "\\" + "Users" + "\\", rendered)
        self.assertEqual(set(source["bindings"]), set(result["bindings"]))
        self.assertTrue(all(value.startswith("<") and value.endswith(">") for value in result["bindings"].values()))

    def test_media_manifests_are_byte_hashed(self):
        index = publication.read_json(publication.MEDIA / "media-index.json")
        for item in index["items"]:
            directory = publication.MEDIA / item["slug"]
            manifest = publication.read_json(directory / "media-manifest.json")
            for name, digest in manifest["files"].items():
                self.assertEqual(digest, hashlib.sha256((directory / name).read_bytes()).hexdigest())

    def test_checksum_is_fresh_and_names_only_selected_archive(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            archive = root / "evidence.zip"
            archive.write_bytes(b"evidence")
            checksum = root / "evidence.zip.sha256"
            result = publication.write_checksum(archive, checksum)
            self.assertEqual("evidence.zip", result["archive"])
            self.assertEqual(result, publication.verify_checksum(archive, checksum))
            with self.assertRaises(publication.PublicationError):
                publication.write_checksum(archive, checksum)

    def test_privacy_screen_rejects_real_host_paths_but_not_escaped_source_literal(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            text = root / "note.md"
            for value in (
                "C:" + "\\" + "Users" + "\\" + "Ada" + "\\" + "evidence",
                "C:/" + "Users" + "/Ada/evidence",
                "/" + "home" + "/ada/evidence",
                "/" + "Users" + "/ada/evidence",
            ):
                text.write_text(value, encoding="utf-8")
                with self.assertRaises(publication.PublicationError):
                    publication.screen_tree(root, public_text=True)
            text.write_text(r"regex example: C:\\Users\\Name", encoding="utf-8")
            publication.screen_tree(root, public_text=True)

    def test_legacy_source_redaction_keeps_manifest_hash_and_removes_host_path(self):
        native = publication.audit_native_sources(self.mirror)
        redaction = publication.source_redactions(native, self.mirror)
        entry = redaction["redactions"][0]
        original = self.mirror / "wpmirror" / publication.LEGACY_SOURCE
        published = publication.redacted_legacy_bytes(original)
        self.assertEqual(native["source_files"][publication.LEGACY_SOURCE], entry["original_sha256"])
        self.assertEqual(hashlib.sha256(published).hexdigest(), entry["published_sha256"])
        self.assertIn(publication.LEGACY_REPLACEMENT.encode(), published)
        self.assertNotRegex(published.decode("utf-8"), publication.HOST_PATH)

    def test_snapshot_verifier_rejects_extra_file_and_modified_authoritative_copy(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            extra = self.build_fixture(root / "extra")
            (extra / "unallowlisted.txt").write_text("not evidence", encoding="utf-8")
            with self.assertRaises(publication.PublicationError):
                publication.verify(extra, self.mirror)
            modified = self.build_fixture(root / "modified")
            target = modified / "research" / "start-screen" / "README.md"
            target.write_text(target.read_text(encoding="utf-8") + "\nchanged", encoding="utf-8")
            with self.assertRaises(publication.PublicationError):
                publication.verify(modified, self.mirror)

    def test_archive_summary_requires_exact_three_labels(self):
        with tempfile.TemporaryDirectory() as temporary:
            archive = Path(temporary) / "bundle.zip"
            inventory = {"members": [
                {"source_label": "capture", "size_bytes": 1},
                {"source_label": "analysis", "size_bytes": 2},
                {"source_label": "publication", "size_bytes": 3},
            ]}
            with zipfile.ZipFile(archive, "w") as output:
                output.writestr("inventory.json", json.dumps(inventory))
            self.assertEqual({"capture": 1, "analysis": 1, "publication": 1}, publication.archive_summary(archive)["bundle_label_counts"])

    def test_release_report_recomputes_snapshot_checksum_and_bundle_values(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            snapshot = self.build_fixture(root / "snapshot")
            archive = root / "evidence.zip"
            inventory = {"members": [
                {"source_label": "capture", "size_bytes": 1},
                {"source_label": "analysis", "size_bytes": 2},
                {"source_label": "publication", "size_bytes": 3},
            ]}
            with zipfile.ZipFile(archive, "w") as output:
                output.writestr("inventory.json", json.dumps(inventory))
            checksum = root / "evidence.zip.sha256"
            publication.write_checksum(archive, checksum)
            report = root / "release.json"
            result = publication.write_release_report(archive, checksum, snapshot, self.mirror, report)
            self.assertEqual(result, publication.verify_release_report(archive, checksum, snapshot, self.mirror, report))
            self.assertEqual(23, result["study_counts"]["scenario_ids"])


if __name__ == "__main__":
    unittest.main()
