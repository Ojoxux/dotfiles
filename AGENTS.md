# AGENTS.md

このリポジトリでコードを書く/編集するAIエージェント向けの背景情報。「なぜこうなっているか」はすべてここに集約し、`.nix`ファイル本体にコメントは書かない。README.mdは人間向けの日常操作のみ。

## 全体構成

```
flake.nix   # mkHost ヘルパーで darwinConfigurations.<ホスト名> を定義
hosts/      # マシンごとの定義。networking.hostName とどの profile を使うかの組み合わせ
profiles/   # 言語・用途ごとのパッケージ + modules のまとまり
modules/    # 1ツール1ファイルの個別設定。複数ファイルに分かれるものは modules/zed/ のようにディレクトリ化
config/     # 実際の設定ファイル本体 (nvim, git, ghostty, zed 等)。基本はここへのシンボリックリンクを modules/ が張る
```

新しいツールを足すときは `modules/<tool>.nix` を作って `profiles/base.nix` (または該当profile) の `imports` に足す。新しい用途別パッケージ群は `profiles/<用途>.nix` を作って `hosts/*.nix` の `imports` で選択する。

## ホストの考え方: `powehi` と `local`

- **`powehi`**: このMac(MacBook Air)専用。`hosts/powehi.nix`はgit管理され、username(`"Ojoxux"`)もflake.nixに静的に書かれている。中身を変えたらコミットする。
- **`local`**: まだ用途やホスト名が決まっていない/一時的なマシン用の使い回せる枠。`hosts/local.nix`は`.gitignore`対象で、`cp hosts/local.example.nix hosts/local.nix`して使う。usernameは静的に書かず、実行時に`$SUDO_USER`(なければ`$USER`)から自動解決する(後述)。

**ホスト指定は常に明示、暗黙のデフォルトを持たせない。** `apply.sh`/`setup.sh`はホスト引数が無いとエラーで止まる。Taskfile側も`apply`/`apply:update`/`build`は`requires.vars: [HOST]`で`HOST`を必須にしており、`task apply`のように`HOST`を省略すると即エラーになる(defaultを設定しない)。理由: 新しいマシンで`HOST`を指定し忘れたときに、意図せず`powehi`の個人設定(重い言語profile、powehi固有のcaskなど)が適用されるのを防ぐため。`powehi`専用に使いたい場合は`nixup`(`task apply HOST=powehi`のエイリアス)を使う。

新しく恒久的な2台目が決まったら、`hosts/powehi.nix`を真似た専用ファイル(例: `hosts/work.nix`)を作り、`flake.nix`に`darwinConfigurations.work = mkHost { file = ./hosts/work.nix; username = "..."; };`を1行足す。`local`枠は次の一時マシンのために空けておく。

## ホストの考え方: `sgra` (NixOS-WSL)

- **`sgra`**: Windows 端末上の NixOS-WSL 専用。ブラックホール名 (`powehi` = M87\*, `sgra` = Sagittarius A\*) で揃えていて、ここは他ホストと違い **ホスト名 (`networking.hostName`) も Linux ユーザー名も `sgra`** に統一している。適用は macOS 側の `darwin-rebuild` ではなく `sudo nixos-rebuild switch --flake ~/dotfiles#sgra` (エイリアス `nixup` を `modules/wsl/zsh.nix` で再定義済み)。
- flake 側は `mkWslHost` ヘルパー + `nixosConfigurations.sgra` で、`nixpkgs.lib.nixosSystem` (system = `x86_64-linux`) を呼ぶ。`nix-darwin` / `determinate` / `brew-nix` / `vitePlus` は一切通さない。`dotfilesPath` は `/home/${username}/dotfiles/...` を返す。
- `specialArgs` に `vitePlus` を渡さないので、`profiles/node.nix` など `vitePlus` 引数を取る profile はそのままでは import できない。WSL に言語 profile を足すときは Linux 用に作り直す。

### なぜ `base.nix` を再利用しないのか

`profiles/base.nix` は `home.homeDirectory` を `/Users/${username}` に `lib.mkForce` で固定し、`imports` も macOS 前提のモジュール (`darwin.nix` は host 側だが、`1password.nix`・`cursor.nix`・`vscode.nix`・`zed/`・`ghostty.nix`・`aerospace/hud.nix`) を含む。WSL では代わりに `profiles/wsl.nix` が Linux 用のホームディレクトリとパッケージ一覧を持ち、macOS 依存の無いモジュールだけを import する。

### モジュールの再利用と WSL 専用版

