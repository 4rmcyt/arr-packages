{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  buildDotnetModule,
  dotnetCorePackages,
  sqlite,
  servarr-ffmpeg,
  fetchYarnDeps,
  yarn,
  fixup-yarn-lock,
  nodejs,
  prefetch-yarn-deps,
}: let
  # Bump this to the upstream tag you want to track, then run:
  #   nix build .#packages.x86_64-linux.radarr.fetch-deps
  #   ./result ./packages/radarr/deps.json
  version = "6.4.4.10685";

  src = fetchFromGitHub {
    owner = "Radarr";
    repo = "Radarr";
    tag = "v${version}";
    hash = "sha256-c7toD4EHn1EJl5l/wvKTh0HGWyIg5BW2SkV4nepvg3I=";
  };

  rid = dotnetCorePackages.systemToDotnetRid stdenvNoCC.hostPlatform.system;
in
  buildDotnetModule {
    pname = "radarr";
    inherit version src;

    strictDeps = true;
    nativeBuildInputs = [nodejs yarn prefetch-yarn-deps fixup-yarn-lock];

    postPatch = ''
      mv src/NuGet.config NuGet.Config
    '';

    yarnOfflineCache = fetchYarnDeps {
      yarnLock = "${src}/yarn.lock";
      hash = "sha256-irAOf0hbhiCet1Xid4oms5bIgtujJlvzNIlxQZU4LwQ=";
    };

    ffprobe = lib.getExe' servarr-ffmpeg "ffprobe";

    postConfigure = ''
      yarn config --offline set yarn-offline-mirror "$yarnOfflineCache"
      fixup-yarn-lock yarn.lock
      yarn install --offline --frozen-lockfile --ignore-platform --ignore-scripts --no-progress --non-interactive
      patchShebangs --build node_modules
    '';
    postBuild = ''
      yarn --offline run build --env production
    '';
    postInstall = ''
      rm -- "$out/lib/radarr/ffprobe"
      ln -s -- "$ffprobe" "$out/lib/radarr/ffprobe"
      cp -a -- _output/UI "$out/lib/radarr/UI"
    '';

    nugetDeps = ./deps.json;

    runtimeDeps = [sqlite];

    dotnet-sdk = dotnetCorePackages.sdk_8_0;
    dotnet-runtime = dotnetCorePackages.aspnetcore_8_0;

    doCheck = false;
    __structuredAttrs = true;

    executables = ["Radarr"];

    projectFile = [
      "src/NzbDrone.Console/Radarr.Console.csproj"
      "src/NzbDrone.Mono/Radarr.Mono.csproj"
    ];

    dotnetFlags = [
      "--property:TargetFramework=net8.0"
      "--property:EnableAnalyzers=false"
      "--property:SentryUploadSymbols=false"
      "--property:Copyright=Copyright 2014-2026 radarr.video (GNU General Public v3)"
      "--property:AssemblyVersion=${version}"
      "--property:AssemblyConfiguration=master"
      "--property:RuntimeIdentifier=${rid}"
    ];

    meta = {
      description = "Usenet/BitTorrent movie downloader";
      homepage = "https://radarr.video";
      license = lib.licenses.gpl3Only;
      mainProgram = "Radarr";
    };
  }
