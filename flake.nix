{
  description = "Sonarr/Radarr/Prowlarr/Bazarr/Jellyfin, forked to track upstream release tags directly instead of waiting on nixpkgs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.treefmt-nix.url = "github:numtide/treefmt-nix";
  inputs.treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = {
    self,
    nixpkgs,
    treefmt-nix,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
  in {
    packages.${system} = rec {
      sonarr = pkgs.callPackage ./packages/sonarr {};
      radarr = pkgs.callPackage ./packages/radarr {};
      prowlarr = pkgs.callPackage ./packages/prowlarr {};
      bazarr = pkgs.callPackage ./packages/bazarr {};
      jellyfin-web = pkgs.callPackage ./packages/jellyfin-web {};
      jellyfin = pkgs.callPackage ./packages/jellyfin {inherit jellyfin-web;};
    };

    formatter.${system} = treefmtEval.config.build.wrapper;
    checks.${system}.formatting = treefmtEval.config.build.check self;

    overlays.default = final: prev: {
      inherit (self.packages.${prev.system}) sonarr radarr prowlarr bazarr jellyfin jellyfin-web;
    };
  };
}
