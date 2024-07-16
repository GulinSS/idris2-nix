.PHONY: idr2nix-init \
	idr2nix-update-pack \
	shell-dev

# See: https://stackoverflow.com/a/12099167
# Supports only x86 LINUX or OSX. OSX Rosetta2 is required for ARM
# See: https://evanrelf.com/building-x86-64-packages-with-nix-on-apple-silicon/
# See: https://github.com/input-output-hk/iogx/blob/main/doc/nix-setup-guide.md#notes-for-apple-users
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	NIX_SYSTEM := "x86_64-linux"
endif
ifeq ($(UNAME_S),Darwin)
	NIX_SYSTEM := "x86_64-darwin"
endif

idr2nix-init:
	nix registry add idr2nix 'git+https://git.sr.ht/~thatonelutenist/idr2nix?ref=trunk'
	nix run .#idr2nix --system "$(NIX_SYSTEM)" -- init

idr2nix-update-pack:
	nix registry add idr2nix 'git+https://git.sr.ht/~thatonelutenist/idr2nix?ref=trunk'
	nix run .#idr2nix --system "$(NIX_SYSTEM)" -- update-pack

pack-info:
	nix run .#pack --system "$(NIX_SYSTEM)" -- info

idris2-lsp:
	nix run .#idris2-lsp --system "$(NIX_SYSTEM)"

shell-dev:
	nix develop --system "$(NIX_SYSTEM)" --impure

shell-dev-build:
	cd src/hello && idris2 helloIdris.idr -o helloIdris
	src/hello/build/exec/helloIdris

shell-dev-repl:
	IDRIS2_PREFIX=/nix/store/q4qmm5ygxq4x1rlszxvcl61dk92qwajj-idris2-0.7.0 idris2-lsp --version

flake-info:
	nix flake metadata
	nix flake show --all-systems --allow-import-from-derivation
