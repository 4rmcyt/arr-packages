{
  jellyfin,
  jellyfin-web,
  jellyfin-ffmpeg,
  fetchFromGitHub,
  lib,
}:
jellyfin.overrideAttrs (_old: rec {
  # Must always match packages/jellyfin-web's version exactly.
  version = "10.11.11";

  src = fetchFromGitHub {
    owner = "jellyfin";
    repo = "jellyfin";
    tag = "v${version}";
    hash = lib.fakeHash;
  };

  # Bump this to the upstream tag you want to track, then run:
  #   nix build .#packages.x86_64-linux.jellyfin.fetch-deps
  #   ./result ./packages/jellyfin/nuget-deps.json
  nugetDeps = ./nuget-deps.json;

  # Rebuilt from scratch (rather than patching the inherited makeWrapperArgs)
  # so it always points at *our* jellyfin-web, not nixpkgs' pinned one.
  makeWrapperArgs = [
    "--add-flags"
    "--ffmpeg=${lib.getExe' jellyfin-ffmpeg "ffmpeg"}"
    "--add-flags"
    "--webdir=${jellyfin-web}/share/jellyfin-web"
  ];
})
