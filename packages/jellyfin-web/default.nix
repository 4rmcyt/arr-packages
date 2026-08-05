{
  jellyfin-web,
  fetchFromGitHub,
  fetchNpmDeps,
}:
jellyfin-web.overrideAttrs (_old: rec {
  # Must always match packages/jellyfin's version exactly.
  version = "10.11.11";

  src = fetchFromGitHub {
    owner = "jellyfin";
    repo = "jellyfin-web";
    tag = "v${version}";
    hash = "sha256-3Gyg0eSbOXO0wgdgzuOtD8nDmSM37z7Bc0fKcbo9ffA=";
  };

  # `npmDepsHash` only takes effect inside nixpkgs' own buildNpmPackage call --
  # overrideAttrs can't reach it. Override the actual `npmDeps` fetcher output
  # instead, same as packages/bazarr.
  npmDeps = fetchNpmDeps {
    inherit src;
    hash = "sha256-4kZo50xY/SvjpHToeIt0E91yeM7ab6Q6XtBMU5zSrF4=";
  };
})
