{ username, dotfilesPath, vitePlus, ... }:
{
  networking.hostName = "powehi";
  users.users.${username}.home = "/Users/${username}";

  imports = [ ../modules/darwin.nix ];

  homebrew.taps = [ "crmne/tap" ];
  homebrew.casks = [
    "google-chrome"
    "orbstack"
    "1password"
    "wireshark-app"
    "crmne/tap/fastpotify"
  ];

  aerospaceCrackGap.enable = true;
  aerospaceCrackGap.width = 100;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = { inherit username dotfilesPath vitePlus; };
  home-manager.users.${username} = {
    imports = [
      ../profiles/base.nix
      ../profiles/powehi-only.nix
      ../profiles/haskell.nix
      ../profiles/php.nix
      ../profiles/python.nix
      ../profiles/node.nix
      ../profiles/rust.nix
      ../profiles/cloud.nix
      ../profiles/vm.nix
    ];
  };
}
