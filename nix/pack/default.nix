{ system, pkgs, idris2, idr2nix }:
let
  ipkg = "pack.ipkg";
  sources = {
    idris2 = {};
    sources = builtins.fromJSON (builtins.readFile ./sources.json);
    sorted = builtins.fromJSON (builtins.readFile ./sorted.json);
  };
  idris2Pkg = idris2.packages.${system}.idris2;
  idris2Prefix = (idr2nix.idris.mkIdrisPrefix {
    inherit system;
    inherit sources;
    idris2api = false;
  }).overrideAttrs (oldAttrs: {
    buildInputs = [ idris2Pkg ];
  });
  fullPrefix = pkgs.symlinkJoin {
    name = "idris-full-prefix";
    paths = [ idris2Pkg idris2Prefix ];
  };

in pkgs.stdenv.mkDerivation (rec {
  name = "pack";
  src = pkgs.fetchgit (builtins.fromJSON (builtins.readFile ./version.json));
  nativeBuildInputs = [ idris2Pkg pkgs.makeWrapper ]
    ++ (with pkgs; lib.optional stdenv.isLinux [ pkgs.autoPatchelfHook ]);
  buildInputs = [ fullPrefix ];
  buildPhase = ''
    export IDRIS2_PREFIX=${fullPrefix}

    set -e
    env

    idris2 --build ${ipkg}
  '';
  installPhase = let
    platformLdLibraryPath = if pkgs.stdenv.isDarwin then
      "DYLD_LIBRARY_PATH"
    else if pkgs.stdenv.isLinux then
      "LD_LIBRARY_PATH"
    else
      throw "unsupported platform";
    binPath = buildInputs ++ [pkgs.coreutils] ++ (if pkgs.stdenv.isDarwin then [pkgs.zsh] else []);
  in ''
    mkdir -p $out
    cp -r ./build/exec $out/bin
    wrapProgram "$out/bin/${name}" --set ${platformLdLibraryPath} "${
      pkgs.lib.makeLibraryPath buildInputs
    }" --set PATH "${pkgs.lib.makeBinPath binPath}"
  '';
})
