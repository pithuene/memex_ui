{
  description = "Memex Applications";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    devshell.url = "github:numtide/devshell";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, devshell, flake-utils }:
    {
      overlay = final: prev: {
        inherit (self.packages.${final.system});
      };
    }
    //
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = false;
          overlays = [
            devshell.overlays.default
            self.overlay
          ];
        };
        buildMemexApplication = { name, vendorHash, nativeBuildInputs ? [ ] }:
          pkgs.flutter.buildFlutterApplication {
            pname = name;
            version = "git";

            src = builtins.path {
              path = ./packages;
              name = "memex";
            };

            # Generated with the following command, which is documented nowhere:
            # flutter pub deps --json | jq '.packages' > deps.json
            depsListFile = ./packages/${name}/deps.json;
            autoDepsList = false;
            pubspecLockFile = ./packages/${name}/pubspec.lock;

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

            vendorHash = vendorHash;
          };
      in
      {
        packages = {
          memex_activity_monitor = buildMemexApplication {
            name = "memex_activity_monitor";
            vendorHash = "sha256-bcPROCdzUhtMIgnbPYRLlVZQCLX1WZjuJjroxB6sit4=";
          };
          memex_editor = buildMemexApplication {
            name = "memex_editor";
            vendorHash = "sha256-Ze0ewiTqiT/1grg7KaIXcMGhi3SSYuH785R4JAb8Os0=";
          };
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
        };
        devShell = import ./devshell.nix { inherit pkgs; };
      }
    );
}
