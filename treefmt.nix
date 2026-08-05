{pkgs, ...}: {
  projectRootFile = "flake.nix";
  programs = {
    alejandra = {
      enable = true;
      includes = ["*.nix"];
      package = pkgs.alejandra;
    };
    deadnix = {
      enable = true;
      includes = ["*.nix"];
      package = pkgs.deadnix;
    };
    statix = {
      enable = true;
      includes = ["*.nix"];
      package = pkgs.statix;
    };
    ruff-format = {
      enable = true;
      package = pkgs.ruff;
    };
    prettier = {
      enable = true;
      includes = [
        "*.json"
        "*.md"
      ];
      package = pkgs.prettier;
    };
    yamlfmt = {
      enable = true;
      includes = [
        "*.yaml"
        "*.yml"
      ];
      package = pkgs.yamlfmt;
    };
  };

  settings.global.excludes = [
    "flake.lock"
    "packages/*/deps.json"
    "packages/*/nuget-deps.json"
  ];
}
