# arr-packages

Sonarr, Radarr, Prowlarr, Bazarr, and Jellyfin (+ jellyfin-web), built from
upstream release tags via a Nix flake and pushed to Cachix.

## Why

nixpkgs packages these apps too, but its pin lags upstream releases by
anywhere from days to months. For Jellyfin specifically, that gap causes
plugins to fail ABI compatibility checks (`targetAbi` mismatch) as soon as a
plugin is built against a newer Jellyfin than what nixpkgs ships. This flake
tracks the exact upstream release tag for each package instead of waiting on
nixpkgs, while reusing nixpkgs' own build recipes (`buildDotnetModule`,
`buildNpmPackage`, etc.) as a base.

## Packages

| Package        | Kind                                   | Notes                                                                                                  |
| -------------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| `sonarr`       | `buildDotnetModule`                    | Needs manual `net8.0`/package-version patches per bump (see comments in `packages/sonarr/default.nix`) |
| `radarr`       | `buildDotnetModule`                    |                                                                                                        |
| `prowlarr`     | `buildDotnetModule`                    |                                                                                                        |
| `bazarr`       | `stdenv.mkDerivation` + `fetchNpmDeps` |                                                                                                        |
| `jellyfin`     | `buildDotnetModule`                    | Version must always match `jellyfin-web`                                                               |
| `jellyfin-web` | `buildNpmPackage`                      | Version must always match `jellyfin`                                                                   |

Each package overrides only `version`/`src`/deps compared to nixpkgs' own
derivation — **not** `<pkg>.overrideAttrs`. `overrideAttrs` can't reach
`nugetDeps`/`npmDeps` for these build helpers (they're consumed inside the
original `buildDotnetModule`/`buildNpmPackage` call, before `overrideAttrs`
ever runs), so bumping a version that way silently keeps building against the
_old_ dependency graph. These packages call `buildDotnetModule`/
`buildNpmPackage` directly instead.

## Updating

### Automatic

`.github/workflows/auto-update.yml` runs daily (06:00 UTC) and on
`workflow_dispatch`. For each package it checks the latest upstream GitHub
release; if newer than what's pinned, it bumps `version`, refetches the
source hash, regenerates `deps.json`/`nuget-deps.json`/`npmDeps` hash (this
step needs real network access — it's an actual `dotnet restore`/`npm
install`), and commits straight to `main`. One package failing doesn't block
the others. A successful commit push then explicitly triggers `build.yml`
via `gh workflow run` (a push made with `GITHUB_TOKEN` doesn't trigger
`on: push` on its own — GitHub's anti-recursion rule).

### Manual / one-off deps regeneration

```console
$ python3 scripts/update-package.py <sonarr|radarr|prowlarr|bazarr|jellyfin|jellyfin-web> [--force-deps]
```

Without `--force-deps`, it only acts if a newer upstream release exists.
With `--force-deps`, it regenerates deps for the **currently pinned**
version without checking for an update — useful right after fixing how a
package consumes its deps (e.g. the `overrideAttrs` → direct-call rewrite
above), since deps generated under the old, broken mechanism don't reflect
reality.

Requires `gh`, `nix` (flakes enabled), and `GH_TOKEN` in the environment.

### Bumping a dotnet package by hand

nixpkgs' `buildDotnetModule` requires a real network-backed `dotnet restore`
to enumerate the full NuGet graph — there's no single-hash trick like
`fetchYarnDeps`/`fetchNpmDeps`. After bumping `version`/`src`:

```console
$ nix build .#packages.x86_64-linux.<pkg>.fetch-deps -o fetch-deps-result
$ ./fetch-deps-result ./packages/<pkg>/deps.json   # or nuget-deps.json for jellyfin
```

## CI

- `build.yml` — matrix build of all 6 packages, pushes results to
  [Cachix](https://arr-packages.cachix.org).
- `auto-update.yml` — see above.

## Consuming this flake

```nix
inputs.arr-packages.url = "github:4rmcyt/arr-packages";
```

Then overlay the packages you want, and add the Cachix substituter/public
key so you pull prebuilt binaries instead of rebuilding locally:

```nix
nixpkgs.overlays = [
  (final: prev: {
    inherit (inputs.arr-packages.packages.${prev.system}) sonarr radarr prowlarr bazarr jellyfin jellyfin-web;
  })
];

nix.settings = {
  extra-substituters = ["https://arr-packages.cachix.org"];
  extra-trusted-public-keys = ["arr-packages.cachix.org-1:oEUMZth/blE0vXVc2zWhczUyaKGvII8UlwHFxSO78WY="];
};
```

Do **not** set `inputs.arr-packages.inputs.nixpkgs.follows`. These packages
are built and cached against this flake's own `nixpkgs` pin; following your
own would change the derivation hash and force a local rebuild instead of a
Cachix hit.
