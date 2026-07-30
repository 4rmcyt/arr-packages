{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  buildDotnetModule,
  dotnetCorePackages,
  sqlite,
  fetchYarnDeps,
  yarn,
  fixup-yarn-lock,
  nodejs,
  prefetch-yarn-deps,
}: let
  # Bump this to the upstream tag you want to track, then run:
  #   nix build .#packages.x86_64-linux.prowlarr.fetch-deps
  #   ./result ./packages/prowlarr/deps.json
  version = "2.5.2.5491";

  src = fetchFromGitHub {
    owner = "Prowlarr";
    repo = "Prowlarr";
    tag = "v${version}";
    hash = "sha256-Q99GbNiMeofccrxfrLPlzns0u3Fy7qFobwPgHNnvG7Q=";
  };

  rid = dotnetCorePackages.systemToDotnetRid stdenvNoCC.hostPlatform.system;
in
  buildDotnetModule {
    pname = "prowlarr";
    inherit version src;

    strictDeps = true;
    nativeBuildInputs = [nodejs yarn prefetch-yarn-deps fixup-yarn-lock];

    postPatch = ''
      mv src/NuGet.config NuGet.Config
    '';

    yarnOfflineCache = fetchYarnDeps {
      yarnLock = "${src}/yarn.lock";
      hash = "sha256-PZw+Q7CcHkbb2bhZKSPE0kvPIhWxWQIqr7/UZlPdqtY=";
    };

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
      cp -a -- _output/UI "$out/lib/prowlarr/UI"
    '';

    nugetDeps = ./deps.json;

    runtimeDeps = [sqlite];

    dotnet-sdk = dotnetCorePackages.sdk_8_0;
    dotnet-runtime = dotnetCorePackages.aspnetcore_8_0;

    doCheck = false;
    __structuredAttrs = true;

    executables = ["Prowlarr"];

    projectFile = [
      "src/NzbDrone.Console/Prowlarr.Console.csproj"
      "src/NzbDrone.Mono/Prowlarr.Mono.csproj"
    ];

    dotnetFlags = [
      "--property:TargetFramework=net8.0"
      "--property:EnableAnalyzers=false"
      "--property:SentryUploadSymbols=false"
      "--property:Copyright=Copyright 2014-2026 prowlarr.com (GNU General Public v3)"
      "--property:AssemblyVersion=${version}"
      "--property:AssemblyConfiguration=master"
      "--property:RuntimeIdentifier=${rid}"
    ];

    meta = {
      description = "Indexer manager/proxy built on the popular arr .net/reactjs base stack";
      homepage = "https://prowlarr.com/";
      license = lib.licenses.gpl3Only;
      mainProgram = "Prowlarr";
    };
  }
