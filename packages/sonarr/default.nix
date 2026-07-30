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
    inherit (old.src) postPatch;
    # nixpkgs' dotnet8-compatibility patches (targeting version < 5.0) no
    # longer apply cleanly at 4.0.19 -- Sonarr.Core.csproj/Sonarr.Host.csproj
    # already carry the .NET 8 changes upstream. Drop them.
    patches = [];
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = "${src}/yarn.lock";
    hash = "sha256-ejAf8/zWX9TbC645vbpyLwa6mrnitU7ByImrJ1d/uX0=";
  };

  nugetDeps = ./deps.json;
})
