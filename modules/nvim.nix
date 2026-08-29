{ config, dotfilesPath, ... }:
{
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink (dotfilesPath "config/nvim");
}
