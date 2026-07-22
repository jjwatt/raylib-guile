{
  pkgs ? import <nixpkgs> { },
}:

pkgs.stdenv.mkDerivation {
  pname = "raylib-guile";
  version = pkgs.lib.trim (builtins.readFile ./VERSION);
  src = ./.;

  nativeBuildInputs = [
    pkgs.pkg-config
    pkgs.guile_3_0
  ];

  buildInputs = [
    pkgs.guile_3_0
    pkgs.raylib
  ];

  installFlags = [
    "GUILE_EXTENSIONDIR=$(out)/lib/guile/3.0/extensions"
    "GUILE_SITEDIR=$(out)/share/guile/site/3.0"
  ];

  meta = with pkgs.lib; {
    description = "GNU Guile 3.0 bindings for raylib";
    homepage = "https://github.com/jjwatt/raylib-guile";
    license = licenses.zlib;
    platforms = platforms.all;
  };
}
