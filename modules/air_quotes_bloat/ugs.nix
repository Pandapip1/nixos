{
  lib,
  config,
  pkgs,
  ...
}:

let
  # normalizeNbmHook = pkgs.makeSetupHook
  #   {
  #     name = "normalize-nbm-hook";
  #     propagatedBuildInputs = with pkgs; [
  #       unzip
  #       zip
  #       gnused
  #     ];
  #     substitutions = {
  #       shell = lib.getExe pkgs.bash;
  #     };
  #   }
  #   (
  #     pkgs.writeScript "normalize-nbm-hook.sh" ''
  #       #!@shell@

  #       _normalizeNbm() {
  #         if [ -d "$out" ]; then
  #           echo "Normalizing NBMs in $out..."
  #           find "$out" -type f -name "*.nbm" | sort | while read nbm; do
  #             tmp=$(mktemp -d)
  #             unzip -q "$nbm" -d "$tmp"

  #             # Normalize manifest
  #             if [ -f "$tmp/META-INF/MANIFEST.MF" ]; then
  #               sed -i '/^Created-By/d;/^Build-Jdk/d' "$tmp/META-INF/MANIFEST.MF"
  #             fi

  #             # Normalize Info/info.xml timestamps
  #             if [ -f "$tmp/Info/info.xml" ]; then
  #               sed -i 's|<build-date>.*</build-date>|<build-date>2026-03-02T00:00:00Z</build-date>|' "$tmp/Info/info.xml"
  #             fi

  #             # Repack NBM in place
  #             (cd "$tmp" && zip -X -r "$nbm" .)

  #             rm -rf "$tmp"
  #           done
  #         fi
  #       }

  #       postFixupHooks+=(_normalizeNbm)
  #     ''
  #   );
  # netbeans-nbms = with pkgs; stdenvNoCC.mkDerivation rec {
  #   pname = "netbeans-nbms";
  #   version = "29";

  #   src = fetchFromGitHub {
  #     owner = "apache";
  #     repo = "netbeans";
  #     tag = "29";
  #     hash = "sha256-w9d6qbra7VfE4gJOpUMrgWTdPgdraEIMh9nOU0sYHzg=";
  #   };

  #   nativeBuildInputs = [ ant normalizeNbmHook ];
  #   buildInputs = [ jdk17_headless ];

  #   JAVA_HOME = jdk17_headless;

  #   dontConfigure = true;

  #   # Following instructions/info from https://bits.netbeans.org/mavenutilities/nb-repository-plugin/repository.html
  #   buildPhase = ''
  #     runHook preBuild

  #     ant clean
  #     ant build
  #     ant build-nbms

  #     runHook postBuild
  #   '';

  #   installPhase = ''
  #     runHook preInstall

  #     mkdir -p $out
  #     cp -r nbbuild/nbms/. $out

  #     runHook postInstall
  #   '';

  #   env.SOURCE_DATE_EPOCH = "0";

  #   meta = with lib; {
  #     description = "All NetBeans NBMs built from source";
  #     homepage = "https://netbeans.apache.org/";
  #     maintainers = with maintainers; [ ];
  #   };

  #   # This is a FOD b/c I can't be bothered trying to sandbox this nonsense. It's turtles all the way down!
  #   # The nixpkgs netbeans package itself uses the binaries so ¯\_(ツ)_/¯
  #   outputHashMode = "recursive";
  #   outputHash = "sha256-dmSAoSgvZLbmAmijzIL3zkLPmbF6eCZC/1NBrmAYvcU="; # "sha256-gdrL8R2eOoKqR4SX6HX8Ai9nruDI1ixU0nqrSAVYqOs=";
  # };
  grbl-src = pkgs.fetchFromGitHub {
    owner = "gnea";
    repo = "grbl";
    tag = "v1.1h.20190825";
    hash = "sha256-Axb1SmQJA2quNs6exsIDvv8SaZ0sWkjXJNtJfexkTP0=";
  };
  ugs-unstable = pkgs.maven.buildMavenPackage rec {
    pname = "ugs";
    version = "0-unstable";

    src = pkgs.fetchFromGitHub {
      owner = "winder";
      repo = "Universal-G-Code-Sender";
      rev = "e642eb64a73fe77ff13f6679b34b498ee1d11af5";
      sha256 = "9V5p4DaOmA05CHMOhCkvg/oOGvBTUsimWLr/RKTW148=";
    };

    postPatch = ''
      xmlstarlet ed -L \
        -N x="http://maven.apache.org/POM/4.0.0" \
        -d "/x:project/x:build/x:plugins/x:plugin[x:artifactId='download-maven-plugin']" \
        -d "/x:project/x:reporting/x:plugins/x:plugin[x:artifactId='cobertura-maven-plugin']" \
        ugs-core/pom.xml
      xmlstarlet ed -L \
        -N x="http://maven.apache.org/POM/4.0.0" \
        -d "/x:project/x:profiles/x:profile[x:id='create-pendant-web-ui']/x:build/x:plugins/x:plugin[x:artifactId='frontend-maven-plugin']/x:executions/x:execution[x:id='install node and npm']" \
        -d "/x:project/x:profiles/x:profile[x:id='create-pendant-web-ui']/x:build/x:plugins/x:plugin[x:artifactId='frontend-maven-plugin']/x:executions/x:execution[x:id='npm install']" \
        ugs-pendant/pom.xml

      # For some reason, there are a bunch of repeated
      #
      # [[1;31mERROR[m] Error resolving plugin org.apache.maven.plugins:maven-install-plugin
      # [[1;31mERROR[m] version can neither be null, empty nor blank
      # [[1;31mERROR[m] Error resolving plugin org.apache.maven.plugins:maven-deploy-plugin
      # [[1;31mERROR[m] version can neither be null, empty nor blank
      #
      # Manually specifying a static version means maven-install-plugin and maven-deploy-plugin are available
      # Those dependencies aren't specified in any of the pom.xmls, but apparently are needed somehow by maven itself
      # Likely related to https://nixos.org/manual/nixpkgs/stable#stable-maven-plugins
      mavenPluginVer=3.1.0
      xmlstarlet ed -L \
        -N x="http://maven.apache.org/POM/4.0.0" \
        -d "/x:project/x:build/x:plugins/x:plugin[x:artifactId='jacoco-maven-plugin']" \
        -s "/x:project/x:build/x:plugins" -t elem -n "plugin" -v "" \
        -s "/x:project/x:build/x:plugins/plugin[last()]" -t elem -n "groupId" -v "org.apache.maven.plugins" \
        -s "/x:project/x:build/x:plugins/plugin[last()]" -t elem -n "artifactId" -v "maven-install-plugin" \
        -s "/x:project/x:build/x:plugins/plugin[last()]" -t elem -n "version" -v "$mavenPluginVer" \
        -s "/x:project/x:build/x:plugins" -t elem -n "plugin" -v "" \
        -s "/x:project/x:build/x:plugins/plugin[last()]" -t elem -n "groupId" -v "org.apache.maven.plugins" \
        -s "/x:project/x:build/x:plugins/plugin[last()]" -t elem -n "artifactId" -v "maven-deploy-plugin" \
        -s "/x:project/x:build/x:plugins/plugin[last()]" -t elem -n "version" -v "$mavenPluginVer" \
        pom.xml
      
      # nbm-maven-plugin uses implicit <type>nbm</type>
      # However, this means go-offline never attempts to download the nbms
      # Explicitly add additional dependencies with <type>nbm</type> so that go-offline knows to download them
      find . -type f -name "pom.xml" | while read pom; do
        # Get all org.netbeans groupIds+artifactIds that don't already have a sibling <type>nbm</type> dependency
        deps=$(xmlstarlet sel \
          -N x="http://maven.apache.org/POM/4.0.0" \
          -t -m "/x:project/x:dependencies/x:dependency[
                    (x:groupId='org.netbeans.api' or x:groupId='org.netbeans.modules') and
                    not(x:type='nbm')
                  ]" \
          -v "concat(x:groupId, ':', x:artifactId, ':', x:version)" \
          -n "$pom" 2>/dev/null || true)
        [ -z "$deps" ] && continue
        echo "$deps" | while IFS=: read groupId artifactId version; do
            [ -z "$artifactId" ] && continue
            # Check a duplicate nbm-typed dep doesn't already exist
            existing=$(xmlstarlet sel \
              -N x="http://maven.apache.org/POM/4.0.0" \
              -t -m "/x:project/x:dependencies/x:dependency[
                        x:groupId='$groupId' and
                        x:artifactId='$artifactId' and
                        x:type='nbm'
                      ]" \
              -v "x:artifactId" "$pom" || true)
            if [ -z "$existing" ]; then
              echo "Patching $pom: Added nbm dependency for $groupId:$artifactId"
              xmlstarlet ed -L \
                -N x="http://maven.apache.org/POM/4.0.0" \
                -s "/x:project/x:dependencies" -t elem -n "dependency" -v "" \
                -s "/x:project/x:dependencies/dependency[last()]" -t elem -n "groupId" -v "$groupId" \
                -s "/x:project/x:dependencies/dependency[last()]" -t elem -n "artifactId" -v "$artifactId" \
                -s "/x:project/x:dependencies/dependency[last()]" -t elem -n "version" -v "$version" \
                -s "/x:project/x:dependencies/dependency[last()]" -t elem -n "type" -v "nbm" \
                -s "/x:project/x:dependencies/dependency[last()]" -t elem -n "scope" -v "provided" \
                "$pom"
            fi
        done
      done

      cat ugs-platform/ugs-platform-gcode-editor/pom.xml
      exit 1

      # Make node and npm runnable from where frontend-maven-plugin expects itself to have installed them
      mkdir -p ugs-pendant/src/main/webapp/node
      ln -s ${lib.getExe' pkgs.nodejs "node"} ${lib.getExe' pkgs.nodejs "npm"} ${pkgs.nodejs}/lib/node_modules ugs-pendant/src/main/webapp/node

      # Copy over resources we are no longer downloading with download-maven-plugin
      mkdir -p ugs-core/src/resources/grbl
      cp -r ${grbl-src}/doc/csv/. ugs-core/src/resources/grbl
    '';

    buildOffline = true;
    mvnFetchExtraArgs = {
      nativeBuildInputs = lib.remove pkgs.npmHooks.npmConfigHook nativeBuildInputs; # npmConfigHook throws a fit about missing npmDeps
      postBuild = ''
        # Fetches nbms, where de.qaware.maven:go-offline-maven-plugin fails to
        mvn $MAVEN_EXTRA_ARGS dependency:go-offline -Dmaven.repo.local=$out/.m2
        # Not present in any repository so can't use go-offline
        # org.netbeans.api:org-netbeans-modules-editor:nbm:RELEASE290

        # Never mind, we're doing it this way instead
        # find "''${netbeans-nbms}" -type f -name "*.nbm" -print0 | while IFS= read -r -d ''' nbm; do
        #   MODULE_NAME=$(basename "$nbm" .nbm)
        #   echo "Parsing $nbm"
        #   OPENIDE_MODULE=$(''${lib.getExe pkgs.unzip} -p "$nbm" Info/info.xml | sed -n 's/.*OpenIDE-Module="\([^"]*\)".*/\1/p')
        #   echo "Detected module string $OPENIDE_MODULE"
        #   GROUP_ID=$(echo "$OPENIDE_MODULE" | cut -d. -f1-3)
        #   echo "Detected group id $GROUP_ID"
        #   echo "Installing nbm $nbm with group ID $GROUP_ID and module name $MODULE_NAME"
        #   mvn $MAVEN_EXTRA_ARGS install:install-file -Dmaven.repo.local=$out/.m2 \
        #     -Dfile="$nbm" \
        #     -DgroupId=$GROUP_ID \
        #     -DartifactId="$MODULE_NAME" \
        #     -Dversion="RELEASE''${netbeans-nbms.version}0" \
        #     -Dpackaging=nbm-file || true
        # done
      '';
    };
    mvnParameters = pkgs.lib.escapeShellArgs [
      "-Dmaven.test.skip=true"
    ];
    mvnHash = lib.fakeHash;
    # mvnHash = "sha256-Ae6GKF8v2TvNbPjRsuMQDdcBBk5i8Z1p628UDwd/3uQ=";

    npmRoot = "ugs-pendant/src/main/webapp";
    npmDeps = pkgs.fetchNpmDeps {
      name = "${ugs-unstable.name}-npm-deps";
      src = ugs-unstable.src + "/ugs-pendant/src/main/webapp";
      hash = "sha256-71TWDkRCOPWHg/XAyj5fJ/ukEfE8MMGlInniCSclJoo=";
    };

    nativeBuildInputs = [
      pkgs.maven
      pkgs.xmlstarlet
      pkgs.makeBinaryWrapper
      pkgs.writableTmpDirAsHomeHook
      pkgs.nodejs
      pkgs.npmHooks.npmConfigHook
      pkgs.stripJavaArchivesHook
    ];
    buildInputs = [ pkgs.jre17_minimal ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share/ugs
      install -Dm644 ugs/target/ugs.jar $out/share/ugs

      makeWrapper ${lib.getExe pkgs.jre17_minimal} $out/bin/ugs \
        --add-flags "-jar $out/share/ugs/ugs.jar"

      runHook postInstall
    '';

    meta = {
      description = "Universal G-Code Sender";
      license = lib.licenses.gpl3;
      platforms = lib.platforms.all;
    };
  };
in
lib.mkIf (config.services.graphical-desktop.enable && !(config.optimizations.lean.enable)) {
  # environment.systemPackages = [
  #   ugs-unstable
  # ];
}
