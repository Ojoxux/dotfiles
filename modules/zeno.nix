{ dotfilesPath, pkgs, ... }:
let
  zenoRawSrc = pkgs.fetchFromGitHub {
    owner = "yuki-yano";
    repo = "zeno.zsh";
    rev = "2e8fbecce0fc3692a5fcc9033ecca7ab35263e56";
    hash = "sha256-05+w1WP/SHKp97JTGsvO3csI123U7py+fVSKnAWiUNY=";
  };

  zenoSrc = pkgs.applyPatches {
    name = "zeno.zsh-source";
    src = zenoRawSrc;
    postPatch = ''
      files=$(grep -rl -- '--node-modules-dir=auto' .)
      if [ -z "$files" ]; then
        echo "zeno.zsh: --node-modules-dir=auto が見つからない。上流が変わった可能性がある" >&2
        exit 1
      fi
      substituteInPlace $files \
        --replace-fail '--node-modules-dir=auto' '--node-modules-dir=none'
    '';
  };
in
{
  home.packages = [ pkgs.deno ];

  xdg.configFile."zeno" = { source = dotfilesPath "config/zeno"; recursive = true; };

  programs.zsh.initContent = ''
    source ${zenoSrc}/zeno.zsh
  '';
}
