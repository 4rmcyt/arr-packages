{
  description = "Sonarr/Radarr/Prowlarr/Bazarr/Jellyfin, forked to track upstream release tags directly instead of waiting on nixpkgs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    packages.${system} = rec {
      sonarr = pkgs.callPackage ./packages/sonarr {};
      radarr = pkgs.callPackage ./packages/radarr {};
      prowlarr = pkgs.callPackage ./packages/prowlarr {};
      bazarr = pkgs.callPackage ./packages/bazarr {};
      jellyfin-web = pkgs.callPackage ./packages/jellyfin-web {};
      jellyfin = pkgs.callPackage ./packages/jellyfin {inherit jellyfin-web;};
    };

    overlays.default = final: prev: {
      inherit (self.packages.${prev.system}) sonarr radarr prowlarr bazarr jellyfin jellyfin-web;
    };
  };
}
