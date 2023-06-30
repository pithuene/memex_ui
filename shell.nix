with (import <nixpkgs> {});

mkShell {
  buildInputs = [
    cloc
    at-spi2-core.dev
    clang
    cmake
    dart
    pandoc
    dbus.dev
    flutter37
    gtk3
    libdatrie
    libepoxy.dev
    libselinux
    libsepol
    libthai
    libxkbcommon
    ninja
    pcre2
    pkg-config
    util-linux.dev
    xorg.libXdmcp
    xorg.libXtst
  ];
  shellHook = ''
    export LD_LIBRARY_PATH=${libepoxy}/lib:${pandoc}/lib
  '';
}
