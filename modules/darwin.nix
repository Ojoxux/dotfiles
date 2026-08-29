{ config, lib, pkgs, username, dotfilesPath, ... }:
let
  stripNulls = value:
    if builtins.isAttrs value then
      lib.filterAttrs (_: v: v != null) (lib.mapAttrs (_: v: stripNulls v) value)
    else if builtins.isList value then
      map stripNulls (builtins.filter (v: v != null) value)
    else
      value;
  workspaceHudHook = pkgs.writeShellScript "aerospace-workspace-hud-hook" ''
    printf '%s' "''${AEROSPACE_FOCUSED_WORKSPACE:-?}" | /usr/bin/nc -u -w 0 127.0.0.1 17371 >/dev/null 2>&1 || true
    exit 0
  '';
  mkAerospaceConfig = name: settings:
    (pkgs.formats.toml { }).generate name (stripNulls settings);

  aerospaceConfig = mkAerospaceConfig "aerospace.toml" config.services.aerospace.settings;
in
{
  imports = [
    ./aerospace/crack-gap.nix
  ];

  environment.systemPackages = with pkgs; [
    aerospace
    jankyborders
  ];

  system.primaryUser = username;
  programs.zsh.enable = true;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Determinate Nix manages the daemon and nix.conf; nix-darwin must not take over.
  nix.enable = false;

  system.activationScripts.preActivation.text = ''
    if [ -f /etc/nix/nix.custom.conf ]; then
      mv /etc/nix/nix.custom.conf /etc/nix/nix.custom.conf.before-nix-darwin || true
    fi
  '';

  system.activationScripts.postActivation.text = lib.optionalString config.services.aerospace.enable ''
    # Rectangle conflicts with AeroSpace; keep it stopped when tiling WM is active.
    if /usr/bin/pgrep -x Rectangle >/dev/null 2>&1; then
      /usr/bin/osascript -e 'tell application "Rectangle" to quit' 2>/dev/null || true
    fi
    /usr/bin/osascript -e 'tell application "System Events" to delete login item "Rectangle"' 2>/dev/null || true
  '';

  determinateNix = {
    enable = true;
    determinateNixd.garbageCollector.strategy = "disabled";
  };

  # nix.gc は nix.enable = false では使えないため launchd で代替
  launchd.daemons.nix-gc = {
    serviceConfig = {
      Label = "org.nixos.nix-gc";
      ProgramArguments = [
        "/nix/var/nix/profiles/default/bin/nix-collect-garbage"
        "--delete-older-than"
        "30d"
      ];
      StartCalendarInterval = [
        { Weekday = 0; Hour = 3; Minute = 0; }
      ];
      StandardOutPath = "/var/log/nix-gc.log";
      StandardErrorPath = "/var/log/nix-gc.err";
    };
  };

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  services.aerospace = {
    enable = true;
    package = pkgs.aerospace;
    settings = {
      config-version = 2;
      start-at-login = false;

      exec-on-workspace-change = [
        "${workspaceHudHook}"
      ];

      enable-normalization-flatten-containers = true;
      enable-normalization-opposite-orientation-for-nested-containers = true;
      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";
      accordion-padding = 30;
      automatically-unhide-macos-hidden-apps = false;

      gaps = {
        inner = {
          horizontal = 6;
          vertical = 6;
        };
        outer = {
          left = lib.mkDefault 0;
          bottom = 6;
          top = 6;
          right = 0;
        };
      };

      mode.main.binding = {
        ctrl-slash = "layout tiles horizontal vertical";
        ctrl-comma = "layout accordion horizontal vertical";

        ctrl-h = "focus left";
        ctrl-j = "focus down";
        ctrl-k = "focus up";
        ctrl-l = "focus right";

        ctrl-shift-h = "move left";
        ctrl-shift-j = "move down";
        ctrl-shift-k = "move up";
        ctrl-shift-l = "move right";

        ctrl-minus = "resize smart -50";
        ctrl-equal = "resize smart +50";

        ctrl-1 = "workspace 1";
        ctrl-2 = "workspace 2";
        ctrl-3 = "workspace 3";
        ctrl-4 = "workspace 4";
        ctrl-5 = "workspace 5";

        ctrl-shift-1 = "move-node-to-workspace 1";
        ctrl-shift-2 = "move-node-to-workspace 2";
        ctrl-shift-3 = "move-node-to-workspace 3";
        ctrl-shift-4 = "move-node-to-workspace 4";
        ctrl-shift-5 = "move-node-to-workspace 5";

        ctrl-tab = "workspace-back-and-forth";
        ctrl-shift-tab = "move-workspace-to-monitor --wrap-around next";

        # Service mode (avoid semicolon; awkward on JIS and blocked by Electron apps)
        ctrl-shift-0 = "mode service";
        ctrl-shift-semicolon = "mode service";

        # Reset layout without service mode (works when Codex/Cursor capture other keys)
        ctrl-shift-r = "flatten-workspace-tree";
        ctrl-alt-r = "flatten-workspace-tree";
        ctrl-alt-shift-r = "flatten-workspace-tree";
        f12 = "flatten-workspace-tree";
      };

      mode.service.binding = {
        esc = [ "reload-config" "mode main" ];
        r = [ "flatten-workspace-tree" "mode main" ];
        f = [ "layout floating tiling" "mode main" ];
        backspace = [ "close-all-windows-but-current" "mode main" ];
      };

      on-window-detected = [
        {
          "if".app-id = "com.apple.systempreferences";
          run = "layout floating";
        }
        {
          "if".app-id = "com.apple.ActivityMonitor";
          run = "layout floating";
        }
      ];
    };
  };

  launchd.user.agents.aerospace.serviceConfig.ProgramArguments = lib.mkForce [
    "/bin/sh"
    "-c"
    "/bin/wait4path '/Applications/Nix Apps/AeroSpace.app' && exec '/Applications/Nix Apps/AeroSpace.app/Contents/MacOS/AeroSpace' --config-path '${aerospaceConfig}'"
  ];

  launchd.user.agents.aerospace-workspace-hud.serviceConfig = {
    ProgramArguments = [
      "/bin/sh"
      "-c"
      "while [ ! -x '/Users/${username}/.local/bin/aerospace-workspace-hud' ]; do /bin/sleep 0.2; done; exec '/Users/${username}/.local/bin/aerospace-workspace-hud' --server"
    ];
    RunAtLoad = true;
    KeepAlive = true;
    StandardErrorPath = "/Users/${username}/Library/Logs/aerospace-workspace-hud.err.log";
    StandardOutPath = "/Users/${username}/Library/Logs/aerospace-workspace-hud.out.log";
  };

  services.jankyborders = {
    enable = true;
    package = pkgs.jankyborders;
    style = "round";
    order = "above";
    width = 2.0;
    hidpi = true;
    active_color = "0xffffffff";
    inactive_color = "0xff282828";
    background_color = "0x00000000";
  };

  launchd.user.agents.jankyborders.serviceConfig = {
    ProgramArguments = lib.mkForce (
      let
        jb = config.services.jankyborders;
      in
      [
        "/bin/sh"
        "-c"
        "/bin/wait4path '/run/current-system/sw/bin/borders' && while ! /usr/bin/pgrep -x WindowServer >/dev/null 2>&1; do /bin/sleep 0.5; done && exec '/run/current-system/sw/bin/borders' width=${toString jb.width} hidpi=${if jb.hidpi then "on" else "off"} active_color=${jb.active_color} inactive_color=${jb.inactive_color} background_color=${jb.background_color} style=${jb.style} blur_radius=0.000000 ax_focus=off order=${jb.order}"
      ]
    );
    StandardErrorPath = "/Users/${username}/Library/Logs/jankyborders/err.log";
    StandardOutPath = "/Users/${username}/Library/Logs/jankyborders/out.log";
  };

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "none";
      autoUpdate = true;
      upgrade = true;
    };
    casks = [
      "visual-studio-code"
      "zed"
      "raycast"
    ];
  };

  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
      mru-spaces = false;
      tilesize = 40;
      magnification = true;
      largesize = 100;
      orientation = "bottom";
      mineffect = "scale";
    };
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "clmv";
      ShowPathbar = true;
    };
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };
  };

  system.defaults.CustomUserPreferences = {
    "com.apple.controlcenter".AutoHideMenuBarOption = 2;
    "com.apple.inputmethod.Kotoeri".JIMPrefPunctuationTypeKey = 3;
    "com.knollsoft.Rectangle" = {
      launchOnLogin = false;
      screenEdgeGapTop = 38;
      screenEdgeGapTopNotch = 0;
      screenEdgeGapLeft = 0;
      screenEdgeGapRight = 0;
    };
  };

  system.stateVersion = 6;
}
