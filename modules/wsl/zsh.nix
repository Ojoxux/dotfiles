{ ... }:
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "";
      plugins = [ "git" ];
    };

    shellAliases = {
      nixup = "sudo nixos-rebuild switch --flake ~/dotfiles#sgra";
      tls = "tmux list-sessions";
      treload = "tmux source-file ~/.config/tmux/tmux.conf && tmux display-message 'tmux reloaded'";
      cursor = "printf '\\e[?25h\\e[2 q'";
      sp = "tmux split-window -h";
      sv = "tmux split-window -v";
    };

    sessionVariables = {
      MY_USER = "$(whoami)";
      MY_HOST = "$(hostname -s)";
    };

    initContent = ''
      ts() {
        local session="''${1:-main}"
        if [[ -n "$TMUX" ]]; then
          if tmux has-session -t "$session" 2>/dev/null; then
            tmux switch-client -t "$session"
          else
            tmux new-session -d -s "$session" -c "$PWD"
            tmux switch-client -t "$session"
          fi
        else
          tmux new -As "$session" -c "$PWD"
        fi
      }

      if [[ -n "$TMUX" ]]; then
        stty -ixon 2>/dev/null
        tmux source-file ~/.config/tmux/tmux.conf 2>/dev/null
      fi

      show_cursor() {
        printf '\e[?25h\e[?12h\e[2 q'
        tput cnorm 2>/dev/null
      }
      precmd_functions+=(show_cursor)
      if [[ -n "$TMUX" ]]; then show_cursor; fi

      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

      export PATH="$HOME/.local/bin:$PATH"

      command -v git-wt >/dev/null && eval "$(git-wt --init zsh)"
    '';
  };
}
