{ pkgs, username, dotfilesPath, ... }:
{
  wsl.enable = true;
  wsl.defaultUser = username;

  networking.hostName = "sgra";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "24.11";

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };

  security.sudo.wheelNeedsPassword = false;

  programs.zsh.enable = true;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = { inherit username dotfilesPath; };
  home-manager.users.${username} = {
    imports = [ ../profiles/wsl.nix ];
  };
}
