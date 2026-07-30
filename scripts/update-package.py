#!/usr/bin/env python3
"""Bump one package to its latest upstream release and refresh all hashes.

Usage: scripts/update-package.py <sonarr|radarr|prowlarr|bazarr|jellyfin|jellyfin-web>

Run from the repo root. Requires `gh`, `nix` (with flakes) on PATH and
GH_TOKEN in the environment. Exits 0 with no changes if already current,
prints "CHANGED" to stdout if the package file was modified.
"""
import json
import re
import subprocess
import sys
from pathlib import Path

PACKAGES = {
    "sonarr": {"owner": "Sonarr", "repo": "Sonarr", "kind": "dotnet-yarn", "deps": "deps.json"},
    "radarr": {"owner": "Radarr", "repo": "Radarr", "kind": "dotnet-yarn", "deps": "deps.json"},
    "prowlarr": {"owner": "Prowlarr", "repo": "Prowlarr", "kind": "dotnet-yarn", "deps": "deps.json"},
    "bazarr": {"owner": "morpheus65535", "repo": "bazarr", "kind": "npm-block"},
    "jellyfin-web": {"owner": "jellyfin", "repo": "jellyfin-web", "kind": "npm-block", "version_from": "jellyfin/jellyfin"},
    "jellyfin": {"owner": "jellyfin", "repo": "jellyfin", "kind": "dotnet-nuget-only", "deps": "nuget-deps.json"},
}


def run(cmd, **kw):
    return subprocess.run(cmd, check=True, text=True, capture_output=True, **kw)


def latest_release_tag(owner_repo: str) -> str:
    out = run(["gh", "api", f"repos/{owner_repo}/releases/latest", "--jq", ".tag_name"]).stdout.strip()
    return out.lstrip("v")


def pinned_version(text: str) -> str:
    m = re.search(r'version = "([^"]+)";', text)
    if not m:
        raise SystemExit("could not find `version = \"...\";` in package file")
    return m.group(1)


def set_version(text: str, version: str) -> str:
    return re.sub(r'version = "[^"]+";', f'version = "{version}";', text, count=1)


def set_hash_in_block(text: str, block_marker: str, new_hash: str) -> str:
    pattern = re.compile(
        rf'({block_marker}\s*\{{.*?hash = )("[^"]*"|lib\.fakeHash)(;.*?\}})',
        re.DOTALL,
    )
    new_text, n = pattern.subn(rf'\g<1>"{new_hash}"\g<3>', text, count=1)
    if n != 1:
        raise SystemExit(f"expected exactly one {block_marker!r} hash to replace, matched {n}")
    return new_text


def prefetch_github_hash(owner: str, repo: str, version: str) -> str:
    out = run(["nix", "flake", "prefetch", "--json", f"github:{owner}/{repo}/v{version}"]).stdout
    return json.loads(out)["hash"]


def fake_then_build_hash(attr: str) -> str:
    """Build the flake attr expecting it to fail on a fakeHash FOD; parse the real hash."""
    proc = subprocess.run(
        ["nix", "build", f".#packages.x86_64-linux.{attr}", "-L"],
        text=True,
        capture_output=True,
    )
    combined = proc.stdout + proc.stderr
    m = re.search(r"got:\s+(sha256-\S+)", combined)
    if not m:
        raise SystemExit(f"could not find a 'got: sha256-...' hash in build output for {attr}:\n{combined[-4000:]}")
    return m.group(1)


def run_fetch_deps(attr: str, deps_path: Path):
    run(["nix", "build", f".#packages.x86_64-linux.{attr}.fetch-deps", "-o", "fetch-deps-result"])
    run(["./fetch-deps-result", str(deps_path)])
    Path("fetch-deps-result").unlink(missing_ok=True)


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in PACKAGES:
        raise SystemExit(f"usage: {sys.argv[0]} <{'|'.join(PACKAGES)}>")

    name = sys.argv[1]
    cfg = PACKAGES[name]
    pkg_dir = Path("packages") / name
    pkg_file = pkg_dir / "default.nix"
    text = pkg_file.read_text()
    current = pinned_version(text)

    version_source = cfg.get("version_from", f"{cfg['owner']}/{cfg['repo']}")
    latest = latest_release_tag(version_source)

    if latest == current:
        print(f"{name}: up to date ({current})")
        return

    print(f"{name}: {current} -> {latest}")
    text = set_version(text, latest)

    src_hash = prefetch_github_hash(cfg["owner"], cfg["repo"], latest)
    text = set_hash_in_block(text, "fetchFromGitHub", src_hash)

    pkg_file.write_text(text)

    if cfg["kind"] == "dotnet-yarn":
        text = pkg_file.read_text()
        text = set_hash_in_block(text, "fetchYarnDeps", "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")
        pkg_file.write_text(text)
        real = fake_then_build_hash(name)
        text = pkg_file.read_text()
        text = set_hash_in_block(text, "fetchYarnDeps", real)
        pkg_file.write_text(text)
        run_fetch_deps(name, pkg_dir / cfg["deps"])

    elif cfg["kind"] == "dotnet-nuget-only":
        run_fetch_deps(name, pkg_dir / cfg["deps"])

    elif cfg["kind"] == "npm-block":
        text = pkg_file.read_text()
        text = set_hash_in_block(text, "fetchNpmDeps", "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")
        pkg_file.write_text(text)
        real = fake_then_build_hash(name)
        text = pkg_file.read_text()
        text = set_hash_in_block(text, "fetchNpmDeps", real)
        pkg_file.write_text(text)

    print("CHANGED")


if __name__ == "__main__":
    main()
