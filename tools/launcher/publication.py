"""Build and verify the portable WP8.1 Start-screen evidence snapshot.

Example (all output paths must be new)::

  <STUDY_PYTHON> tools/launcher/publication.py build --output <SNAPSHOT> --wp-mirror <WP_MIRROR_APP>
  <STUDY_PYTHON> tools/launcher/publication.py verify <SNAPSHOT> --wp-mirror <WP_MIRROR_APP>

The final ZIP is deliberately made by the UI-Fidelity explicit-input bundler,
not by this program.  This program only creates the portable ``publication``
input and validates its allowlist, hashes, media, source snapshot and privacy
screening.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import sys
import zipfile
from collections import Counter
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
STUDY = REPO / "artifacts" / "launcher-primitives-01"
CAPTURE = STUDY / "runs" / "capture"
ANALYSIS = STUDY / "runs" / "analysis"
MEDIA = REPO / "docs" / "media" / "start-screen"
CURRENT_ADAPTER = "b8f95994e06a9191feafe47c5afa3458843e2ba3e83f73dc14de09a16e45f94d"
OLDER_PILOT_ADAPTER = "42036c503cc7ad9f4098dd453e5b49bb5a55345f9593aa2fe04b0aa85e643acb"
LEGACY_SOURCE = "framesource/legacy_exe.py"
LEGACY_REPLACEMENT = "<REDACTED_LEGACY_EXE_PATH>"
TEXT_EXTENSIONS = {".json", ".md", ".py", ".ps1", ".csv", ".jsonl", ".txt", ".html", ".yml", ".yaml"}
FORBIDDEN_PARTS = {".git", ".preview-new", "__pycache__"}
FORBIDDEN_SUFFIXES = {".pyc", ".pyo", ".ttf", ".otf", ".ttc", ".woff", ".woff2", ".fon"}
# Match actual host paths, not escaped path examples in Python/regex source.
HOST_PATH = re.compile(
    r"(?i)(?<!\\)(?:[A-Z]:\\Users(?:\\|$)|[A-Z]:/Users(?:/|$)|/(?:home|Users)/[^/\\\r\n]+(?:/|$))"
)


class PublicationError(ValueError):
    """A missing, unsafe, or non-reproducible publication input."""


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def check_safe_relative(relative: Path) -> None:
    if relative.is_absolute() or any(part in {"", ".", ".."} for part in relative.parts):
        raise PublicationError(f"unsafe relative path: {relative}")
    if any(part.casefold() in FORBIDDEN_PARTS for part in relative.parts):
        raise PublicationError(f"forbidden path component: {relative}")
    if relative.suffix.casefold() in FORBIDDEN_SUFFIXES:
        raise PublicationError(f"forbidden binary/cache suffix: {relative}")


def screen_tree(root: Path, *, public_text: bool) -> None:
    for path in root.rglob("*"):
        relative = path.relative_to(root)
        check_safe_relative(relative)
        if path.is_symlink():
            raise PublicationError(f"symlink is not a portable evidence file: {path}")
        if public_text and path.is_file() and path.suffix.casefold() in TEXT_EXTENSIONS:
            if HOST_PATH.search(path.read_text(encoding="utf-8", errors="strict")):
                raise PublicationError(f"host-specific path in public snapshot text: {relative}")


def copy_file(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, destination)


def copy_tree(source: Path, destination: Path) -> None:
    if not source.is_dir():
        raise PublicationError(f"missing selected directory: {source}")
    for file in sorted(path for path in source.rglob("*") if path.is_file()):
        relative = file.relative_to(source)
        check_safe_relative(relative)
        copy_file(file, destination / relative)


def manifest_source_map() -> tuple[dict[str, str], list[tuple[Path, dict]]]:
    manifests = []
    maps = set()
    for path in sorted(CAPTURE.glob("*/*/manifest.json")):
        manifest = read_json(path)
        source_map = manifest.get("provenance", {}).get("wp_mirror_source_sha256")
        if not isinstance(source_map, dict) or not source_map:
            raise PublicationError(f"missing wp-mirror source map: {path}")
        maps.add(json.dumps(source_map, sort_keys=True))
        manifests.append((path, manifest))
    if not manifests or len(maps) != 1:
        raise PublicationError("native manifests must share exactly one nonempty wp-mirror source map")
    return json.loads(maps.pop()), manifests


def audit_native_sources(wp_mirror: Path) -> dict:
    source_map, manifests = manifest_source_map()
    source_root = wp_mirror / "wpmirror"
    missing_or_changed = []
    for relative, expected in source_map.items():
        source = source_root / relative
        if not source.is_file() or sha256(source) != expected:
            missing_or_changed.append(relative)
    if missing_or_changed:
        raise PublicationError(f"wp-mirror source mismatch: {missing_or_changed}")
    adapter_hashes = {manifest["provenance"]["shell_adapter_sha256"] for _, manifest in manifests}
    recorder_hashes = {manifest["provenance"]["shared_frame_recorder_sha256"] for _, manifest in manifests}
    if adapter_hashes != {CURRENT_ADAPTER, OLDER_PILOT_ADAPTER}:
        raise PublicationError(f"unexpected adapter source hashes: {sorted(adapter_hashes)}")
    if sha256(REPO / "tools" / "launcher" / "capture.py") != CURRENT_ADAPTER:
        raise PublicationError("current launcher adapter does not match confirmation-manifest hash")
    recorder = REPO / "tools" / "capture" / "record_native.py"
    if len(recorder_hashes) != 1 or sha256(recorder) != next(iter(recorder_hashes)):
        raise PublicationError("shared recorder does not match native manifest hash")
    older = [str(path.relative_to(STUDY).as_posix()) for path, manifest in manifests if manifest["provenance"]["shell_adapter_sha256"] == OLDER_PILOT_ADAPTER]
    return {"source_files": source_map, "trial_manifests": len(manifests), "recorder_sha256": sha256(recorder), "older_adapter_trials": older}


def validate_media() -> dict:
    index = read_json(MEDIA / "media-index.json")
    items = index.get("items", [])
    if len(items) != 22 or sum(item.get("kind") == "canonical" for item in items) != 20:
        raise PublicationError("media index must enumerate 20 canonical and 2 supplemental items")
    slugs = {item["slug"] for item in items}
    actual = {path.name for path in MEDIA.iterdir() if path.is_dir()}
    if actual != slugs:
        raise PublicationError(f"media directories differ from index: missing={slugs - actual}, extra={actual - slugs}")
    # Legacy standalone files can remain in the working site while the snapshot
    # copies only indexed directories.  They are rejected below if they appear
    # in the publication input.
    for item in items:
        directory = MEDIA / item["slug"]
        manifest = read_json(directory / "media-manifest.json")
        verification = read_json(directory / "media-verification.json")
        if not verification.get("ok") or verification.get("decoded_frames") != verification.get("mapped_frames") or verification.get("dimensions") != [480, 800]:
            raise PublicationError(f"unverified media: {item['slug']}")
        for name, digest in manifest.get("files", {}).items():
            path = directory / name
            if not path.is_file() or sha256(path) != digest:
                raise PublicationError(f"media hash mismatch: {path}")
    return {"items": len(items), "canonical": 20, "supplemental": 2}


def portable_study(study: dict) -> dict:
    return {
        "schema_version": 1,
        "name": study["name"],
        "objective": study["objective"],
        "scope": study["scope"],
        "bindings": {key: f"<{key.upper()}>" for key in study["bindings"]},
        "redaction_map": {key: "portable placeholder; resolve in the maintainer's internal study configuration" for key in study["bindings"]},
        "internal_study_sha256": sha256(STUDY / "study.json"),
        "publication": study["publication"],
        "status": "prepared-local-evidence-snapshot",
        "limits": ["Emulator evidence only; no hardware/Lumia claim.", "30 fps media is a presentation schedule, not acquired native cadence."],
    }


def selected_launcher_files() -> list[Path]:
    root = REPO / "tools" / "launcher"
    return sorted(path for path in root.iterdir() if path.is_file() and path.suffix in {".py", ".json", ".md"})


def expected_snapshot_sources(wp_mirror: Path, native: dict | None = None) -> dict[str, Path | None]:
    """Return the authoritative, explicit snapshot allowlist.

    ``None`` marks a generated record whose bytes are validated separately. The
    output set is derived from current inputs every time verification runs, so a
    self-authored publication inventory cannot authorize an extra file.
    """
    native = native or audit_native_sources(wp_mirror)
    expected: dict[str, Path | None] = {
        "study-public.json": None,
        "publication-inventory.json": None,
        "release-notes.md": None,
        "source-redactions.json": None,
    }
    for relative in ("README.md", "measurements.json", "EVIDENCE-NOTICE.md"):
        expected[f"research/start-screen/{relative}"] = REPO / "research" / "start-screen" / relative
    for relative in (
        "docs/research/start-screen/index.md", "docs/research/index.md", "docs/captures/index.md",
        "docs/resources/index.md", "docs/index.md", "docs/paradigms/index.md",
    ):
        expected[relative] = REPO / relative
    expected["docs/media/start-screen/media-index.json"] = MEDIA / "media-index.json"
    for item in read_json(MEDIA / "media-index.json")["items"]:
        source_dir = MEDIA / item["slug"]
        for source in sorted(path for path in source_dir.rglob("*") if path.is_file()):
            expected[f"docs/media/start-screen/{item['slug']}/{source.relative_to(source_dir).as_posix()}"] = source
    for source in selected_launcher_files():
        expected[f"tools/launcher/{source.name}"] = source
    expected["tools/capture/record_native.py"] = REPO / "tools" / "capture" / "record_native.py"
    for relative in native["source_files"]:
        expected[f"sources/wp-mirror/wpmirror/{relative}"] = None if relative == LEGACY_SOURCE else wp_mirror / "wpmirror" / relative
    return expected


def redacted_legacy_bytes(source: Path) -> bytes:
    """Redact only the unused legacy backend's developer-specific executable path."""
    original = source.read_text(encoding="utf-8")
    pattern = re.compile(r'(?m)^(DEFAULT_EXE\s*=\s*r?")[^"]+("\s*)$')
    published, replacements = pattern.subn(r"\1" + LEGACY_REPLACEMENT + r"\2", original)
    if replacements != 1 or LEGACY_REPLACEMENT not in published or HOST_PATH.search(published):
        raise PublicationError("legacy source redaction did not replace exactly one host-specific DEFAULT_EXE")
    return published.encode("utf-8")


