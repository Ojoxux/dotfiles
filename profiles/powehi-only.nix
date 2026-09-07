{ pkgs, ... }:
let
  # codexはcode-mode-hostを「自分と同じディレクトリにあるバイナリ」としてしか探さないため
  # ~/.local/binのような別PATHに置いても効果がない。home.packagesのbuildEnvで
  # brewCasks.codexと同じbinディレクトリにsymlinkされるようにする必要がある。
  # 本体とバージョンが常に一致している必要がある特例なので、fetchurlのhash固定はせず
  # builtins.fetchTarball(--impureなので毎回codexの実バージョンに追従して取得)を使う。
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
    # brewCasks.codexは0.153.4以降bin/codexを直接提供するようになったため、ラッパー不要
    brewCasks.codex
    codexCodeModeHost
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
