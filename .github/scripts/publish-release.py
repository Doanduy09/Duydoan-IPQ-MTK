#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# [VERIFIED-GOLDEN: gh-release-batched-publisher | 2026-11-26 | DO NOT MODIFY UNLESS TARGETED]
"""
Atomic & Secondary-Rate-Limit-Resilient GitHub Release Publisher for OpenWrt CI.
1. Filters only top-level regular files in FIRMWARE_DIR (skips u-boot-* dirs & release_notes.md).
2. Creates/updates release as DRAFT first (race-safe on HTTP 422).
3. Uploads assets in paced batches (15 files/batch, 1.5s pacing) with exponential backoff
   on GitHub secondary rate limits (HTTP 403/429/5xx) and per-file fallback.
4. Publishes release (--draft=false) only after 100% of assets succeed.
"""

import os
import subprocess
import sys
import time

BATCH_SIZE = 15
PACE_SECONDS = 1.5
BACKOFF_SCHEDULE = [20, 45, 90, 150, 240]
SKIP_NAMES = {"release_notes.md"}


def run_gh(args, timeout=300):
    return subprocess.run(
        ["gh", *args],
        text=True,
        capture_output=True,
        timeout=timeout,
    )


def is_retryable(stderr_text: str) -> bool:
    s = (stderr_text or "").lower()
    markers = (
        "secondary rate limit",
        "abuse detection",
        "rate limit",
        "http 403",
        "http 429",
        "http 500",
        "http 502",
        "http 503",
        "http 504",
        "bad gateway",
        "service unavailable",
        "gateway timeout",
        "tls handshake timeout",
        "connection reset",
        "unexpected eof",
        "eof",
        "timed out",
        "stream error",
    )
    return any(m in s for m in markers)


def run_with_backoff(desc: str, args, timeout=300) -> None:
    max_attempts = len(BACKOFF_SCHEDULE) + 1
    for attempt in range(1, max_attempts + 1):
        try:
            res = run_gh(args, timeout=timeout)
        except subprocess.TimeoutExpired:
            res = None
            err = f"Timeout after {timeout}s"
        else:
            if res.returncode == 0:
                return
            err = (res.stderr or res.stdout or "").strip()

        if attempt < max_attempts and (res is None or is_retryable(err)):
            wait_s = BACKOFF_SCHEDULE[attempt - 1]
            print(
                f"[WARN] {desc} failed (attempt {attempt}/{max_attempts}): {err[:240]} "
                f"-> sleeping {wait_s}s before retry...",
                flush=True,
            )
            time.sleep(wait_s)
            continue

        raise RuntimeError(f"{desc} failed after {attempt} attempt(s): {err}")


def ensure_draft_release(repo: str, tag: str, title: str, notes_file: str) -> None:
    chk = run_gh(["release", "view", tag, "--repo", repo], timeout=60)
    if chk.returncode == 0:
        edit_args = ["release", "edit", tag, "--repo", repo, "--title", title]
        if notes_file and os.path.isfile(notes_file):
            edit_args += ["--notes-file", notes_file]
        run_with_backoff(f"update release {tag}", edit_args, timeout=120)
        return

    create_args = [
        "release",
        "create",
        tag,
        "--repo",
        repo,
        "--draft",
        "--title",
        title,
    ]
    if notes_file and os.path.isfile(notes_file):
        create_args += ["--notes-file", notes_file]
    else:
        create_args += ["--notes", title]

    res = run_gh(create_args, timeout=120)
    if res.returncode == 0:
        return

    err = (res.stderr or res.stdout or "").strip()
    if "already_exists" in err.lower() or "422" in err.lower():
        print(f"[INFO] Release {tag} already created concurrently; updating metadata.", flush=True)
        edit_args = ["release", "edit", tag, "--repo", repo, "--title", title]
        if notes_file and os.path.isfile(notes_file):
            edit_args += ["--notes-file", notes_file]
        run_with_backoff(f"update existing release {tag}", edit_args, timeout=120)
        return

    if is_retryable(err):
        run_with_backoff(f"create draft release {tag}", create_args, timeout=120)
        return

    raise RuntimeError(f"Failed to create release {tag}: {err}")


