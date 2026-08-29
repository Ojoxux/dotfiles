{ lib, dotfilesPath, ... }:
{
  home.activation.compileAerospaceWorkspaceHUD = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SRC="${dotfilesPath "tools/aerospace-workspace-hud/main.swift"}"
    DEST="$HOME/.local/bin/aerospace-workspace-hud"
    if [ -f "$SRC" ]; then
      $DRY_RUN_CMD /bin/mkdir -p "$HOME/.local/bin"
      if [ ! -x "$DEST" ] || [ "$SRC" -nt "$DEST" ]; then
        $DRY_RUN_CMD /usr/bin/swiftc -O "$SRC" -o "$DEST"
      fi

      HUD_AGENT="gui/$(/usr/bin/id -u)/org.nixos.aerospace-workspace-hud"
      if /bin/launchctl print "$HUD_AGENT" >/dev/null 2>&1; then
        $DRY_RUN_CMD /bin/launchctl kickstart -k "$HUD_AGENT" || true
      fi
    fi
  '';
}
