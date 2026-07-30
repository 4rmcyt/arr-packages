{
  radarr,
  fetchFromGitHub,
  fetchYarnDeps,
  applyPatches,
  lib,
}:
radarr.overrideAttrs (old: rec {
  # Bump this to the upstream tag you want to track, then run:
  #   nix build .#packages.x86_64-linux.radarr.fetch-deps
  #   ./result ./packages/radarr/deps.json
  version = "6.3.0.10514";

  src = applyPatches {
    src = fetchFromGitHub {
      owner = "Radarr";
      repo = "Radarr";
      tag = "v${version}";
      hash = lib.fakeHash;
    };
    # Keep upstream nixpkgs' postPatch/patches only if they still apply at
    # this version (dotnet8-compat patches only target `version < 6.0`).
    inherit (old.src) postPatch patches;
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = "${src}/yarn.lock";
    hash = lib.fakeHash;
  };

  nugetDeps = ./deps.json;
})
