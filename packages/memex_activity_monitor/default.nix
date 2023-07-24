{ lib
, flutter
, python3
, fetchFromGitHub
, stdenv
, pcre2
, gnome
, makeWrapper
, removeReferencesTo
, at-spi2-core
, clang
, cmake
, dart
, dbus
, gtk3
, libdatrie
, libepoxy
, libselinux
, libsepol
, libthai
, libxkbcommon
, ninja
, pcre
, pkg-config
, util-linux
, xorg
}:
let
  vendorHashes = {
    x86_64-linux = "sha256-MuPKfQMY+BCkFqhIYmOk+yrsMz+JWnOTX+73rvIbg3c=";
  };
in
flutter.mkFlutterApp rec {
  pname = "flutter_activity_monitor";
  version = "0.0.0";

  src = lib.cleanSource ./.;


  flutterExtraFetchCommands = ''
    touch .packages .flutter-plugins .flutter-plugins-dependencies
  '';

  vendorHash = vendorHashes.${stdenv.system};

  preInstall = ''
    # Make sure we have permission to delete things CMake has copied in to our build directory from elsewhere.
    chmod -R +w build
  '';

  nativeBuildInputs = [
    cmake
    makeWrapper
    removeReferencesTo
  ];

  buildInputs = [
    at-spi2-core.dev
    clang
    cmake
    dart
    dbus.dev
    flutter
    gtk3
    libdatrie
    libepoxy.dev
    libselinux
    libsepol
    libthai
    libxkbcommon
    ninja
    pcre
    pkg-config
    util-linux.dev
    xorg.libXdmcp
    xorg.libXtst
  ];

  meta = with lib; {
    description = "Activity Monitor";
    platforms = builtins.attrNames vendorHashes;
  };
}

