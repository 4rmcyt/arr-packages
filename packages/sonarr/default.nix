{
  sonarr,
  fetchFromGitHub,
  fetchYarnDeps,
  applyPatches,
  lib,
}:
sonarr.overrideAttrs (old: rec {
  # Bump this to the upstream tag you want to track, then run:
  #   nix build .#packages.x86_64-linux.sonarr.fetch-deps
  #   ./result ./packages/sonarr/deps.json
  version = "4.0.19.2979";

  src = applyPatches {
    src = fetchFromGitHub {
      owner = "Sonarr";
      repo = "Sonarr";
      tag = "v${version}";
      hash = "sha256-hYO7I1zaBSYgobd8GvIx/sWyRzflXMFjnnPB21pm4wQ=";
    };
    # Keep upstream nixpkgs' postPatch/patches only if they still apply at
    # this version (dotnet8-compat patches only target `version < 5.0`).
    inherit (old.src) postPatch patches;
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = "${src}/yarn.lock";
    hash = lib.fakeHash;
  };

  nugetDeps = ./deps.json;
})
