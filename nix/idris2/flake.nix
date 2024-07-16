{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/24.05";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    idr2nix = {
      url = "git+https://git.sr.ht/~thatonelutenist/idr2nix?ref=trunk";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { self, nixpkgs, flake-utils, idr2nix }:
    let
      sources = {
        idris2 = builtins.fromJSON (builtins.readFile ./version.json);
      };
    in flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [];
        };

        idris2Pkg = idr2nix.idris.mkIdris { inherit system sources; };

        # It is required for idris2api "virtual package"
        # See: https://idris2.readthedocs.io/en/latest/backends/custom.html#getting-started
        # See: https://git.sr.ht/~thatonelutenist/idr2nix/tree/trunk/item/flake.nix#L76
        idris2Prefix = (idr2nix.idris.mkIdrisPrefix {
          inherit system;
          sources = sources // {
            # We do not need any additional prefix to build idris2api
            sources = {};
            sorted = [];
          };
          idris2api = true;
        }).overrideAttrs (oldAttrs: {
          buildInputs = [ idris2Pkg ];
        });
      in {
        packages.idris2 = pkgs.symlinkJoin {
          name = "idris2-with-api";
          paths = [ idris2Pkg idris2Prefix ];
        };
      }
    );
}
