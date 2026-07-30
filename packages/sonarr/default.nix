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
  #   nix build .#packages.x86_64-linux.sonarr.fetch-deps
  #   ./result ./packages/sonarr/deps.json
  version = "4.0.19.2979";

  src = fetchFromGitHub {
    owner = "Sonarr";
    repo = "Sonarr";
    tag = "v${version}";
    hash = "sha256-hYO7I1zaBSYgobd8GvIx/sWyRzflXMFjnnPB21pm4wQ=";
  };

  rid = dotnetCorePackages.systemToDotnetRid stdenvNoCC.hostPlatform.system;
in
  buildDotnetModule {
    pname = "sonarr";
    inherit version src;

    installPath = "${placeholder "out"}/lib/sonarr/bin";
    strictDeps = true;
    nativeBuildInputs = [nodejs yarn prefetch-yarn-deps fixup-yarn-lock];

    postPatch = ''
      mv src/NuGet.Config NuGet.Config
      substituteInPlace src/NzbDrone.Host/Startup.cs \
        --replace-fail 'IPNetwork' 'Microsoft.AspNetCore.HttpOverrides.IPNetwork'
      # global.json pins an SDK version older than what's installed; let
      # dotnet fall back to whatever SDK we actually have.
      rm -f global.json
      # These class libraries still declare only net6.0; the --property:TargetFramework=net8.0
      # override below can't add a framework that isn't in a project's own
      # <TargetFrameworks> list, so the library projects must say so themselves.
      find src -name '*.csproj' -exec \
        sed -i 's#<TargetFrameworks>net6.0</TargetFrameworks>#<TargetFrameworks>net8.0</TargetFrameworks>#' {} +
    '';

    yarnOfflineCache = fetchYarnDeps {
      yarnLock = "${src}/yarn.lock";
      hash = "sha256-ejAf8/zWX9TbC645vbpyLwa6mrnitU7ByImrJ1d/uX0=";
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
      ln -sf -- "$ffprobe" "$out/lib/sonarr/bin/ffprobe"
      cp -a -- _output/UI "$out/lib/sonarr/bin/UI"
    '';
    postFixup = ''
      ln -s -- Sonarr "$out/bin/NzbDrone"
    '';

    nugetDeps = ./deps.json;

    runtimeDeps = [sqlite];

    dotnet-sdk = dotnetCorePackages.sdk_8_0;
    dotnet-runtime = dotnetCorePackages.aspnetcore_8_0;

    doCheck = false;
    __structuredAttrs = true;

    executables = ["Sonarr"];

    projectFile = [
      "src/NzbDrone.Console/Sonarr.Console.csproj"
      "src/NzbDrone.Mono/Sonarr.Mono.csproj"
    ];

    dotnetFlags = [
      "--property:TargetFramework=net8.0"
      "--property:EnableAnalyzers=false"
      "--property:SentryUploadSymbols=false"
      "--property:Copyright=Copyright 2014-2026 sonarr.tv (GNU General Public v3)"
      "--property:AssemblyVersion=${version}"
      "--property:AssemblyConfiguration=main"
      "--property:RuntimeIdentifier=${rid}"
      # NuGet's own restore-time downgrade check (NU1605) is promoted to an
      # error independently of the general TreatWarningsAsErrors switch --
      # the now-dropped dotnet8-compat patches used to pin these transitive
      # versions to avoid it. NoWarn only accepts one code here: a value with
      # multiple ';'-separated codes gets mangled somewhere in the flags
      # plumbing (confirmed: "NU1605;CS1591" -> MSBuild saw "CS1591" as its
      # own switch). CS1591 (missing XML doc) is handled separately below.
      "--property:NoWarn=NU1605"
      "--property:GenerateDocumentationFile=false"
    ];

    meta = {
      description = "Smart PVR for newsgroup and bittorrent users";
      homepage = "https://sonarr.tv";
      license = lib.licenses.gpl3Only;
      mainProgram = "Sonarr";
    };
  }
