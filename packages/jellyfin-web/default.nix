{
  jellyfin-web,
  fetchFromGitHub,
  fetchNpmDeps,
}:
jellyfin-web.overrideAttrs (_old: rec {
  # Must always match packages/jellyfin's version exactly.
  version = "12.0";

  src = fetchFromGitHub {
    owner = "jellyfin";
    repo = "jellyfin-web";
    tag = "v${version}";
    hash = "sha256-LwFjfG+OLgQDP7GqD4/wQhmym4N5QWe/qITQN+hxHh8=";
  };

  # `npmDepsHash` only takes effect inside nixpkgs' own buildNpmPackage call --
  # overrideAttrs can't reach it. Override the actual `npmDeps` fetcher output
  # instead, same as packages/bazarr.
  npmDeps = fetchNpmDeps {
    inherit src;
    hash = "sha256-1s9PWqakzZMiZokOqnKfwaj9s7yWm6e/xh4R5OmTNMc=";
  };
})
