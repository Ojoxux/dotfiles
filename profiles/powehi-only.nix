{ pkgs, ... }:
let
  codexCodeModeHost = pkgs.runCommand "codex-code-mode-host-${pkgs.brewCasks.codex.version}" { } ''
    mkdir -p $out/bin
    install -m755 ${builtins.fetchTarball {
      url = "https://github.com/openai/codex/releases/download/rust-v${pkgs.brewCasks.codex.version}/codex-code-mode-host-aarch64-apple-darwin.tar.gz";
    }}/codex-code-mode-host-aarch64-apple-darwin $out/bin/codex-code-mode-host
  '';
in
{
  imports = [ ./base.nix ];

  home.packages = with pkgs; [
    brewCasks.codex
    codexCodeModeHost
    brewCasks.cursor
    brewCasks.arc
    brewCasks.figma
    brewCasks.webots

    (writeShellScriptBin "claude-nix" ''
      exec ${claude-code}/bin/claude "$@"
    '')
  ];
}
