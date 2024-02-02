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
            # If the flutter.nix flake ever creates problems, remove
            # this overlay and the nixpkgs version will be used again.
            flutter-nix.overlays.default
          ];
        };
        buildMemexApplication = { name, nativeBuildInputs ? [ ] }:
          pkgs.flutter.buildFlutterApplication {
            pname = name;
            version = "git";

            src = nixpkgs.lib.cleanSource ./packages;

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
        memex_bar = buildMemexApplication {
          name = "memex_bar";
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
