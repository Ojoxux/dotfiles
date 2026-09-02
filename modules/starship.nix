{ ... }:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    settings = {
      "$schema" = "https://starship.rs/config-schema.json";
      palette = "koda_monochrome";
      palettes.koda_monochrome = {
        fg = "#a6a6a6";
        fg_bright = "#e0e0e0";
        fg_dim = "#8a8a8a";
        accent = "#c4c4c4";
        alert = "#ffffff";
        purple = "#a855f7";
      };
      add_newline = true;
      format = "[╭ ](bold fg_bright)[{](bold fg_dim)[λ](bold purple)[}](bold fg_dim)[ ](bold fg_bright)\$directory\$battery\$all\$line_break\$character";
      character = {
        success_symbol = "[╰─>](bold accent)";
        error_symbol = "[x >](bold alert)";
      };
      directory.style = "bold fg";
      git_branch = {
        format = "[$symbol$branch(:$remote_branch) ]($style)";
        style = "bold accent";
      };
      git_status.style = "bold fg_dim";
      time.disabled = true;
      aws.disabled = true;
      gcloud.disabled = true;
      nodejs.disabled = true;
    };
  };
}
