{ ... }:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    settings = {
      "$schema" = "https://starship.rs/config-schema.json";
      add_newline = true;
      format = "[╭ λ ](bold green)\$directory\$battery\$all\$line_break\$character";
      character = {
        success_symbol = "[╰─>](bold green)";
        error_symbol = "[x >](bold red)";
      };
      git_branch.format = "[$symbol$branch(:$remote_branch) ]($style)";
      time.disabled = true;
      aws.disabled = true;
      gcloud.disabled = true;
      nodejs.disabled = true;
    };
  };
}
