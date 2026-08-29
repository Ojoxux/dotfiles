{ ... }:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    settings = {
      "$schema" = "https://starship.rs/config-schema.json";
      add_newline = true;
      format = "[╭{owo} ](bold green)\$username\$directory\$battery\$all\$line_break\$character";
      character = {
        success_symbol = "[╰─>](bold green)";
        error_symbol = "[x >](bold red)";
      };
      git_branch.format = "[$symbol$branch(:$remote_branch) ]($style)";
      git_status = {
        format = "\$all_status\$ahead_behind ";
        conflicted = "";
        ahead = "";
        behind = "";
        diverged = "";
        up_to_date = "[✓](bold green)";
        untracked = "";
        stashed = "";
        modified = "🔥";
        staged = "";
        renamed = "";
        deleted = "";
      };
      time = {
        disabled = false;
        format = "🕙 [$time]($style) ";
        time_format = "%m/%d %R";
      };
      aws.disabled = true;
      gcloud.disabled = true;
      nodejs.disabled = true;
    };
  };
}
