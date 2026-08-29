{ pkgs, ... }:
{
  imports = [ ./base.nix ];

  home.packages = with pkgs; [
    cloudflared
    awscli2
    supabase-cli
  ];
}
