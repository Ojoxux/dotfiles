{ config, dotfilesPath, ... }:
{
  xdg.configFile."zed/themes".source =
    config.lib.file.mkOutOfStoreSymlink (dotfilesPath "config/zed/themes");

  xdg.configFile."zed/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink (dotfilesPath "config/zed/settings.json");

  xdg.configFile."zed/keymap.json".source =
    config.lib.file.mkOutOfStoreSymlink (dotfilesPath "config/zed/keymap.json");
}
