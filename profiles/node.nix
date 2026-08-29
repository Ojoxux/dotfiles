{ vitePlus, ... }:
{
  imports = [ ./base.nix ];

  home.file = {
    ".local/bin/vp".source = "${vitePlus}/bin/vp";
    ".local/bin/vpr".source = "${vitePlus}/bin/vpr";
    ".local/bin/vpx".source = "${vitePlus}/bin/vpx";
    ".local/bin/node".source = "${vitePlus}/bin/vp";
    ".local/bin/npm".source = "${vitePlus}/bin/vp";
    ".local/bin/npx".source = "${vitePlus}/bin/vp";
    ".local/bin/corepack".source = "${vitePlus}/bin/vp";
  };
}
