{ pkgs, ... }:
{
  imports = [ ./base.nix ];

  home.packages = with pkgs; [
    # brewCasks.codexの実体はcodex-aarch64-apple-darwinという名前なので，普段使うcodexコマンドとして呼べるようラッパーを被せた
    brewCasks.codex
    (writeShellScriptBin "codex" ''
      exec ${brewCasks.codex}/bin/codex-aarch64-apple-darwin "$@"
    '')
    brewCasks.cursor
    brewCasks.arc
    brewCasks.figma
    brewCasks.webots

    # 試験導入中: 既存の ~/.vite-plus/bin/claude とは別名で共存させ、様子を見る。
    # 問題なさそうならこの部分を書き換えて "claude" コマンド自体を置き換える。
    (writeShellScriptBin "claude-nix" ''
      exec ${claude-code}/bin/claude "$@"
    '')
  ];
}