def source_redactions(native: dict, wp_mirror: Path) -> dict:
    original = wp_mirror / "wpmirror" / LEGACY_SOURCE
    published = redacted_legacy_bytes(original)
    expected = native["source_files"].get(LEGACY_SOURCE)
    if expected != sha256(original):
        raise PublicationError("legacy source does not match the raw-manifest hash")
    return {
        "schema_version": 1,
        "redactions": [{
            "relative_path": f"sources/wp-mirror/wpmirror/{LEGACY_SOURCE}",
            "original_sha256": expected,
            "published_sha256": hashlib.sha256(published).hexdigest(),
            "field_or_line_purpose": "DEFAULT_EXE legacy projection-backend executable default",
            "replacement_token": LEGACY_REPLACEMENT,
            "reason": "host-specific developer path",
            "capture_relevance": "legacy projection backend was not used; native manifests identify CaptureImage emulator backend",
        }],
    }


def write_inventory(snapshot: Path) -> dict:
    records = []
    for path in sorted(item for item in snapshot.rglob("*") if item.is_file() and item.name != "publication-inventory.json"):
        relative = path.relative_to(snapshot)
        check_safe_relative(relative)
        records.append({"path": relative.as_posix(), "size_bytes": path.stat().st_size, "sha256": sha256(path), "provenance": relative.parts[0]})
    result = {
        "schema_version": 1,
        "snapshot_file_count": len(records),
        "snapshot_bytes": sum(record["size_bytes"] for record in records),
        "files": records,
        "exclusions": ["raw internal study.json and handoff files", "host bindings", ".preview-new", ".git", "caches and pyc", "standalone live-tile-passive media", "font binaries", "proprietary standalone UI assets"],
        "review_note": "native_status.vm emulator registration suffix is retained inside immutable capture manifests as emulator provenance, not application or user data.",
    }
    (snapshot / "publication-inventory.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    return result


def release_notes(native: dict, media: dict, inventory: dict) -> str:
    measurements = read_json(REPO / "research" / "start-screen" / "measurements.json")
    canonical = sum(len(item["trials"]) for item in measurements["scenario_registry"])
    return f"""# Windows Phone 8.1 Start-screen evidence\n\nRelease tag: `start-screen-evidence-2026-08-30`  \nArchive: `wp81-start-screen-evidence-2026-08-30.zip`\n\nThis release contains {native['trial_manifests']} immutable native trials, {canonical} registry trials across {len(measurements['scenario_registry'])} scenario IDs, and {media['items']} media items ({media['canonical']} canonical, {media['supplemental']} supplemental). The snapshot inventory records {inventory['snapshot_file_count']} files and {inventory['snapshot_bytes']} bytes before archive compression.\n\n## Integrity and source availability\n\nAll native manifests share one {len(native['source_files'])}-file wp-mirror source map and recorder SHA-256 `{native['recorder_sha256']}`; 18 wp-mirror files are published byte-exact, while the unused legacy projection-backend file is transparently privacy-redacted in `source-redactions.json`. The current adapter bytes match the confirmation hash. Two `pilot-01` trials retain older adapter hash `{OLDER_PILOT_ADAPTER}` whose exact adapter source bytes are not retained, so that older adapter is documented but not reconstructed.\n\n## Limits and rights\n\nFrames are WP8.1 emulator observations. Encoded 30 fps is a presentation schedule using held observations, not native acquisition/display/touch cadence. This release makes no Lumia/hardware, exact-easing, physical-latency, font-source, or launcher-package claim. Microsoft-origin emulator UI is attributed research evidence only; no proprietary font binary or standalone Windows artwork is redistributed.\n"""


def build(output: Path, wp_mirror: Path) -> dict:
    if output.exists():
        raise PublicationError(f"fresh output required: {output}")
    if not wp_mirror.is_dir():
        raise PublicationError(f"missing wp-mirror app directory: {wp_mirror}")
    native = audit_native_sources(wp_mirror)
    media = validate_media()
    output.mkdir(parents=True)
    study = read_json(STUDY / "study.json")
    (output / "study-public.json").write_text(json.dumps(portable_study(study), indent=2) + "\n", encoding="utf-8")
    for relative in ("README.md", "measurements.json", "EVIDENCE-NOTICE.md"):
        copy_file(REPO / "research" / "start-screen" / relative, output / "research" / "start-screen" / relative)
    for relative in ("docs/research/start-screen/index.md", "docs/research/index.md", "docs/captures/index.md", "docs/resources/index.md", "docs/index.md", "docs/paradigms/index.md"):
        copy_file(REPO / relative, output / relative)
    copy_file(MEDIA / "media-index.json", output / "docs" / "media" / "start-screen" / "media-index.json")
    for item in read_json(MEDIA / "media-index.json")["items"]:
        copy_tree(MEDIA / item["slug"], output / "docs" / "media" / "start-screen" / item["slug"])
    for source in selected_launcher_files():
        copy_file(source, output / "tools" / "launcher" / source.name)
    copy_file(REPO / "tools" / "capture" / "record_native.py", output / "tools" / "capture" / "record_native.py")
    for relative in native["source_files"]:
        destination = output / "sources" / "wp-mirror" / "wpmirror" / relative
        source = wp_mirror / "wpmirror" / relative
        if relative == LEGACY_SOURCE:
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(redacted_legacy_bytes(source))
        else:
            copy_file(source, destination)
    (output / "source-redactions.json").write_text(
        json.dumps(source_redactions(native, wp_mirror), indent=2) + "\n", encoding="utf-8"
    )
    # The release note itself is an inventory member. Iterate until its stated
    # file/byte totals equal the final inventory rather than the pre-note draft.
    inventory = write_inventory(output)
    for _ in range(3):
        (output / "release-notes.md").write_text(release_notes(native, media, inventory), encoding="utf-8")
        updated = write_inventory(output)
        if updated["snapshot_file_count"] == inventory["snapshot_file_count"] and updated["snapshot_bytes"] == inventory["snapshot_bytes"]:
            inventory = updated
            break
        inventory = updated
    else:
        raise PublicationError("release-note inventory totals did not stabilize")
    screen_tree(output, public_text=True)
    return verify(output, wp_mirror)


def verify(snapshot: Path, wp_mirror: Path) -> dict:
    if not snapshot.is_dir():
        raise PublicationError(f"missing snapshot: {snapshot}")
    native = audit_native_sources(wp_mirror)
    media = validate_media()
    expected = expected_snapshot_sources(wp_mirror, native)
    screen_tree(snapshot, public_text=True)
    stale = list((snapshot / "docs" / "media" / "start-screen").glob("live-tile-passive.*"))
    if stale:
        raise PublicationError(f"stale standalone live-tile media entered snapshot: {stale}")
    actual_all = {path.relative_to(snapshot).as_posix(): path for path in snapshot.rglob("*") if path.is_file()}
    if set(actual_all) != set(expected):
        raise PublicationError(
            "snapshot allowlist mismatch: "
            f"missing={sorted(set(expected) - set(actual_all))}, extra={sorted(set(actual_all) - set(expected))}"
        )
    for relative, source in expected.items():
        if source is not None and sha256(actual_all[relative]) != sha256(source):
            raise PublicationError(f"snapshot source mismatch: {relative}")
    redactions = source_redactions(native, wp_mirror)
    redaction_path = f"sources/wp-mirror/wpmirror/{LEGACY_SOURCE}"
    published_legacy = actual_all[redaction_path]
    declared = read_json(snapshot / "source-redactions.json")
    if declared != redactions or sha256(published_legacy) != redactions["redactions"][0]["published_sha256"]:
        raise PublicationError("legacy source redaction declaration/hash mismatch")
    if LEGACY_REPLACEMENT not in published_legacy.read_text(encoding="utf-8") or HOST_PATH.search(published_legacy.read_text(encoding="utf-8")):
        raise PublicationError("legacy source redaction is missing its token or retains a host path")
    expected_study = json.dumps(portable_study(read_json(STUDY / "study.json")), indent=2) + "\n"
    if actual_all["study-public.json"].read_text(encoding="utf-8") != expected_study:
        raise PublicationError("snapshot portable study bytes differ from authoritative redaction")
    inventory = read_json(snapshot / "publication-inventory.json")
    listed = {entry["path"]: entry for entry in inventory.get("files", [])}
    actual = {relative: path for relative, path in actual_all.items() if relative != "publication-inventory.json"}
    if set(listed) != set(actual):
        raise PublicationError("snapshot inventory membership mismatch")
    for relative, entry in listed.items():
        path = actual[relative]
        if entry["size_bytes"] != path.stat().st_size or entry["sha256"] != sha256(path):
            raise PublicationError(f"snapshot inventory hash mismatch: {relative}")
    expected_notes = release_notes(native, media, inventory)
    if actual_all["release-notes.md"].read_text(encoding="utf-8") != expected_notes:
        raise PublicationError("snapshot release notes differ from authoritative values")
    return {"snapshot": str(snapshot), "snapshot_files": len(actual), "snapshot_bytes": sum(path.stat().st_size for path in actual.values()), "media": media, "native": native}


def write_checksum(archive: Path, checksum: Path) -> dict:
    if not archive.is_file():
        raise PublicationError(f"missing archive: {archive}")
    if checksum.exists():
        raise PublicationError(f"fresh checksum output required: {checksum}")
    if checksum.name != archive.name + ".sha256":
        raise PublicationError("checksum must name the selected archive plus .sha256")
    digest = sha256(archive)
    checksum.write_text(f"{digest}  {archive.name}\n", encoding="ascii", newline="\n")
    return verify_checksum(archive, checksum)


def verify_checksum(archive: Path, checksum: Path) -> dict:
    if not archive.is_file() or not checksum.is_file():
        raise PublicationError("archive and checksum must both exist")
    lines = checksum.read_text(encoding="ascii").splitlines()
    if len(lines) != 1 or not re.fullmatch(r"[0-9a-f]{64}  " + re.escape(archive.name), lines[0]):
        raise PublicationError("checksum must contain one SHA-256 line naming only the archive")
    digest = lines[0].split("  ", 1)[0]
    if digest != sha256(archive):
        raise PublicationError("archive checksum mismatch")
    return {"archive": archive.name, "sha256": digest, "size_bytes": archive.stat().st_size}


def archive_summary(archive: Path) -> dict:
    """Recompute signed release facts from the explicit-input bundle inventory."""
    try:
        with zipfile.ZipFile(archive) as bundle:
            inventory = json.loads(bundle.read("inventory.json"))
    except (OSError, KeyError, json.JSONDecodeError, zipfile.BadZipFile) as error:
        raise PublicationError(f"unreadable explicit-input bundle: {error}") from error
    members = inventory.get("members")
    if not isinstance(members, list):
        raise PublicationError("bundle inventory has no member list")
    labels = Counter(member.get("source_label") for member in members)
    if set(labels) != {"capture", "analysis", "publication"}:
        raise PublicationError(f"bundle labels differ from required explicit set: {sorted(labels)}")
    return {
        "bundle_member_count": len(members),
        "bundle_source_bytes": sum(member["size_bytes"] for member in members),
        "bundle_label_counts": dict(sorted(labels.items())),
    }


def release_report_data(archive: Path, checksum: Path, snapshot: Path, wp_mirror: Path) -> dict:
    checksum_data = verify_checksum(archive, checksum)
    snapshot_data = verify(snapshot, wp_mirror)
    bundle_data = archive_summary(archive)
    measurements = read_json(REPO / "research" / "start-screen" / "measurements.json")
    scenario_ids = len(measurements["scenario_registry"])
    registry_trials = sum(len(item["trials"]) for item in measurements["scenario_registry"])
    native = snapshot_data["native"]
    return {
        "schema_version": 1,
        "release_tag": "start-screen-evidence-2026-08-30",
        "archive": checksum_data,
        **bundle_data,
        "snapshot": {"file_count": snapshot_data["snapshot_files"], "bytes": snapshot_data["snapshot_bytes"]},
        "study_counts": {"scenario_ids": scenario_ids, "registry_trials": registry_trials, "media_items": 22},
        "native_source_provenance": {
            "wp_mirror_source_hashes": native["source_files"],
            "published_source_summary": "18 files byte-exact; framesource/legacy_exe.py is a declared privacy-redacted unused legacy backend file.",
            "source_redactions": source_redactions(native, wp_mirror),
            "shared_recorder_sha256": native["recorder_sha256"],
            "older_pilot_adapter_limit": {
                "adapter_sha256": OLDER_PILOT_ADAPTER,
                "trials": native["older_adapter_trials"],
                "statement": "Exact older pilot adapter bytes are not retained and are not reconstructed.",
            },
        },
        "exclusions_and_privacy_review": {
            "excluded": read_json(snapshot / "publication-inventory.json")["exclusions"],
            "host_path_screening": "public snapshot text rejects Windows and Unix/macOS home paths",
            "native_status_vm_note": "Emulator registration suffix remains immutable capture provenance, not application/user data.",
        },
        "timing_limit": "Encoded 30 fps is a presentation schedule using held native observations, not acquired native cadence or guest/display/touch timing.",
        "evidence_notice_boundary": "Microsoft-origin Windows Phone emulator UI is attributed research evidence only; no proprietary font binary or standalone Windows artwork is redistributed, and no trademark affiliation is implied.",
    }


def write_release_report(archive: Path, checksum: Path, snapshot: Path, wp_mirror: Path, report: Path) -> dict:
    if report.exists():
        raise PublicationError(f"fresh release-report output required: {report}")
    data = release_report_data(archive, checksum, snapshot, wp_mirror)
    report.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    return verify_release_report(archive, checksum, snapshot, wp_mirror, report)


def verify_release_report(archive: Path, checksum: Path, snapshot: Path, wp_mirror: Path, report: Path) -> dict:
    if not report.is_file():
        raise PublicationError(f"missing release report: {report}")
    actual = read_json(report)
    expected = release_report_data(archive, checksum, snapshot, wp_mirror)
    if actual != expected:
        raise PublicationError("release report differs from recomputed archive/snapshot facts")
    return expected


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("build", "verify"):
        command = commands.add_parser(name)
        command.add_argument("output", type=Path, help="new snapshot for build; existing snapshot for verify")
        command.add_argument("--wp-mirror", type=Path, required=True, help="Glance app directory containing wpmirror")
    write = commands.add_parser("write-checksum")
    write.add_argument("archive", type=Path)
    write.add_argument("checksum", type=Path)
    check = commands.add_parser("verify-checksum")
    check.add_argument("archive", type=Path)
    check.add_argument("checksum", type=Path)
    for name in ("write-release-report", "verify-release-report"):
        command = commands.add_parser(name)
        command.add_argument("archive", type=Path)
        command.add_argument("checksum", type=Path)
        command.add_argument("snapshot", type=Path)
        command.add_argument("report", type=Path)
        command.add_argument("--wp-mirror", type=Path, required=True, help="Glance app directory containing wpmirror")
    args = parser.parse_args(argv)
    try:
        if args.command == "build":
            result = build(args.output, args.wp_mirror)
        elif args.command == "verify":
            result = verify(args.output, args.wp_mirror)
        elif args.command == "write-checksum":
            result = write_checksum(args.archive, args.checksum)
        elif args.command == "verify-checksum":
            result = verify_checksum(args.archive, args.checksum)
        elif args.command == "write-release-report":
            result = write_release_report(args.archive, args.checksum, args.snapshot, args.wp_mirror, args.report)
        else:
            result = verify_release_report(args.archive, args.checksum, args.snapshot, args.wp_mirror, args.report)
        print(json.dumps(result, indent=2))
        return 0
    except (PublicationError, OSError, json.JSONDecodeError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
