{
  prowlarr,
  fetchFromGitHub,
  fetchYarnDeps,
  applyPatches,
  lib,
}:
prowlarr.overrideAttrs (old: rec {
  # Bump this to the upstream tag you want to track, then run:
  #   nix build .#packages.x86_64-linux.prowlarr.fetch-deps
  #   ./result ./packages/prowlarr/deps.json
  version = "2.5.2.5491";

  src = applyPatches {
    src = fetchFromGitHub {
      owner = "Prowlarr";
      repo = "Prowlarr";
      tag = "v${version}";
      hash = lib.fakeHash;
    };
    inherit (old.src) postPatch patches;
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = "${src}/yarn.lock";
    hash = lib.fakeHash;
  };

  nugetDeps = ./deps.json;
})
