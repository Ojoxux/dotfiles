{ config, dotfilesPath, ... }:
{
  home.file."Library/Application Support/Code/User/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink (dotfilesPath "config/vscode/settings.json");
}
