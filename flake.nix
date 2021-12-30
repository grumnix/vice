{
  description = "Commodore 64, 128 and other emulators";

  inputs = rec {
    nixpkgs.url = "github:nixos/nixpkgs";
    nix.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nix, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in rec {
        packages = flake-utils.lib.flattenTree rec {
          vice = pkgs.stdenv.mkDerivation rec {
            pname = "vice";
            version = "3.6";
            # src = pkgs.fetchurl {
            #   url = "mirror://sourceforge/vice-emu/vice-${version}.tar.gz";
            #   sha256 = "sha256-Zb/lXM5ifbm1oKx4dqkMCH6f6G6fVRfoCURsQGSi0/0=";
            # };
            # patches = "${self}/vice-sdl2_image-fix.diff";
            src = pkgs.fetchsvn {
              url = "svn://svn.code.sf.net/p/vice-emu/code/trunk/vice/";
              rev = "41441";
              sha256 = "sha256-SNgeyBm5rpiS/CFabKFoh51truWIhS/FcKkM5P0xiUw=";
            };
            dontDisableStatic = true;
            preConfigure = "./autogen.sh";
            configureFlags = [
              "--enable-x64"  # old faster x64 emulator
              "--enable-fullscreen"
              "--enable-sdl2ui"
              "--disable-pdf-docs"
            ];

            desktopItem = pkgs.makeDesktopItem {
               name = "vice";
               exec = "x64";
               comment = "Commodore 64 emulator";
               desktopName = "VICE";
               genericName = "Commodore 64 emulator";
               categories = "Emulator;";
            };

            preBuild = ''
              for i in src/resid src/resid-dtv
              do
                 mkdir -pv $i/src
                 ln -sv ../../wrap-u-ar.sh $i/src
              done
            '';

            postInstall = ''
              mkdir -p $out/share/applications
              cp ${desktopItem}/share/applications/* $out/share/applications
            '';

            nativeBuildInputs = with pkgs; [
              autoreconfHook
              bison
              dos2unix
              file
              flex
              pkg-config
            ];

            buildInputs = with pkgs; [
              alsa-lib
              giflib
              gtk2
              libGL
              libGLU
              # libXaw
              libjpeg
              libpng
              perl
              readline
              pulseaudio
              SDL2
              SDL2_image
              xa
            ];
          };
        };
        defaultPackage = packages.vice;
      }
    );
}
