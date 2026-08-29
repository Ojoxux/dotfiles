{ config, dotfilesPath, ... }:
{
  xdg.configFile = {
    "ghostty/config".source = config.lib.file.mkOutOfStoreSymlink (dotfilesPath "config/ghostty/config");
    "ghostty/themes" = { source = dotfilesPath "config/ghostty/themes"; recursive = true; };
  };
}
