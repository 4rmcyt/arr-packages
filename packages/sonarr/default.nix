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
    # nixpkgs' dotnet8-compatibility patches (targeting version < 5.0) no
    # longer apply cleanly at 4.0.19 -- two csproj hunks reject. Dropping the
    # patches also drops their global.json SDK-version bump though, so
    # dotnetConfigureHook then demands the now-uninstalled SDK 6.0.405.
    # Just delete global.json instead so it picks whatever SDK is installed.
    postPatch = old.src.postPatch + "\nrm -f global.json\n";
    patches = [];
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = "${src}/yarn.lock";
    hash = "sha256-ejAf8/zWX9TbC645vbpyLwa6mrnitU7ByImrJ1d/uX0=";
  };

  nugetDeps = ./deps.json;
})
