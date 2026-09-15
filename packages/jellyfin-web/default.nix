{
  jellyfin-web,
  fetchFromGitHub,
  fetchNpmDeps,
  nodejs_24,
}:
(jellyfin-web.override {
  # 12.0 raised the engines requirement to node>=24/npm>=11. `nodejs` is set
  # from this same-named callPackage arg inside nixpkgs' jellyfin-web
  # package.nix, so swapping the arg (not overrideAttrs, which can't reach
  # buildNpmPackage's already-resolved nativeBuildInputs) is what actually
  # changes the node used to build it.
  nodejs_22 = nodejs_24;
}).overrideAttrs (_old: rec {
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
