# AGENTS.md

このリポジトリでコードを書く/編集するAIエージェント向けの背景情報。「なぜこうなっているか」はすべてここに集約し、`.nix`ファイル本体にコメントは書かない。README.mdは人間向けの日常操作のみ。

ここに書くのは、環境由来の問題への対処や、普通のやり方をしていない理由だけ。コードを読めば分かる構成や一般的な説明は書かない。

## ホスト指定にデフォルトを持たせない

`apply.sh`/`setup.sh`はホスト引数が無いとエラーで止まり、Taskfileの`apply`/`apply:update`/`build`も`requires.vars: [HOST]`でdefaultを設定していない。新しいマシンで`HOST`を指定し忘れたときに、`powehi`の個人設定(重い言語profile、powehi固有のcaskなど)が意図せず適用されるのを防ぐため。

`local`枠は一時マシン用に空けておき、恒久的な2台目は`hosts/powehi.nix`を真似た専用ファイルを作って`flake.nix`に足す。

## `sgra` (NixOS-WSL)

### `claude` は npm グローバル (nixpkgs `claude-code` は使わない)

nixpkgs の `claude-code` は Claude Code の npm リリースから大きく遅れる (実測 `2.1.133` vs npm `2.1.261`)。CLI バージョンに利用可能モデルがクライアント側で紐付くため、鮮度が実用に効く。mac は `nix-vite-plus` を使っているが、今の `vp` (VITE+) はグローバル CLI を PATH に生やす仕組みが無く、`claude` は node バージョン依存パス (`~/.vite-plus/js_runtime/node/<ver>/bin`) に埋もれる。そこで WSL は `nodejs_22` + `~/.npmrc` の `prefix=${HOME}/.npm-global` にしている。

`programs.nix-ld.enable`: NixOS は FHS のダイナミックリンク実行ファイルを素で動かせない。nixpkgs `nodejs` 自体は patchelf 済みで問題ないが、npm グローバルが引き込む prebuilt バイナリや VS Code server 等のために入れてある。

### `base.nix` と macOS 用モジュールを再利用しない理由

`profiles/base.nix` は `home.homeDirectory` を `/Users/${username}` に `lib.mkForce` で固定し、macOS 前提のモジュールも import している。`profiles/node.nix` 等の言語 profile も `./base.nix` を import しているので、WSL に言語 profile を足すときは Linux 用に作り直す。

`modules/wsl/` の zsh・tmux は、元モジュールの macOS 固有処理が 1 個の文字列 (`initContent` / `extraConfig`) の中にあって部分上書きできないので fork している。zsh の自動 `tmux exec` は、元の ghostty 判定が WSL では成り立たないので「対話シェル & tmux 外 & IDE ターミナルでない」だけで判定している。

### コミット署名は `op-ssh-sign-wsl.exe` (`modules/wsl/git.nix`)

Windows 側 1Password 同梱の helper はデスクトップアプリと直接 IPC するので、コミット署名だけなら SSH agent のブリッジ (`npiperelay`) は不要。`%LOCALAPPDATA%\Microsoft\WindowsApps\` のアプリ実行エイリアスが `appendWindowsPath` で PATH に載るので、Windows のユーザー名をリポジトリに書かないようフルパスではなくコマンド名で指定している。

### WezTerm の設定はコピー (`modules/wsl/wezterm.nix`)

WezTerm.exe は Windows のホーム (`%USERPROFILE%\.wezterm.lua`) しか読まないので、switch のたびにコピーしている。Windows のユーザー名をリポジトリに書かないよう、`%USERPROFILE%` は実行時に `cmd.exe` から取る。

### 初回セットアップの順序 (chicken-and-egg)

NixOS-WSL は最初 `nixos` ユーザーで起動する。`sgra` ユーザーは初回 `nixos-rebuild switch --flake .#sgra` で初めて作られるが、その時点でリポジトリは `/home/nixos/dotfiles` にあり `dotfilesPath` が期待する `/home/sgra/dotfiles` とズレる。手順:

1. NixOS-WSL を入れて `nixos` で起動、`nix-shell -p git` 等で `git clone` → `/home/nixos/dotfiles`
2. `sudo nixos-rebuild switch --flake /home/nixos/dotfiles#sgra` (ここで `sgra` ユーザーが作られる)
3. `wsl --shutdown` して再起動 → ログインユーザーが `sgra` になる
4. `sudo mv /home/nixos/dotfiles /home/sgra/ && sudo chown -R sgra:users /home/sgra/dotfiles`
5. `cd ~/dotfiles && sudo nixos-rebuild switch --flake .#sgra` (今度は `sgra` の home-manager が正しいパスで activate)

初回のうち `sgra` に system git が入るまでは `git+file://` フレーク評価が root で `git` を呼べずコケるので、その間は `--flake path:/home/nixos/dotfiles#sgra` を使う (`path:` は git を経由せずディレクトリをそのままコピーする)。