def collect_assets(fw_dir: str):
    if not os.path.isdir(fw_dir):
        raise RuntimeError(f"FIRMWARE_DIR does not exist: {fw_dir}")

    meta_first = []
    fw_files = []
    for name in sorted(os.listdir(fw_dir)):
        if name in SKIP_NAMES or name.startswith(".") or name.endswith(".tmp"):
            continue
        full = os.path.join(fw_dir, name)
        # Skip u-boot-* subdirectories and symlinks to directories; keep regular files only
        if not os.path.isfile(full):
            continue
        if os.path.getsize(full) == 0:
            continue
        if name in ("profiles.json", "sha256sums") or name.endswith(".manifest") or name.endswith(".buildinfo"):
            meta_first.append(full)
        else:
            fw_files.append(full)
    return meta_first + fw_files


def upload_batch(repo: str, tag: str, batch_paths, batch_idx: int, total_batches: int) -> None:
    desc = f"upload batch {batch_idx}/{total_batches} ({len(batch_paths)} files)"
    args = ["release", "upload", tag, *batch_paths, "--clobber", "--repo", repo]
    try:
        run_with_backoff(desc, args, timeout=600)
    except RuntimeError as batch_err:
        if len(batch_paths) == 1:
            raise
        print(
            f"[WARN] {desc} encountered error ({batch_err}); falling back to single-file upload...",
            flush=True,
        )
        for fp in batch_paths:
            fname = os.path.basename(fp)
            run_with_backoff(
                f"upload single asset {fname}",
                ["release", "upload", tag, fp, "--clobber", "--repo", repo],
                timeout=300,
            )
            time.sleep(1.0)


def main() -> int:
    repo = (os.environ.get("GH_REPO") or os.environ.get("GITHUB_REPOSITORY") or "").strip()
    tag = (os.environ.get("RELEASE_TAG") or "").strip()
    title = (os.environ.get("RELEASE_TITLE") or tag).strip()
    notes_file = (os.environ.get("RELEASE_NOTES_FILE") or "release_notes.md").strip()
    fw_dir = (os.environ.get("FIRMWARE_DIR") or os.environ.get("FIRMWARE") or "").strip()

    if not repo or not tag or not fw_dir:
        print(
            f"[ERR] Missing required env vars: GH_REPO={repo!r}, RELEASE_TAG={tag!r}, FIRMWARE_DIR={fw_dir!r}",
            file=sys.stderr,
        )
        return 1

    if not os.path.isfile(notes_file):
        cand = os.path.join(fw_dir, os.path.basename(notes_file))
        if os.path.isfile(cand):
            notes_file = cand

    assets = collect_assets(fw_dir)
    if not assets:
        print(f"[ERR] No uploadable firmware files found in {fw_dir}", file=sys.stderr)
        return 1

    total_batches = (len(assets) + BATCH_SIZE - 1) // BATCH_SIZE
    print(
        f">> Publishing release {tag} on {repo}: {len(assets)} files across {total_batches} batch(es).",
        flush=True,
    )

    ensure_draft_release(repo, tag, title, notes_file)

    for idx in range(total_batches):
        batch = assets[idx * BATCH_SIZE : (idx + 1) * BATCH_SIZE]
        print(
            f">> Uploading batch {idx + 1}/{total_batches} ({len(batch)} files)...",
            flush=True,
        )
        upload_batch(repo, tag, batch, idx + 1, total_batches)
        if idx + 1 < total_batches:
            time.sleep(PACE_SECONDS)

    run_with_backoff(
        f"publish release {tag}",
        ["release", "edit", tag, "--repo", repo, "--draft=false"],
        timeout=120,
    )
    print(f">> Successfully published {tag} ({len(assets)} assets)!", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
# [/VERIFIED-GOLDEN]
