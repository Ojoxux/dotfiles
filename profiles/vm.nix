{ pkgs, ... }:
{
  imports = [ ./base.nix ];

  home.packages = with pkgs; [
    utm
    qemu
    e2fsprogs
  ];
}
