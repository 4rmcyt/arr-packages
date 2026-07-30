{
  bazarr,
  fetchzip,
  lib,
}:
bazarr.overrideAttrs (_old: rec {
  # Bump this to the upstream release tag, get the hash with:
  #   nix-prefetch-url --unpack https://github.com/morpheus65535/bazarr/releases/download/v${version}/bazarr.zip
  version = "1.6.0";

  src = fetchzip {
    url = "https://github.com/morpheus65535/bazarr/releases/download/v${version}/bazarr.zip";
    hash = lib.fakeHash;
  };
})
