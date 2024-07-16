# See: https://evanrelf.com/building-x86-64-packages-with-nix-on-apple-silicon/
# See: https://github.com/input-output-hk/iogx/blob/main/doc/nix-setup-guide.md#notes-for-apple-users
{ system ? (if builtins.currentSystem == "aarch64-darwin"
            then "x86_64-darwin"
            else builtins.currentSystem)
, ...
}: (import
  (
    let lock = builtins.fromJSON (builtins.readFile ./flake.lock); in
    fetchTarball {
      url = lock.nodes.flake-compat.locked.url or "https://github.com/edolstra/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
      sha256 = lock.nodes.flake-compat.locked.narHash;
    }
  )
  { src = ./.; inherit system; }
).shellNix
