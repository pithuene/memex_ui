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
    nix-filter.url = "github:numtide/nix-filter";
  };

  outputs = { self, nixpkgs, flutter-nix, devshell, flake-utils, nix-filter }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = false;
          overlays = [
            devshell.overlays.default
            # If the flutter.nix flake ever creates problems, remove
            # this overlay and the nixpkgs version will be used again.
            flutter-nix.overlays.default
          ];
        };
        buildMemexApplication = { name, nativeBuildInputs ? [ ] }:
          pkgs.flutter.buildFlutterApplication {
            pname = name;
            version = "git";
        
            src = nix-filter.lib {
              root = ./packages;
              # This filter limits the source to the package and its dependencies.
              # This way, Nix will know not to rebuild packages that did not change.
              include = [
                "${name}"
                "memex_ui"
                "memex_data"
                "appflowy-editor"
              ];
            };

            pubspecLock = pkgs.lib.importJSON ./packages/${name}/pubspec.lock.json;

            sourceRoot = "source/${name}";

            nativeBuildInputs = nativeBuildInputs;
          };
        memex_activity_monitor = buildMemexApplication {
          name = "memex_activity_monitor";
        };
        #memex_editor = buildMemexApplication {
        #  name = "memex_editor";
        #};
        memex_ui_examples = buildMemexApplication {
          name = "memex_ui_examples";
        };
        memex_music = buildMemexApplication {
          name = "memex_music";
        };
        memex_filepicker = buildMemexApplication {
          name = "memex_filepicker";
        };
        memex_bar = buildMemexApplication {
          name = "memex_bar";
          nativeBuildInputs = with pkgs; [
            pkg-config
            gtk-layer-shell.dev
          ];
        };
      in
      {
        packages.activity_monitor = memex_activity_monitor;
        # packages.editor = memex_editor;
        packages.ui_examples = memex_ui_examples;
        packages.music = memex_music;
        packages.filepicker = memex_filepicker;
        packages.bar = memex_bar;
        # The default package contains all applications.
        packages.default = pkgs.stdenv.mkDerivation {
          name = "memex";
          buildInputs = [
            memex_activity_monitor
            #memex_editor
            memex_ui_examples
            memex_music
            memex_filepicker
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
