{
  description = "Memex Applications";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    # Use https://github.com/maximoffua/flutter.nix because the nixpkgs version is outdated
    flutter-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:maximoffua/flutter.nix";
    };
    devshell = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/devshell";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flutter-nix, devshell, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = false;
          overlays = [
            devshell.overlays.default
            # If the flutter.nix flake ever creates problems, just remove
            # this overlay and the nixpkgs version will be used again.
            flutter-nix.overlays.default
          ];
        };
        buildMemexApplication = { name, vendorHash, nativeBuildInputs ? [ ] }:
          pkgs.flutter.buildFlutterApplication {
            pname = name;
            version = "git";

            src = nixpkgs.lib.cleanSource ./packages;

            # Generated with the following command, which is documented nowhere:
            # flutter pub deps --json | jq '.packages' > deps.json
            depsListFile = ./packages/${name}/deps.json;
            autoDepsList = false;
            pubspecLock = pkgs.lib.importJSON ./packages/${name}/pubspec.lock.json;

            # Copy the sources into the build directory.
            # As I understand it, this is necessary because a source fetched using something like
            # fetchFromGitHub is expected, but the default unpacking script doesn't work with a local directory.
            unpackCmd = ''
              runHook preUnpack;
              
              mkdir -p ./source;
              # Copy all packages into the source directory.
              # This is necessary in case of dependencies between them.
              cp -r $src/* ./source/;
            
              runHook postUnpack;
            '';

            sourceRoot = "source/${name}";

            nativeBuildInputs = nativeBuildInputs;

            # A hash based on the dependency used by the Flutter build.
            vendorHash = vendorHash;
          };
        memex_activity_monitor = buildMemexApplication {
          name = "memex_activity_monitor";
          vendorHash = "sha256-bcPROCdzUhtMIgnbPYRLlVZQCLX1WZjuJjroxB6sit4=";
        };
        #memex_editor = buildMemexApplication {
        #  name = "memex_editor";
        #  vendorHash = "sha256-Ze0ewiTqiT/1grg7KaIXcMGhi3SSYuH785R4JAb8Os0=";
        #};
        memex_ui_examples = buildMemexApplication {
          name = "memex_ui_examples";
          vendorHash = "sha256-Qn3VQXdXNKO9oEf6ixutpJON6dhJdIbqVKLTw351DQs=";
        };
        memex_bar = buildMemexApplication {
          name = "memex_bar";
          vendorHash = "sha256-NXZHC2/lN1f51TFeOy7Fm73QnGj8cy+FBhuyTrrMel4=";
          nativeBuildInputs = [
            pkgs.pkg-config
            pkgs.gtk-layer-shell.dev
          ];
        };
      in
      {
        packages.activity_monitor = memex_activity_monitor;
        # packages.editor = memex_editor;
        packages.ui_examples = memex_ui_examples;
        packages.bar = memex_bar;
        # The default package contains all applications.
        packages.default = pkgs.stdenv.mkDerivation {
          name = "memex";
          buildInputs = [
            memex_activity_monitor
            #memex_editor
            memex_ui_examples
            memex_bar
          ];
          phases = [ "installPhase" ];
          installPhase = ''
            mkdir -p $out/bin;
            mkdir -p $out/app/lib;
            mkdir -p $out/app/data/flutter_assets/fonts;
            mkdir -p $out/app/data/flutter_assets/packages;
            mkdir -p $out/app/data/flutter_assets/shaders;

            # Loop over all applications and copy their files into the output directory.
            for app in $buildInputs; do
              cp -rn $app/bin/* $out/bin/ || true;
              cp -rn $app/app/lib/* $out/app/lib || true;
              cp -rn $app/app/data/flutter_assets/fonts/* $out/app/data/flutter_assets/fonts/ || true;
              cp -rn $app/app/data/flutter_assets/packages/* $out/app/data/flutter_assets/packages/ || true;
              cp -rn $app/app/data/flutter_assets/shaders/* $out/app/data/flutter_assets/shaders/ || true;
            done
          '';
        };
        devShell = import ./devshell.nix { inherit pkgs; };
      }
    );
}
