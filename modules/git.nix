{ dotfilesPath, ... }:
{
  home.file = {
    ".gitconfig".source = dotfilesPath "config/git/.gitconfig";
    ".config/git/ignore".source = dotfilesPath "config/git/ignore";
    ".config/git/hooks/pre-commit" = {
      source = dotfilesPath "config/git/hooks/pre-commit";
      executable = true;
    };
  };
}
