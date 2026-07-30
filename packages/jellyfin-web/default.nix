{
  jellyfin-web,
  fetchFromGitHub,
  lib,
}:
jellyfin-web.overrideAttrs (_old: rec {
  # Must always match packages/jellyfin's version exactly.
  version = "10.11.11";

  src = fetchFromGitHub {
    owner = "jellyfin";
    repo = "jellyfin-web";
    tag = "v${version}";
    hash = lib.fakeHash;
  };

  # Regenerate with the standard fakeHash-then-copy-from-error trick
  # (single FOD, no fetch-deps step needed here).
  npmDepsHash = lib.fakeHash;
})
