{ pkgs }:

with pkgs;

# Nix based development environment for Flutter development.
# Using https://github.com/numtide/devshell
devshell.mkShell {
  name = "memex-dev";
  motd = ''
    🛠️  Memex development environment.
  '';
  # Change the local CoC settings to point to the Flutter SDK.
  devshell.startup.vimFlutter.text = ''
    mkdir -p .vim;
    echo "{ \"flutter.sdk.searchPaths\": [\"${flutter}\"] }" > .vim/coc-settings.json;
  '';
  env = [
    {
      name = "DART_SDK_HOME";
      value = "${flutter}";
    }
    {
      # Make pkg-config find gtk-layer-shell.
      # The .dev package contains the .pc file.
      # However, the .pc file in the .dev package points to the .so file in the
      # non-.dev package. So we need to add the .lib package to the LD_LIBRARY_PATH.
      name = "PKG_CONFIG_PATH";
      value = "${gtk-layer-shell.dev}/lib/pkgconfig";
    }
    {
      name = "LD_LIBRARY_PATH";
      value = "${gtk-layer-shell}/lib";
    }
  ];
  packages = [
    cloc
    at-spi2-core.dev
    clang
    cmake
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
    pcre2
    pkg-config
    util-linux.dev
    xorg.libXdmcp
    xorg.libXtst
  ];
}
