{
  description = "A multiplatform Guile 3.0 and raylib environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixgl.url = "github:nix-community/nixGL";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      nixgl,
    }:
    let
      mkRaylibGuile = pkgs: pkgs.callPackage ./default.nix { };

      gcOverlay = final: prev:
        if prev.stdenv.isDarwin then {
          boehmgc = prev.boehmgc.overrideAttrs (oldAttrs: {
            configureFlags = (oldAttrs.configureFlags or [ ]) ++ [ "--enable-large-config" ];
            NIX_CFLAGS_COMPILE = (oldAttrs.NIX_CFLAGS_COMPILE or "") + " -DLARGE_CONFIG";
          });
          guile_3_0 = prev.guile_3_0.override {
            boehmgc = final.boehmgc;
          };
        } else { };

      overlay = final: prev: (gcOverlay final prev) // {
        raylib-guile = mkRaylibGuile final;
      };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ gcOverlay ]
          ++ (if system == "x86_64-linux" then [ nixgl.overlay ] else [ ]);
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        raylib-guile = mkRaylibGuile pkgs;

        guile_3_0-wrapped = if system == "x86_64-linux" then
          pkgs.writeShellScriptBin "guile" ''
            if [ -e /etc/NIXOS ]; then
                exec ${pkgs.guile_3_0}/bin/guile "$@"
            else
                # Non-NixOS x86_64 Linux
                exec ${pkgs.nixgl.nixGLMesa}/bin/nixGLMesa ${pkgs.guile_3_0}/bin/guile "$@"
            fi
            ''
        else
          pkgs.guile_3_0;
      in
      {
        packages = {
          default = raylib-guile;
          raylib-guile = raylib-guile;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            pkg-config
            gmp
            guile_3_0-wrapped
            raylib
            raylib-guile
          ];
          shellHook = ''
            export GUILE_LOAD_PATH="$PWD:$GUILE_LOAD_PATH"
            export GUILE_EXTENSIONS_PATH="$PWD:$GUILE_EXTENSIONS_PATH"
          '';
        };
      }
    ) // {
      overlays.default = overlay;
    };
}
