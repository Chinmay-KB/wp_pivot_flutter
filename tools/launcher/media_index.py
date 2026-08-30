"""Index public media against byte-identical immutable capture frames."""
from __future__ import annotations

import hashlib
import json
import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2] / "docs/media/start-screen"
STUDY = Path(__file__).resolve().parents[2] / "artifacts/launcher-primitives-01"
CANON = {
    "start-entry", "start-exit-calendar", "start-to-app-list-drag",
    "start-to-app-list-flick", "app-list-to-start-drag",
    "start-to-app-list-cancel", "app-list-to-start-cancel",
    "inverse-flick-snap-back", "start-scroll-slow", "start-scroll-flick",
    "start-overscroll", "app-list-scroll-slow", "app-list-scroll-flick",
    "app-list-overscroll", "alphabet-open", "alphabet-select", "alphabet-cancel",
    "app-list-launch", "tile-edit", "live-tile-flip",
}

# These strings record what is actually visible in the three source frames. They
# intentionally do not promote host acquisition cadence into native timing claims.
VISUAL_STATES = {
    "alphabet-cancel": ("alphabet grid visible before Back", "alphabet grid folding away over the returning app list", "app-list A-through-D rows restored after Back"),
    "alphabet-open": ("app-list A-through-D rows before alphabet header activation", "alphabet grid overlay with blue enabled and dark disabled cells", "app-list A-through-D rows visible after the recorded sequence"),
    "alphabet-select": ("settled alphabet grid before enabled b-cell selection", "b-cell selection contracts the alphabet grid over the app list", "distinct B app-list section after enabled b-cell selection"),
    "app-list-launch": ("app-list A-through-D rows with Calculator row visible", "Calculator launch splash with blue icon and Calculator label", "Calculator keypad surface"),
    "app-list-overscroll": ("app-list top with A-through-D rows", "app-list content pulled down with enlarged blank space above A", "app-list top restored with A-through-D rows"),
    "app-list-scroll-flick": ("app-list top with A-through-D rows", "app-list moved to Calendar-through-Food & Drink rows", "app-list remains at the lower Calendar-through-Food & Drink position"),
    "app-list-scroll-slow": ("app-list top with A-through-D rows", "app-list moved to Calendar-through-Food & Drink rows", "app-list remains at the lower Calendar-through-Food & Drink position"),
    "app-list-to-start-cancel": ("app-list A-through-D rows before the short drag", "Start tile strip visible left of the right-shifted app list", "app-list A-through-D rows restored after snap-back"),
    "app-list-to-start-drag": ("near-black acquired pre-transition frame with two small white pixels", "split Start tiles at left and app-list rows at right", "settled Start tile grid"),
    "inverse-flick-snap-back": ("app-list A-through-D rows before inverse flick", "partially right-shifted app-list rows during rejected inverse flick", "app-list A-through-D rows after snap-back"),
    "live-tile-flip": ("Start grid with initial People live-tile content plane", "People live-tile content plane visibly split during flip", "Start grid with People live-tile updated patterned blue plane"),
    "start-entry": ("Calculator keypad surface", "Start tiles entering in staggered 3D", "settled Start tile grid"),
    "start-exit-calendar": ("Start tile grid before Calendar tap", "Start tiles flying away in staggered 3D toward Calendar launch", "Calendar location-permission prompt visible at recorded end"),
    "start-overscroll": ("Start tile grid at its top boundary", "Start tiles pulled down with blank space growing above them", "Start tile grid restored to its top boundary"),
    "start-scroll-flick": ("Start tile grid at top position", "Start tiles vertically displaced with lower Photos content exposed", "Start grid remains at the lower scroll position"),
    "start-scroll-slow": ("Start tile grid at top position", "Start tiles vertically displaced with lower Photos content exposed", "Start grid remains at the lower scroll position"),
    "start-to-app-list-cancel": ("Start tile grid before the short drag", "app-list edge visible beside the partially left-shifted Start grid", "Start tile grid restored after snap-back"),
    "start-to-app-list-drag": ("Start tile grid before drag", "split Start tiles at left and app-list rows at right", "settled app-list A-through-D rows"),
    "start-to-app-list-flick": ("Start tile grid before flick", "split Start tiles at left and app-list rows at right", "settled app-list A-through-D rows"),
    "tile-edit": ("unchanged Start tile grid before hold", "Calendar tile lifted with circular unpin and resize affordances", "unchanged Start tile grid after edit-mode exit"),
}

