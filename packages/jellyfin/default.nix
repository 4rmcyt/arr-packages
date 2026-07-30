{
  lib,
  fetchFromGitHub,
  buildDotnetModule,
  dotnetCorePackages,
  jellyfin-web,
  jellyfin-ffmpeg,
  fontconfig,
  freetype,
  sqlite,
  jq,
}: let
  # Must always match packages/jellyfin-web's version exactly. Bump this to
  # the upstream tag you want to track, then run:
  #   nix build .#packages.x86_64-linux.jellyfin.fetch-deps
  #   ./result ./packages/jellyfin/nuget-deps.json
  version = "10.11.11";

  src = fetchFromGitHub {
    owner = "jellyfin";
    repo = "jellyfin";
    tag = "v${version}";
    hash = "sha256-HCs4ZsutVoVH+bBZANjpPeMyV8e63Yemjg9DSr0R9zg=";
  };
in
  buildDotnetModule {
    pname = "jellyfin";
    inherit version src;

    nativeBuildInputs = [jq];
    propagatedBuildInputs = [sqlite];

    projectFile = "Jellyfin.Server/Jellyfin.Server.csproj";
    executables = ["jellyfin"];
    nugetDeps = ./nuget-deps.json;
    runtimeDeps = [
      jellyfin-ffmpeg
      fontconfig
      freetype
    ];
    dotnet-sdk = dotnetCorePackages.sdk_9_0;
    dotnet-runtime = dotnetCorePackages.aspnetcore_9_0;
    dotnetBuildFlags = ["--no-self-contained"];

    makeWrapperArgs = [
      "--add-flags"
      "--ffmpeg=${lib.getExe' jellyfin-ffmpeg "ffmpeg"}"
      "--add-flags"
      "--webdir=${jellyfin-web}/share/jellyfin-web"
    ];

    meta = {
      description = "Free Software Media System";
      homepage = "https://jellyfin.org/";
      license = lib.licenses.gpl2Plus;
      mainProgram = "jellyfin";
    };
  }
