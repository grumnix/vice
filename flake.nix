{
  description = "Commodore 64, 128 and other emulators";

  inputs = rec {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages = flake-utils.lib.flattenTree rec {
          default = vice-sdl2;

          vice-base = rec {
            version = "3.6";
            src = pkgs.fetchsvn {
              url = "svn://svn.code.sf.net/p/vice-emu/code/trunk/vice/";
              rev = "41473";
              sha256 = "sha256-rMBXBA0ZzxC6Evlf2hZk+wLn5PzIOd7tLMm/uEbGzxU=";
            };
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
            ];
          };

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

            postInstall = ''
              for i in $out/bin/*; do
                mv -v "$i" "$i.gtk3"
                ln -s "$i.gtk3" "$i"
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
                ln -s "$i.sdl2" "$i"
              done
              mkdir -p $out/share/applications
              cp ${desktopItem}/share/applications/* $out/share/applications
            '';

            buildInputs = vice-base.buildInputs ++ [
              pkgs.SDL2
              pkgs.SDL2_image
            ];
          });
        };
      }
    );
}
