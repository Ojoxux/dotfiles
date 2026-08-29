{
  description = "nix-darwin + home-manager (dotfiles)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate = {
      url = "github:DeterminateSystems/determinate";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs.brew-api.follows = "brew-api";
      inputs.nix-darwin.follows = "nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };

    nix-vite-plus = {
      url = "github:ryoppippi/nix-vite-plus";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, determinate, brew-nix, nix-vite-plus, ... }:
    let
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;

      mkHost = { file, username }: nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          determinate.darwinModules.default
          brew-nix.darwinModules.default
          home-manager.darwinModules.home-manager
          { brew-nix.enable = true; }
          file
        ];
        specialArgs = {
          inherit username;
          dotfilesPath = path: "/Users/${username}/dotfiles/${path}";
          vitePlus = nix-vite-plus.packages.aarch64-darwin.vp;
        };
      };
    in
    {
      darwinConfigurations.powehi = mkHost { file = ./hosts/powehi.nix; username = "Ojoxux"; };

      darwinConfigurations.local = mkHost {
        file = ./hosts/local.nix;
        username =
          let sudoUser = builtins.getEnv "SUDO_USER";
          in if sudoUser != "" then sudoUser else builtins.getEnv "USER";
      };

      darwinConfigurations.check = mkHost {
        file = ./hosts/local.example.nix;
        username = "Ojoxux";
      };

      apps.aarch64-darwin = {
        switch = {
          type = "app";
          program = toString (pkgs.writeShellScript "switch" ''
            set -euo pipefail
            exec "$HOME/dotfiles/apply.sh" "$@"
          '');
        };

        build = {
          type = "app";
          program = toString (pkgs.writeShellScript "build" ''
            set -euo pipefail
            if [ -z "''${1:-}" ]; then
              echo "Error: no host specified." >&2
              echo "Usage: nix run .#build -- <host>" >&2
              exit 1
            fi
            HOST="$1"
            echo "Building nix-darwin configuration (dry run)..."
            sudo ${nix-darwin.packages.aarch64-darwin.default}/bin/darwin-rebuild build \
              --flake "$HOME/dotfiles#$HOST" --impure
            echo "Build successful!"
          '');
        };

        update = {
          type = "app";
          program = toString (pkgs.writeShellScript "update" ''
            set -euo pipefail
            echo "Updating flake inputs..."
            nix flake update "$HOME/dotfiles"
            echo "Done! Run 'task apply HOST=<host>' to apply."
          '');
        };
      };
    };
}
