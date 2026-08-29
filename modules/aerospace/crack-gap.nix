{ config, lib, pkgs, username, ... }:
let
  cfg = config.aerospaceCrackGap;

  stripNulls = value:
    if builtins.isAttrs value then
      lib.filterAttrs (_: v: v != null) (lib.mapAttrs (_: v: stripNulls v) value)
    else if builtins.isList value then
      map stripNulls (builtins.filter (v: v != null) value)
    else
      value;

  mkAerospaceConfig = name: settings:
    (pkgs.formats.toml { }).generate name (stripNulls settings);

  crackGapConfigOn = mkAerospaceConfig "aerospace-crack-gap-on.toml"
    config.services.aerospace.settings;
  crackGapConfigOff = mkAerospaceConfig "aerospace-crack-gap-off.toml"
    (lib.recursiveUpdate config.services.aerospace.settings { gaps.outer.left = 0; });

  aerospaceUserConfig = "/Users/${username}/.config/aerospace/aerospace.toml";
  crackGapStateFile = "/Users/${username}/.local/state/aerospace/crack-gap";

  crackGapToggle = pkgs.writeShellScriptBin "aerospace-crack-gap" ''
    set -eu

    CONFIG_FILE="${aerospaceUserConfig}"
    STATE_FILE="${crackGapStateFile}"

    current_state() {
      if [ -r "$STATE_FILE" ] && [ "$(/bin/cat "$STATE_FILE")" = "off" ]; then
        printf 'off'
      else
        printf 'on'
      fi
    }

    write_config() {
      /bin/mkdir -p "$(/usr/bin/dirname "$CONFIG_FILE")" "$(/usr/bin/dirname "$STATE_FILE")"
      if [ "$1" = "off" ]; then
        /usr/bin/install -m 644 "${crackGapConfigOff}" "$CONFIG_FILE"
      else
        /usr/bin/install -m 644 "${crackGapConfigOn}" "$CONFIG_FILE"
      fi
      printf '%s' "$1" > "$STATE_FILE"
    }

    apply() {
      write_config "$1"
      /run/current-system/sw/bin/aerospace reload-config >/dev/null 2>&1 || true
      printf 'crack gap: %s\n' "$1"
    }

    case "''${1:-toggle}" in
      on) apply on ;;
      off) apply off ;;
      toggle)
        if [ "$(current_state)" = "off" ]; then apply on; else apply off; fi
        ;;
      sync) write_config "$(current_state)" ;;
      status) printf 'crack gap: %s\n' "$(current_state)" ;;
      *)
        printf 'usage: aerospace-crack-gap [toggle|on|off|sync|status]\n' >&2
        exit 1
        ;;
    esac
  '';
in
{
  options.aerospaceCrackGap = {
    enable = lib.mkEnableOption "画面割れ対策の左余白トグル";

    width = lib.mkOption {
      type = lib.types.int;
      default = 100;
      description = ''
        内蔵ディスプレイの割れている部分を避けるための左余白 (px)。
        割れ幅はマシンの個体ごとに違うので、ホスト側で実測値を指定する。
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ crackGapToggle ];

    services.aerospace.settings = {
      gaps.outer.left = cfg.width;

      mode.main.binding.ctrl-alt-p =
        "exec-and-forget /run/current-system/sw/bin/aerospace-crack-gap toggle";

      mode.service.binding.p = [
        "exec-and-forget /run/current-system/sw/bin/aerospace-crack-gap toggle"
        "mode main"
      ];
    };

    launchd.user.agents.aerospace.serviceConfig.ProgramArguments = lib.mkOverride 40 [
      "/bin/sh"
      "-c"
      "'${crackGapToggle}/bin/aerospace-crack-gap' sync; /bin/wait4path '/Applications/Nix Apps/AeroSpace.app' && exec '/Applications/Nix Apps/AeroSpace.app/Contents/MacOS/AeroSpace' --config-path '${aerospaceUserConfig}'"
    ];
  };
}
