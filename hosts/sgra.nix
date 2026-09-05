{ pkgs, username, dotfilesPath, vitePlus, ... }:
{
  wsl.enable = true;
  wsl.defaultUser = username;

  networking.hostName = "sgra";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.substituters = [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    (final: prev: {
      fetchurl = args:
        let
          m =
            if args ? url && builtins.isString args.url
            then builtins.match "https://crates\\.io/api/v1/crates/([^/]+)/([^/]+)/download" args.url
            else null;
        in
        if m == null
        then prev.fetchurl args
        else prev.fetchurl (args // {
          url = "https://static.crates.io/crates/${builtins.elemAt m 0}/${builtins.elemAt m 0}-${builtins.elemAt m 1}.crate";
        });
    })
  ];

  system.stateVersion = "24.11";

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };

  security.sudo.wheelNeedsPassword = false;

  programs.zsh.enable = true;

  programs.nix-ld.enable = true;

  programs.git = {
    enable = true;
    config.safe.directory = "*";
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = { inherit username dotfilesPath vitePlus; };
  home-manager.users.${username} = {
    imports = [ ../profiles/wsl.nix ];
  };
}