### `hosts/sgra.nix` の回避策

1. **`programs.git` (system git)**: `sudo nixos-rebuild` は root で走り、`git+file://` フレークの評価・lock 更新で `git` を実行する。まっさらな NixOS-WSL には git が無いので入れる。
2. **`nix.settings` に `nix-community` cache**: `nixos-wsl` が Rust で書いた `nixos-wsl-utils` (activate スクリプト) をローカルビルドさせず既製バイナリで済ませる狙い。ただし nixpkgs のズレでヒットしないこともあり、決定打は 3。
3. **`fetchurl` オーバーレイで crate を `static.crates.io` から取る**: この回線からは `https://crates.io/api/v1/crates/<name>/<ver>/download` (crates.io API) が 403 で、CDN の `https://static.crates.io/crates/<name>/<name>-<ver>.crate` は 200。`fetchCargoVendor` は前者を使うので、`fetchurl` を包んで URL がその形のときだけ後者に書き換える (中身同一なのでハッシュ不変)。別回線で crates.io API が普通に通るならこのオーバーレイは無害な no-op。
4. **`SSL_CERT_FILE` を明示**: 未設定だと NixOS 上の workerd (`wrangler dev`) が CA 証明書を見つけられず、外部への HTTPS fetch が `internal error; reference = ...` で全滅する (HTTP は通る)。
5. **Docker Desktop ではなくネイティブの dockerd**: Docker Desktop の WSL 統合スクリプトは `wsl.exe -e whoami` を最小 PATH で呼ぶため、NixOS のバイナリが見えず `execvpe(whoami) failed` で落ちる。`wsl.docker-desktop.enable` で回避はできるが、この統合は Docker Desktop のバージョンが上がるたびに壊れている (docker/for-win#14931) ので使わない。

## `local`特有の落とし穴

1. **`hosts/local.nix`はNixのflake評価から見えない**: Nixはローカルgitリポジトリをflakeとして評価するとき、gitに追跡されていないファイルを無視する。`hosts/local.nix`は`.gitignore`対象=追跡外なので、ディスク上に存在してもエラー(`path .../hosts/local.nix does not exist`)になる。対処は、コミットはせずにgitの追跡対象にだけ乗せること:
   ```bash
   git add -N -f hosts/local.nix
   ```
   (`-f`で`.gitignore`を無視、`-N`=intent-to-addでパスの存在だけをgitに知らせる。中身はまだコミット対象にならない。) 以後うっかり`git commit -a`等で巻き込まないよう`git update-index --skip-worktree hosts/local.nix`もしておくとよい。
   - `config/zed/display-profiles/local.json`のような、`dotfilesPath`(実行時の絶対パス文字列)経由でしか参照されないファイルは、この対応は不要。flake評価時に読まれるのは`./hosts/local.nix`のように相対パスで`import`されるファイルだけ。

2. **`sudo`配下では`$USER`が`"root"`になる**: `apply.sh`は`sudo darwin-rebuild switch ...`で実行する。sudoはデフォルトで環境変数をリセットし(`env_reset`)、`$USER`をターゲットユーザー(root)に書き換える。`darwinConfigurations.local`のusername解決はこれを踏まえて`$SUDO_USER`(元のユーザー名を保持している)を優先し、無ければ(sudoを経由しない`nix eval`等)`$USER`にフォールバックする。これをやらないと「`users.users.root.home`は`null`か`/var/root`以外許さない」というnix-darwinのアサーションで落ちる。

3. **`darwinConfigurations.check`は検証専用**: 「powehi固有の設定が共通モジュール(`modules/`)に漏れていないか」を確認するためだけのホスト。`hosts/local.example.nix`(git管理・追跡済み)を読む。実マシンに適用するものではない。
   ```bash
   nix eval --impure .#darwinConfigurations.check.config.<option>
   ```

## `task dry-run`の実装 (`Taskfile.yaml`)

`darwin-rebuild`に`switch --dry-run`は無い(`--dry-run`は`nix build`側へ渡るだけで`activate`は素通りしてしまう)。そのため`darwin-rebuild build`だけ実行し、できたシステムと現行システム(`/run/current-system`)のクロージャを`nix store diff-closures`で比較することで疑似的なdry-runにしている。ビルド結果の`result`シンボリックリンクはリポジトリを汚さないよう`mktemp -d`したtempディレクトリに作らせている。

## Homebrew caskの分け方

`modules/darwin.nix`の`homebrew.casks`にはホスト非依存で安全な最小限だけを置く。会社ポリシー確認が必要なものやpowehi固有のものは`hosts/powehi.nix`側で足す。

## 画面割れ対策の左余白 (`modules/aerospace/crack-gap.nix`)

powehi固有機能。内蔵ディスプレイの割れた部分を避けるため`gaps.outer.left`に余白を入れ、外部モニターのみで作業するときのためにトグルできるようにしている。

- 優先度の作り: `modules/darwin.nix`側は`gaps.outer.left = lib.mkDefault 0`、`crack-gap.nix`側は`cfg.width`をそのまま代入(defaultより強い)。launchdの起動コマンドも`darwin.nix`が`mkForce`(優先度50)、`crack-gap.nix`が`mkOverride 40`(より強い)で上書きする。両方`mkForce`だと優先度が同じで衝突するため、片方は必ずそれより強い優先度にする必要がある。
- トグル状態は`~/.local/state/aerospace/crack-gap`に持ち、`~/.config/aerospace/aerospace.toml`を生成済み設定に差し替える。再ビルドで状態が消えないよう、AeroSpace起動時に`sync`(保存済み状態を書き出すだけ)を走らせている。
- キーバインド(`mode.main.binding.ctrl-alt-p`)は`crackGapToggle`のstoreパスではなく実行時パス(`/run/current-system/sw/bin/...`)を指す。`config.services.aerospace.settings`を読みながら同じ`settings`を定義しているため、storeパスをここに埋めると評価が循環してしまう。

## AeroSpaceのlaunchd起動 (`modules/darwin.nix`)

`launchd.user.agents.aerospace`は`/nix/store`のバンドルを直接起動せず、`/Applications/Nix Apps/AeroSpace.app`を起動するよう`mkForce`で上書きしている。nix-darwin標準の起動方法(`/nix/store`直接)だとAccessibility権限のTCCチェックがad-hoc署名アプリに対して通らないことがあるため。

## AeroSpaceまわりのキーとアプリ (`modules/darwin.nix`)

- Rectangleはウィンドウ操作がAeroSpaceと衝突するので、AeroSpaceが有効なときはactivationで終了させ、ログイン項目からも外す。
- service modeには`ctrl-shift-0`も割り当てている。`ctrl-shift-semicolon`はJISキーボードで押しにくく、Electronアプリに横取りされることもあるため。
- service modeを経由しないレイアウトリセット(`flatten-workspace-tree`)を複数のキーに割り当てている。Codex/Cursorが他のキーを横取りしても、どれかは効くようにするため。

## その他の個別事情

- **zeno.zsh** (`modules/zeno.nix`): nixpkgsの`zeno`パッケージは無関係のツールなので本体をGitHubから直接取得している。上流は`deno --node-modules-dir=auto`を呼ぶが、`auto`は読み取り専用の`/nix/store`内に`node_modules`を作ろうとして失敗する。npm依存が`yargs-parser`のみなので`--node-modules-dir=none`にパッチして`deno`のグローバルキャッシュから解決させている。
- **`brewCasks.*`と`homebrew.casks`の使い分け** (`profiles/powehi-only.nix`): `brewCasks.*`は`brew-nix`フレークが提供する、Homebrew配布物をNixパッケージとして参照する仕組み。CLI的に使うものはこちら、GUIアプリで署名・自動更新・権限まわりが絡むものは`homebrew.casks`。
- **codexの`code-mode-host`** (`profiles/powehi-only.nix`): codexは`code-mode-host`を自分と同じディレクトリのバイナリとしてしか探さないので、`~/.local/bin`等に置いても効かず、`home.packages`で`brewCasks.codex`と同じbinにsymlinkされる必要がある。本体とバージョンが常に一致している必要があるため、hash固定の`fetchurl`ではなく`builtins.fetchTarball`(`--impure`で毎回codexの実バージョンに追従)で取る。
- **`claude-nix`** (`profiles/powehi-only.nix`): 既存の`~/.vite-plus/bin/claude`と別名で共存させる試験導入中の名前。問題なければ`claude`自体を置き換える想定。
- **Determinate Nix**: `nix.enable = false`としてnix-darwin本体にはNixデーモン管理をさせず、Determinate Nixに任せている。`nix.gc`が使えないため、ガベージコレクションはlaunchdデーモン(`modules/darwin.nix`の`launchd.daemons.nix-gc`)で代替している。
- **カーソル表示のワークアラウンド**: AI agent CLI(Claude Code等)が`\e[?25l`でカーソルを隠したまま復元し忘れることがあるため、`modules/zsh.nix`の`precmd_functions`にカーソルを強制表示する関数を登録し、`modules/tmux.nix`側でも`pane-focus-in`/`client-focus-in`フックと`prefix + r`(手動リストア)を用意している。`modules/zsh.nix`はさらに、Ghosttyの`command=`設定が効く前のフォールバックとして、対話シェルかつ`TERM_PROGRAM=ghostty`かつtmux外のときに自動で`tmux new -A -s main`する。
- **tmuxのWi-Fi表示** (`modules/tmux.nix`の`tmux-wifi-status`): macOSはターミナルにLocation Services権限が無いとSSIDを`<redacted>`に伏せる。`networksetup`で取れなければ`ipconfig getsummary`にフォールバックし、それでも駄目なら接続の有無だけ`Wi-Fi`と表示する。
