#!/usr/bin/env python3
"""Sync the wp_pivot_flutter research site to Cloudflare.

Source:  wp_pivot_flutter/docs/  (Jekyll)
Deploy:  via the `mysite` Cloudflare Worker (Workers Static Assets),
         which serves chinmaykabi.com from the mysite repo root.
         Built HTML is vendored to mysite/wp_pivot_flutter/.

R2 assets: large captures (video, raw frames, CSVs) live in the
         `wp-pivot-assets` R2 bucket, served at
         https://assets.chinmaykabi.com/wp-pivot/...
         Never commit large binaries to git or the mysite repo.

Usage:
  python3 tool/sync_cloudflare_site.py [--mysite ../mysite] [--deploy]

  --mysite  path to the mysite checkout (default: ../mysite)
  --deploy  run `npx wrangler deploy` in mysite after syncing
"""
import argparse
import shutil
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DOCS = REPO / "docs"


def run(cmd, cwd):
    print(f"+ {' '.join(cmd)}  (in {cwd})")
    subprocess.run(cmd, cwd=cwd, check=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mysite", default=str(REPO.parent / "mysite"))
    ap.add_argument("--deploy", action="store_true")
    args = ap.parse_args()

    mysite = Path(args.mysite).resolve()
    dest = mysite / "wp_pivot_flutter"
    if not (mysite / "wrangler.jsonc").exists():
        sys.exit(f"error: {mysite} does not look like the mysite checkout")

    # 1. Jekyll build docs/ -> temp dir
    tmp = REPO / ".cloudflare_site_tmp"
    if tmp.exists():
        shutil.rmtree(tmp)
    run(["jekyll", "build", "--source", str(DOCS), "--destination", str(tmp)], cwd=str(REPO))

    # 2. Drop Jekyll-copied source files (we only want rendered HTML)
    for p in list(tmp.rglob("*.md")) + list(tmp.rglob("*.sh")):
        p.unlink()

    # 3. Vendor into mysite/wp_pivot_flutter/
    if dest.exists():
        shutil.rmtree(dest)
    shutil.copytree(tmp, dest)
    shutil.rmtree(tmp)
    print(f"synced -> {dest}")

    # 4. Optionally deploy the mysite worker (serves chinmaykabi.com)
    if args.deploy:
        run(["npx", "wrangler", "deploy"], cwd=str(mysite))
        print("deployed chinmaykabi.com (mysite worker)")
        print("verify: https://chinmaykabi.com/wp_pivot_flutter/")


if __name__ == "__main__":
    main()
