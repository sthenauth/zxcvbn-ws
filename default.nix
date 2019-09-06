{ pkgs ? import <nixpkgs> { }
}:

let
  zxcvbn = {
    url = "https://code.devalot.com/sthenauth/zxcvbn-hs.git";
    rev = "e60d1b0493b6839ba4d7fe170afcf86d19031bb8";
  };

  # Helpful if you want to override any Haskell packages:
  overrides = self: super: with pkgs.haskell.lib; {
    zxcvbn-hs = import "${fetchGit zxcvbn}/default.nix" {inherit pkgs;};
  };

  # Apply the overrides from above:
  haskell = pkgs.haskellPackages.override (orig: {
    overrides = pkgs.lib.composeExtensions
      (orig.overrides or (_: _: {})) overrides; });

in haskell.callPackage ./zxcvbn-ws.nix { }
