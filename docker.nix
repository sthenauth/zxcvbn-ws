{ pkgs ? import <nixpkgs> { }
}:

let
  zxcvbn-ws = with pkgs.haskell.lib;
    justStaticExecutables
      (import ./default.nix { inherit pkgs; });

in pkgs.dockerTools.buildImage {
  name = "zxcvbn-ws";
  tag  = "latest";

  config = {
    Cmd = [ "${zxcvbn-ws}/bin/zxcvbn-ws" ];
  };
}