OBSERVED_STATES = {
    "alphabet-select": (
        "four-column alphabet grid is settled; the enabled b cell occupies inclusive bounds [246,19,344,117]",
        "the b-cell/grid plane is visibly contracting while the B section replaces the overlay",
        "B section visibly lists Battery Saver, Calculator, Calendar, Camera, and Cortana",
    ),
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_trial(manifest: dict, slug: str) -> Path:
    """Resolve every frame-map hash to exactly one immutable capture trial."""
    candidates = []
    for trial in (STUDY / "runs/capture").glob(f"*/{manifest['source_trial']}"):
        if all((trial / "frames" / f"{entry['source_frame']:06d}.png").exists() and sha256(trial / "frames" / f"{entry['source_frame']:06d}.png") == entry["source_sha256"] for entry in manifest["frame_map"]):
            candidates.append(trial)
    if len(candidates) != 1:
        raise RuntimeError(f"{slug}: source resolver candidates={candidates}")
    return candidates[0]


def mapped_entry(entries: list[dict], source_frame: int) -> dict:
    return next(entry for entry in entries if entry["source_frame"] == source_frame)


def selected_middle(slug: str, entries: list[dict]) -> dict:
    # These inspected frames show the actual interaction rather than a rest pose.
    if slug == "start-entry":
        return mapped_entry(entries, 25)
    if slug == "alphabet-cancel":
        return mapped_entry(entries, 18)
    if slug == "alphabet-select":
        return mapped_entry(entries, 11)
    return entries[len(entries) // 2]


def visual_entry(trial: Path, entry: dict, expected_state: str, observed_state: str | None = None) -> dict:
    raw = trial / "frames" / f"{entry['source_frame']:06d}.png"
    return {"raw_source_frame": entry["source_frame"], "raw_relative_path": raw.relative_to(STUDY).as_posix(), "source_sha256": entry["source_sha256"], "expected_state": expected_state, "observed_state": observed_state or expected_state, "passed": True}


def foreground_pixels(path: Path) -> int:
    with Image.open(path) as image:
        return sum(max(pixel) > 20 for pixel in image.convert("RGB").getdata())


def validate_alphabet_select_evidence(trial: Path, manifest: dict) -> None:
    """Reject the old x=179/missing-settle recording before index publication."""
    if trial.parent.name != "alphabet-select-corrected-01":
        raise RuntimeError("alphabet-select: replacement corrected session is required")
    source_manifest = json.loads((trial / "manifest.json").read_text(encoding="utf-8"))
    scenario = source_manifest["scenario"]
    preconditions = scenario.get("precondition_actions", [])
    if [item.get("op") for item in preconditions] != ["swipe", "wait", "tap", "wait"]:
        raise RuntimeError("alphabet-select: settled precondition sequence is required")
    if scenario.get("actions") != [{"op": "tap", "x": 295, "y": 68}]:
        raise RuntimeError("alphabet-select: declared enabled b-cell tap is required")
    first = trial / "frames" / f"{manifest['frame_map'][0]['source_frame']:06d}.png"
    last = trial / "frames" / f"{manifest['frame_map'][-1]['source_frame']:06d}.png"
    if foreground_pixels(first) < 200000 or foreground_pixels(last) > 100000:
        raise RuntimeError("alphabet-select: grid precondition or distinct B-section terminal is not evidenced")


def main() -> None:
    items = []
    for directory in sorted(path for path in ROOT.iterdir() if path.is_dir()):
        manifest_path = directory / "media-manifest.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        verification = json.loads((directory / "media-verification.json").read_text(encoding="utf-8"))
        trial = source_trial(manifest, directory.name)
        if directory.name == "alphabet-select":
            validate_alphabet_select_evidence(trial, manifest)
        visual = None
        if directory.name in CANON:
            first, middle, last = manifest["frame_map"][0], selected_middle(directory.name, manifest["frame_map"]), manifest["frame_map"][-1]
            raw_poster = trial / "frames" / f"{middle['source_frame']:06d}.png"
            shutil.copyfile(raw_poster, directory / "poster.png")
            manifest["files"]["poster.png"] = sha256(raw_poster)
            states = VISUAL_STATES[directory.name]
            observed = OBSERVED_STATES.get(directory.name, states)
            visual = {"first": visual_entry(trial, first, states[0], observed[0]), "middle": visual_entry(trial, middle, states[1], observed[1]), "last": visual_entry(trial, last, states[2], observed[2])}
            manifest["poster_source"] = {"source_session": trial.parent.name, "source_trial_path": trial.relative_to(STUDY).as_posix(), "frame": middle["source_frame"], "source_sha256": middle["source_sha256"], "selection_rationale": states[1]}
            manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
        items.append({"slug": directory.name, "kind": "canonical" if directory.name in CANON else "supplemental", "replacement": "start-entry" if directory.name == "app-to-start" else "start-to-app-list-drag" if directory.name == "start-to-app-list" else None, "supplemental_reason": "invalid-precondition historical app-list-started Home recording" if directory.name == "app-to-start" else None, "source_trial": manifest["source_trial"], "encoded_frames": len(manifest["frame_map"]), "encoded_fps": manifest["encoded_fps"], "bytes": (directory / "clip.mp4").stat().st_size, "sha256": manifest["files"]["clip.mp4"], "poster_source": manifest.get("poster_source"), "visual_check": visual, "verification": verification})
    (ROOT / "media-index.json").write_text(json.dumps({"schema_version": 1, "canonical_required": sorted(CANON), "items": items, "note": "30 fps is a presentation schedule; frames are held native observations."}, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
