{ lib, pkgs, username, ... }:
{
  home.username = username;
  home.homeDirectory = lib.mkForce "/Users/${username}";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    git
    git-lfs
    git-wt
    gh
    lazygit
    neovim
    tmux
    fish
    starship
    fzf
    lsd
    ripgrep
    fd
    bat
    jq
    yq-go
    delta

    go-task

    devbox

    ghostty-bin

    nerd-fonts.hack
    nerd-fonts.blex-mono
    nerd-fonts.fira-code
    source-han-code-jp
  ];

  imports = [
    ../modules/direnv.nix
    ../modules/lsd.nix
    ../modules/bat.nix
    ../modules/starship.nix
    ../modules/tmux.nix
    ../modules/fzf.nix
    ../modules/zoxide.nix
    ../modules/fish.nix
    ../modules/zsh.nix

    ../modules/cursor.nix
    ../modules/vscode.nix
    ../modules/nvim.nix
    ../modules/zed

    ../modules/git.nix
    ../modules/1password.nix
    ../modules/ghostty.nix
    ../modules/zeno.nix
    ../modules/aerospace/hud.nix
  ];
}
