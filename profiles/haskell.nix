{ pkgs, ... }:
{
  imports = [ ./base.nix ];

  home.packages = with pkgs; [
    ghc
    cabal-install
    haskell-language-server
  ];
}
