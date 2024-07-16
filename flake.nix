# See: https://fasterthanli.me/series/building-a-rust-service-with-nix/part-10
{
  description = "Idris 2 dev shell (demo)";

  inputs = {
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
    nixpkgs.url = "github:NixOS/nixpkgs/24.05";
    systems = {
      url = "./nix/systems.nix";
      flake = false;
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    idr2nix = {
      url = "git+https://git.sr.ht/~thatonelutenist/idr2nix?ref=trunk";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    idris2 = {
      url = "./nix/idris2";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        idr2nix.follows = "idr2nix";
      };
    };
    pack = {
      url = "./nix/pack";
      flake = false;
    };
    idris2-lsp = {
      url = "./nix/idris2-lsp";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, idr2nix, idris2, pack, idris2-lsp, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        sources = builtins.fromJSON (builtins.readFile ./pack.json);
        pkgs = import nixpkgs {
          inherit system;
          overlays = [];
        };
        pack-drv = import pack {
          inherit system;
          inherit idr2nix;
          inherit idris2;
          inherit pkgs;
        };
        idris2-lsp-drv = import idris2-lsp {
          inherit system;
          inherit idr2nix;
          inherit idris2;
          inherit pkgs;
        };
      in {
        packages.pack = pack-drv;
        packages.idris2-lsp = idris2-lsp-drv;

        # See: https://github.com/numtide/flake-utils?tab=readme-ov-file#example
        # See: $ nix flake show "git+https://git.sr.ht/~thatonelutenist/idr2nix?ref=trunk
        apps.idr2nix = flake-utils.lib.mkApp {
          drv = idr2nix.defaultPackage.${system};
        };

        apps.idris2 = flake-utils.lib.mkApp {
          drv = idris2.packages.${system}.idris2;
        };

        apps.pack = flake-utils.lib.mkApp {
          drv = pack-drv;
        };

        apps.idris2-lsp = flake-utils.lib.mkApp {
          drv = idris2-lsp-drv;
        };

        devShells.default = idr2nix.idris.mkDevShell {
          inherit system;
          inherit sources;
          extraNativeDeps = pkgs: with pkgs; [
            rlwrap pack-drv idris2-lsp-drv
          ];
        };
      }
    );
}
