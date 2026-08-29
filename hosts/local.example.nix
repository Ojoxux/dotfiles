{ username, dotfilesPath, vitePlus, ... }:
{
  networking.hostName = "changeme";
  users.users.${username}.home = "/Users/${username}";

  imports = [ ../modules/darwin.nix ];

  # aerospaceCrackGap.enable = true;
  # aerospaceCrackGap.width = 100;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = { inherit username dotfilesPath vitePlus; };
  home-manager.users.${username} = {
    imports = [
      ../profiles/base.nix
    ];
  };
}