- **そのまま再利用**: `direnv.nix` `lsd.nix` `bat.nix` `starship.nix` `fzf.nix` `zoxide.nix` `fish.nix` `nvim.nix` (nvim は `mkOutOfStoreSymlink` で `~/dotfiles/config/nvim` を指すだけ)。
- **WSL 専用版 (`modules/wsl/`)**: 元モジュールの macOS 固有処理が 1 個の文字列 (`initContent` / `extraConfig`) の中にあり部分上書きできないので fork している。
  - `modules/wsl/zsh.nix`: `Library/pnpm` パス, ghostty 判定での自動 `tmux exec` (darwin の `/etc/profiles` パス前提), `aerospace` エイリアス, nvm/bun/vite-plus/vscode 連携を落とした。`ts()`・tmux への `source-file`・カーソル復元・`git-wt` は残す。`nixup` を `nixos-rebuild` に張り替え。
  - `modules/wsl/tmux.nix`: `shell` を `${pkgs.zsh}/bin/zsh` に、`pmset` バッテリー表示と `tmux-wifi-status` (`networksetup`/`ipconfig`) と ghostty 専用 `terminal-overrides` を削除。
  - `modules/wsl/git.nix`: 共有 `config/git/.gitconfig` を読み込んで末尾に上書きを追記する。git は同じキーの最後の値を採るので `[gpg "ssh"] program` を Windows 側 1Password 同梱の `op-ssh-sign-wsl.exe` (`/mnt/c/Users/jokuy/AppData/Local/Microsoft/WindowsApps/Agilebits.1Password_amwd9z03whsfe/op-ssh-sign-wsl.exe`) に張り替える。この helper は 1Password デスクトップアプリと直接 IPC するので、コミット署名だけなら SSH agent のブリッジ (`npiperelay`) は不要。1Password 8 のバージョンが上がってもこの `WindowsApps\Agilebits.1Password_amwd9z03whsfe\` エイリアスパスは変わらない。

### 初回セットアップの順序 (chicken-and-egg)

NixOS-WSL は最初 `nixos` ユーザーで起動する。`sgra` ユーザーは初回 `nixos-rebuild switch --flake .#sgra` で初めて作られるが、その時点でリポジトリは `/home/nixos/dotfiles` にあり `dotfilesPath` が期待する `/home/sgra/dotfiles` とズレる。手順:

1. NixOS-WSL を入れて `nixos` で起動、`nix-shell -p git` 等で `git clone` → `/home/nixos/dotfiles`
2. `sudo nixos-rebuild switch --flake /home/nixos/dotfiles#sgra` (ここで `sgra` ユーザーが作られる)
3. `wsl --shutdown` して再起動 → ログインユーザーが `sgra` になる
4. `sudo mv /home/nixos/dotfiles /home/sgra/ && sudo chown -R sgra:users /home/sgra/dotfiles`
5. `cd ~/dotfiles && sudo nixos-rebuild switch --flake .#sgra` (今度は `sgra` の home-manager が正しいパスで activate)

初回のうち `sgra` に system git が入るまでは `git+file://` フレーク評価が root で `git` を呼べずコケるので、その間は `--flake path:/home/nixos/dotfiles#sgra` を使う (`path:` は git を経由せずディレクトリをそのままコピーする)。

### `hosts/sgra.nix` の3つの回避策

1. **`programs.git` (system git + `safe.directory = "*"`)**: `sudo nixos-rebuild` は root で走り、`git+file://` フレークの評価・lock 更新で `git` を実行する。まっさらな NixOS-WSL には git が無いので入れる。さらに repo は `sgra` 所有・評価は root なので git の "dubious ownership" ガードに引っかかる。`safe.directory` で無効化。これが入る前は上記のとおり `path:` で回避。
2. **`nix.settings` に `nix-community` cache**: `nixos-wsl` が Rust で書いた `nixos-wsl-utils` (activate スクリプト) をローカルビルドさせず既製バイナリで済ませる狙い。ただし nixpkgs のズレでヒットしないこともあり、決定打は 3。
3. **`fetchurl` オーバーレイで crate を `static.crates.io` から取る**: この回線からは `https://crates.io/api/v1/crates/<name>/<ver>/download` (crates.io API) が 403 で、CDN の `https://static.crates.io/crates/<name>/<name>-<ver>.crate` は 200。`fetchCargoVendor` は前者を使うので、`fetchurl` を包んで URL がその形のときだけ後者に書き換える (中身同一なのでハッシュ不変)。`nixos-wsl-utils` のクレート取得がこれで通る。別回線で crates.io API が普通に通るならこのオーバーレイは無害な no-op。

### `local`特有の落とし穴

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

`modules/darwin.nix`の`homebrew.casks`は**ホスト非依存で安全な最小限**だけを置く(今は`visual-studio-code`/`zed`/`raycast`)。会社ポリシー確認が必要なもの・powehi固有のもの(`google-chrome`/`orbstack`/`1password`/`wireshark-app`)は`hosts/powehi.nix`側に`homebrew.casks = [...]`を追加する形で足す。nix-darwinの`homebrew.casks`はリスト型オプションなので、モジュール間で自動的に連結される(`mkMerge`不要)。新しいホストを作るときも、共通で困らないものだけ`modules/darwin.nix`に残し、それ以外はホスト側で足す方針を踏襲する。

