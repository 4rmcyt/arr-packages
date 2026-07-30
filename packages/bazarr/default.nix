{
  bazarr,
  fetchFromGitHub,
  fetchNpmDeps,
}:
bazarr.overrideAttrs (_old: rec {
  # Bump this to the upstream tag you want to track, then run:
  #   nix build .#packages.x86_64-linux.bazarr  (fails once for src, once for npmDeps)
  version = "1.6.0";

  src = fetchFromGitHub {
    owner = "morpheus65535";
    repo = "bazarr";
    tag = "v${version}";
    hash = "sha256-r3H0JEcGYzQOTHVR/zONmtOIF+LnJd+qn2pcAj8vdOA=";
  };

  npmDeps = fetchNpmDeps {
    name = "bazarr-${version}-npm-deps";
    inherit src;
    sourceRoot = "${src.name}/frontend";
    hash = "sha256-cb++eqVtKZer9B1rwJ9WR4mZImnASeFU2MojgXAPWf4=";
  };
})
