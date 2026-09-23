{ ... }:
{
  home.file.".gitconfig".text = ''
    ${builtins.readFile ../../config/git/.gitconfig}
    [gpg "ssh"]
    	program = op-ssh-sign-wsl.exe
  '';

  home.file.".config/git/ignore".source = ../../config/git/ignore;
  home.file.".config/git/hooks/pre-commit" = {
    source = ../../config/git/hooks/pre-commit;
    executable = true;
  };
}
