# WezTerm.exe は Windows ホーム (%USERPROFILE%\.wezterm.lua) しか読まないので switch のたびにコピーする
{ lib, dotfilesPath, ... }:
let
  src = dotfilesPath "config/wezterm/wezterm.lua";
in
{
  home.activation.weztermConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    up="$(/mnt/c/Windows/System32/cmd.exe /C 'echo %USERPROFILE%' 2>/dev/null || true)"
    up="''${up%$'\r'}"
    if [ -z "$up" ]; then
      warnEcho "wezterm: %USERPROFILE% を取得できずスキップ"
    else
      up="''${up//\\//}"
      drive="''${up%%:*}"
      win_home="/mnt/''${drive,,}''${up#*:}"
      run cp -f ${lib.escapeShellArg src} "$win_home/.wezterm.lua"
    fi
  '';
}
