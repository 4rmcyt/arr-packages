{
  bazarr,
  fetchFromGitHub,
  fetchNpmDeps,
}:
bazarr.overrideAttrs (finalAttrs: old: {
  # Bump to the upstream tag, then `nix build .#bazarr` (fails once for src, once for frontend npmDeps).
  version = "1.6.2";

  src = fetchFromGitHub {
    owner = "morpheus65535";
    repo = "bazarr";
    tag = "v${finalAttrs.version}";
    hash = "sha256-5bhNbLfuL1wzraO3UypRRstC1+ULTaFVNJC++Qov6AE=";
  };

  # nixpkgs builds the frontend as passthru.frontend (inherits src/version via finalAttrs).
  passthru =
    old.passthru
    // {
      frontend = old.passthru.frontend.overrideAttrs {
        npmDeps = fetchNpmDeps {
          name = "bazarr-frontend-${finalAttrs.version}-npm-deps";
          inherit (finalAttrs) src;
          sourceRoot = "${finalAttrs.src.name}/frontend";
          hash = "sha256-uvUXk5+/WOfFRuBnC/SQOkau+0uIkJ4OTofMXckmwzw=";
        };
      };
    };
})
