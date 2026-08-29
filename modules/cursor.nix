{ config, dotfilesPath, ... }:
{
  home.file = {
    "Library/Application Support/Cursor/User/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink (dotfilesPath "config/cursor/settings.json");
    "Library/Application Support/Cursor/User/keybindings.json".source =
      config.lib.file.mkOutOfStoreSymlink (dotfilesPath "config/cursor/keybindings.json");

    ".local/bin/cursor-sync-extensions" = {
      source = dotfilesPath "config/cursor/cursor-sync-extensions.sh";
      executable = true;
    };
    ".local/bin/cursor-export-extensions" = {
      source = dotfilesPath "config/cursor/cursor-export-extensions.sh";
      executable = true;
    };
  };

  xdg.configFile."cursor/extensions.txt" = { source = dotfilesPath "config/cursor/extensions.txt"; };
}
