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
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = if system == "x86_64-linux" then [ nixgl.overlay ] else [ ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        # Override the existing tic-80 package to inject the Pro CMake flag
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
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            gmp
            guile_3_0-wrapped
            raylib
          ];
        };
      }
    );
}
