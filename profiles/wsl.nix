{ lib, pkgs, username, ... }:
{
  home.username = username;
  home.homeDirectory = lib.mkForce "/home/${username}";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  home.file.".npmrc".text = "prefix=\${HOME}/.npm-global\n";

  home.packages = with pkgs; [
    git
    git-lfs
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
    nodejs_22
  ];

  imports = [
    ../modules/direnv.nix
    ../modules/lsd.nix
    ../modules/bat.nix
    ../modules/starship.nix
    ../modules/fzf.nix
    ../modules/zoxide.nix
    ../modules/fish.nix
    ../modules/nvim.nix

    ../modules/wsl/zsh.nix
    ../modules/wsl/tmux.nix
    ../modules/wsl/git.nix
  ];
}