## 画面割れ対策の左余白 (`modules/aerospace/crack-gap.nix`)

powehi固有機能。内蔵ディスプレイの割れた部分を避けるため`gaps.outer.left`に余白を入れる。外部モニターのみで作業するときは不要なのでトグルできる。

- 有効化: ホストの`.nix`に`aerospaceCrackGap.enable = true; aerospaceCrackGap.width = <避けたい幅(px)>;`
- 優先度の作り: `modules/darwin.nix`側は`gaps.outer.left = lib.mkDefault 0`、`crack-gap.nix`側は`cfg.width`をそのまま代入(defaultより強い)。launchdの起動コマンドも`darwin.nix`が`mkForce`(優先度50)、`crack-gap.nix`が`mkOverride 40`(より強い)で上書きする。両方`mkForce`だと優先度が同じで衝突するため、片方は必ずそれより強い優先度にする必要がある。
- 状態は`~/.local/state/aerospace/crack-gap`に保存され、`~/.config/aerospace/aerospace.toml`を余白あり/なしの生成済み設定に差し替えて`aerospace reload-config`する。再ビルドしてもAeroSpace起動時に`sync`(トグルはしない、保存済み状態を書き出すだけ)が走るので状態は維持される。無効なホストでは`~/.config/aerospace/`を経由せず、Nixが生成した設定をAeroSpaceが直接読む。
- コマンド: `ctrl-alt-p`(トグル、service modeでは`p`)、`aerospace-crack-gap [on|off|toggle|status]`。
- キーバインド(`mode.main.binding.ctrl-alt-p`)は`crackGapToggle`のstoreパスではなく実行時パス(`/run/current-system/sw/bin/...`)を指す。`config.services.aerospace.settings`を読みながら同じ`settings`を定義しているため、storeパスをここに埋めると評価が循環してしまう。

## AeroSpaceのlaunchd起動 (`modules/darwin.nix`)

`launchd.user.agents.aerospace`は`/nix/store`のバンドルを直接起動せず、`/Applications/Nix Apps/AeroSpace.app`を起動するよう`mkForce`で上書きしている。nix-darwin標準の起動方法(`/nix/store`直接)だとAccessibility権限のTCCチェックがad-hoc署名アプリに対して通らないことがあるため。

## その他の個別事情

- **zeno.zsh** (`modules/zeno.nix`): nixpkgsの`zeno`パッケージは無関係のツールなので本体をGitHubから直接取得している。上流は`deno --node-modules-dir=auto`を呼ぶが、`auto`は読み取り専用の`/nix/store`内に`node_modules`を作ろうとして失敗する。npm依存が`yargs-parser`のみなので`--node-modules-dir=none`にパッチして`deno`のグローバルキャッシュから解決させている。
- **`app-only`系のprofile** (`profiles/powehi-only.nix`): `brewCasks.*`は`modules/darwin.nix`の`homebrew.casks`(実際に`brew bundle`でインストールする)とは別物で、`brew-nix`フレークが提供する、Homebrew配布物をNixパッケージとして参照する仕組み。CLI的に使うものはこちら、GUIアプリで署名・自動更新・権限まわりが絡むものは`homebrew.casks`、という使い分け。`brewCasks.codex`の実体は`codex-aarch64-apple-darwin`という名前なので、普段使う`codex`コマンドとして呼べるようラッパーを被せている。`claude-nix`は既存の`~/.vite-plus/bin/claude`と別名で共存させる試験導入中の名前(問題なければ`claude`自体を置き換える想定)。
- **Determinate Nix**: `nix.enable = false`としてnix-darwin本体にはNixデーモン管理をさせず、Determinate Nixに任せている。`nix.gc`が使えないため、ガベージコレクションはlaunchdデーモン(`modules/darwin.nix`の`launchd.daemons.nix-gc`)で代替している。
- **カーソル表示のワークアラウンド**: AI agent CLI(Claude Code等)が`\e[?25l`でカーソルを隠したまま復元し忘れることがあるため、`modules/zsh.nix`の`precmd_functions`にカーソルを強制表示する関数を登録し、`modules/tmux.nix`側でも`pane-focus-in`/`client-focus-in`フックと`prefix + r`(手動リストア)を用意している。`modules/zsh.nix`はさらに、Ghosttyの`command=`設定が効く前のフォールバックとして、対話シェルかつ`TERM_PROGRAM=ghostty`かつtmux外のときに自動で`tmux new -A -s main`する(IDEターミナルやネストしたtmuxはスキップ)。
- **tmuxのWi-Fi表示** (`modules/tmux.nix`の`tmux-wifi-status`): macOSはターミナルにLocation Services権限が無いとSSIDを`<redacted>`に伏せる。`networksetup`で取れなければ`ipconfig getsummary`にフォールバックし、それでも駄目なら接続の有無だけ`Wi-Fi`と表示する。
