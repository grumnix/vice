{
  description = "Commodore 64, 128 and other emulators";

  inputs = rec {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";

    vice_src.url = "https://unlimited.dl.sourceforge.net/project/vice-emu/releases/vice-3.8.tar.gz";
    vice_src.flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, vice_src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        vice-base = rec {
          version = "3.8";
          src = vice_src;

          enableParallelBuilding = true;
          # dontDisableStatic = true;  # FIXME: is this necessary?!

          postPatch = ''
              patchShebangs ./src/arch/gtk3/novte/box_drawing_generate.sh
            '';

          configureFlags = [
            "--enable-x64"  # old faster x64 emulator
            "--disable-pdf-docs"
          ];

          preBuild = ''
              for i in src/resid src/resid-dtv
              do
                 mkdir -pv $i/src
                 ln -sv ../../wrap-u-ar.sh $i/src
              done
            '';

          nativeBuildInputs = with pkgs; [
            autoreconfHook
            bison
            dos2unix
            file
            flex
            pkg-config
            perl
          ];

          buildInputs = with pkgs; [
            alsa-lib
            giflib
            libGL
            libGLU
            libjpeg
            libpng
            readline
            pulseaudio
            xa
            libevdev
            curl
          ];
        };
      in {
        packages = rec {
          default = vice-sdl2;

          vice-gtk3 = pkgs.stdenv.mkDerivation (vice-base // rec {
            pname = "vice-gtk3";
            configureFlags = vice-base.configureFlags ++ [
              "--enable-native-gtk3ui"
              "--enable-desktop-files"
            ];

            preConfigure = ''
                substituteInPlace configure.ac \
                   --replace "AC_INIT([vice]" "AC_INIT([${pname}]"
                ./autogen.sh
            '';

            preBuild = ''
              substituteInPlace src/Makefile \
                --replace '-lGLEW -lGLU -lOpenGL' \
                          '-lGLEW -lGLU -lOpenGL -lGLX'
            '';

            postInstall = ''
              for i in $out/bin/*; do
                mv -v "$i" "$i.gtk3"
              done
            '';

            nativeBuildInputs = vice-base.nativeBuildInputs ++ [
              pkgs.xdg-utils
            ];

            buildInputs = vice-base.buildInputs ++ [
              pkgs.gtk3
              pkgs.glew
            ];
          });

          vice-sdl2 = pkgs.stdenv.mkDerivation (vice-base // rec {
            pname = "vice-sdl2";

            configureFlags = vice-base.configureFlags ++ [
              "--enable-sdl2ui"
            ];

            desktopItem = pkgs.makeDesktopItem {
               name = "vice";
               exec = "x64";
               comment = "Commodore 64 emulator";
               desktopName = "VICE";
               genericName = "Commodore 64 emulator";
               categories = [ "Emulator" ];
            };

            preConfigure = ''
              substituteInPlace configure.ac \
                 --replace "AC_INIT([vice]" "AC_INIT([${pname}]"
              ./autogen.sh
            '';

            postInstall = ''
              for i in $out/bin/*; do
                mv -v "$i" "$i.sdl2"
              done
              mkdir -p $out/share/applications
              cp ${desktopItem}/share/applications/* $out/share/applications
            '';

            buildInputs = vice-base.buildInputs ++ [
              pkgs.SDL2
              pkgs.SDL2_image
            ];
          });

          vice-sdl2-as-default = pkgs.runCommand "vice-sdl2-as-defautl" {} ''
            mkdir -p $out/bin
            for i in ${vice-sdl2}/bin/*; do
              ln -sv "$i" "$out/bin/$(basename ''${i%.sdl2})"
            done
          '';

          vice-gtk3-as-default = pkgs.runCommand "vice-gtk3-as-default" {} ''
            mkdir -p $out/bin
            for i in ${vice-gtk3}/bin/*; do
              ln -sv "$i" "$out/bin/$(basename ''${i%.gtk3})"
            done
          '';
        };
      }
    );
}
