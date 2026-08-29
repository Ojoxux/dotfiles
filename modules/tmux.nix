{ ... }:
{
  programs.tmux = {
    enable = true;
    shell = "/bin/zsh";
    terminal = "screen-256color";
    prefix = "C-a";
    baseIndex = 1;
    mouse = true;
    keyMode = "vi";
    escapeTime = 10;
    focusEvents = true;
    extraConfig = ''
      set-hook -g client-attached 'source-file ~/.config/tmux/tmux.conf \; send-keys -H 1b5b3f3235681b5b322071'
      set-option -g renumber-windows on
      # Monochrome tmux theme
      set-option -g status-position bottom
      set-option -g status-interval 1
      set-option -g status-justify centre
      set-option -g status-style "bg=#0a0a0a,fg=#e6e6e6"
      set-option -g status-left-length 30
      set-option -g status-left '#{?client_prefix,#[fg=#ffffff,bold] CTRL-A ,#[fg=#333333]│ ,}#[fg=#ffffff,bold]#S '
      set-option -g status-right-length 70
      set-option -g status-right '#[fg=#8a8a8a]#(~/.local/bin/tmux-wifi-status) #[fg=#333333]│ #[fg=#e6e6e6]#(pmset -g batt 2>/dev/null | grep -o "[0-9]*%%" | head -1) #[fg=#333333]│ #[fg=#ffffff]%H:%M #[fg=#8a8a8a]%Y-%m-%d(%a)'
      setw -g window-status-style "fg=#8a8a8a"
      setw -g window-status-format " #I:#W "
      setw -g window-status-current-style "fg=#000000,bg=#ffffff,bold"
      setw -g window-status-current-format " #I:#W "
      set -g pane-border-style "fg=#333333"
      set -g pane-active-border-style "fg=#ffffff"
      set -g message-style "bg=#1a1a1a,fg=#e6e6e6,bold"
      set -g message-command-style "bg=#1a1a1a,fg=#ffffff"
      set -g mode-style "bg=#1a1a1a,fg=#ffffff,bold"
      set -g copy-mode-match-style "fg=#000000,bg=#cfcfcf"
      set -g copy-mode-current-match-style "fg=#000000,bg=#ffffff,bold"
      set -g terminal-overrides 'xterm:colors=256'
      set -ga terminal-overrides ",xterm-ghostty:RGB"
      set -as terminal-overrides ",*:Tc"
      set -as terminal-overrides ",*:civis@:cnorm@"

      set-hook -g pane-focus-in 'send-keys -H 1b5b3f3235681b5b322071'
      set-hook -g client-focus-in 'send-keys -H 1b5b3f3235681b5b322071'

      # macOS clipboard integration
      set-option -g set-clipboard on

      # Panes
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5
      bind | split-window -h -c "#{pane_current_path}"
      bind \\ split-window -h -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind o split-window -h -c "#{pane_current_path}"
      bind e split-window -v -c "#{pane_current_path}"
      bind x kill-pane

      # No-prefix shortcuts (left Option + key)
      bind -n M-o split-window -h -c "#{pane_current_path}"
      bind -n M-e split-window -v -c "#{pane_current_path}"
      bind -n M-h select-pane -L
      bind -n M-j select-pane -D
      bind -n M-k select-pane -U
      bind -n M-l select-pane -R

      # Windows (use these instead of Ghostty tabs)
      bind c new-window -c "#{pane_current_path}"
      bind w choose-window
      bind n next-window
      bind p previous-window
      bind , command-prompt -I "#W" "rename-window '%%'"
      bind & confirm-before -p "kill window #I? (y/n)" kill-window

      # Sessions (switch projects without nesting tmux)
      bind s choose-session

      # Copy mode
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi V send -X select-line
      bind -T copy-mode-vi C-v send -X rectangle-toggle
      bind -T copy-mode-vi y send -X copy-selection
      bind -T copy-mode-vi Y send -X copy-line
      bind-key C-p paste-buffer

      bind r run-shell "printf '\\e[?25h\\e[2 q'; tmux display-message 'cursor restored'"
    '';
  };

  home.file.".local/bin/tmux-wifi-status" = {
    executable = true;
    text = ''
      #!/bin/sh
      out=$(networksetup -getairportnetwork en0 2>/dev/null)
      case "$out" in
        *"Current Wi-Fi Network:"*)
          printf '%s' "''${out#Current Wi-Fi Network: }"
          exit 0
          ;;
      esac

      ssid=$(ipconfig getsummary en0 2>/dev/null | sed -n 's/.*SSID : //p' | head -1)
      if [ -n "$ssid" ] && [ "$ssid" != '<redacted>' ]; then
        printf '%s' "$ssid"
        exit 0
      fi

      if ipconfig getifaddr en0 >/dev/null 2>&1; then
        printf 'Wi-Fi'
      fi
    '';
  };
}
