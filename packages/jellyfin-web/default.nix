{
  lib,
  jellyfin-web,
  fetchFromGitHub,
  fetchNpmDeps,
}:
jellyfin-web.overrideAttrs (_old: rec {
  # Must always match packages/jellyfin's version exactly.
  version = "12.1";

  src = fetchFromGitHub {
    owner = "jellyfin";
    repo = "jellyfin-web";
    tag = "v${version}";
    hash = "sha256-WR62ZkhLVn0+cbY0FEDvKcmCGb78tIiK2wIc5Y6rUn8=";
  };

  # `npmDepsHash` only takes effect inside nixpkgs' own buildNpmPackage call --
  # overrideAttrs can't reach it. Override the actual `npmDeps` fetcher output
  # instead, same as packages/bazarr.
  npmDeps = fetchNpmDeps {
    inherit src;
    hash = lib.fakeHash;
  };
})
