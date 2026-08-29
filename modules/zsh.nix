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
      nixup = "task -d ~/dotfiles apply HOST=powehi";
      tls = "tmux list-sessions";
      treload = "tmux source-file ~/.config/tmux/tmux.conf && tmux display-message 'tmux reloaded'";
      cursor = "printf '\\e[?25h\\e[2 q'";
      sp = "tmux split-window -h";
      sv = "tmux split-window -v";
      ar = "aerospace flatten-workspace-tree";
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

      if [[ -z "$TMUX" && -o interactive && "$TERM_PROGRAM" == "ghostty" ]]; then
        export PATH="/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$PATH"
        exec tmux new -A -s main
      fi

      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

      export PNPM_HOME="$HOME/Library/pnpm"
      case ":$PATH:" in
        *":$PNPM_HOME:"*) ;;
        *) export PATH="$PNPM_HOME:$PATH" ;;
      esac

      [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
      export BUN_INSTALL="$HOME/.bun"
      export PATH="$BUN_INSTALL/bin:$PATH"

      [[ "$TERM_PROGRAM" == "vscode" ]] && . "$(cursor --locate-shell-integration-path zsh)"
      [[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

      [ -f "$HOME/.vite-plus/env" ] && . "$HOME/.vite-plus/env"

      export PATH="$HOME/.local/bin:$PATH"

      # git wt でワークツリーへ自動 cd する（wrapper 関数と補完を読み込む）
      command -v git-wt >/dev/null && eval "$(git-wt --init zsh)"
    '';
  };
}
