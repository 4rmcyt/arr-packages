{
  lib,
  bazarr,
  fetchFromGitHub,
  fetchNpmDeps,
}:
bazarr.overrideAttrs (_old: rec {
  # Bump this to the upstream tag you want to track, then run:
  #   nix build .#packages.x86_64-linux.bazarr  (fails once for src, once for npmDeps)
  version = "1.6.1";

  src = fetchFromGitHub {
    owner = "morpheus65535";
    repo = "bazarr";
    tag = "v${version}";
    hash = "sha256-m9429gSt9xrA3N9w6eIBtHmQWOZDiRKIsu52fusQutU=";
  };

  npmDeps = fetchNpmDeps {
    name = "bazarr-${version}-npm-deps";
    inherit src;
    sourceRoot = "${src.name}/frontend";
    hash = lib.fakeHash;
  };
})
