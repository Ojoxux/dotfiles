{ pkgs, ... }:
{
  imports = [ ./base.nix ];

  home.file = {
    ".local/bin/rustup".source = "${pkgs.rustup}/bin/rustup";
    ".local/bin/cargo".source = "${pkgs.rustup}/bin/cargo";
    ".local/bin/cargo-clippy".source = "${pkgs.rustup}/bin/cargo-clippy";
    ".local/bin/cargo-fmt".source = "${pkgs.rustup}/bin/cargo-fmt";
    ".local/bin/cargo-miri".source = "${pkgs.rustup}/bin/cargo-miri";
    ".local/bin/clippy-driver".source = "${pkgs.rustup}/bin/clippy-driver";
    ".local/bin/rls".source = "${pkgs.rustup}/bin/rls";
    ".local/bin/rust-analyzer".source = "${pkgs.rustup}/bin/rust-analyzer";
    ".local/bin/rust-gdb".source = "${pkgs.rustup}/bin/rust-gdb";
    ".local/bin/rust-gdbgui".source = "${pkgs.rustup}/bin/rust-gdbgui";
    ".local/bin/rust-lldb".source = "${pkgs.rustup}/bin/rust-lldb";
    ".local/bin/rustc".source = "${pkgs.rustup}/bin/rustc";
    ".local/bin/rustdoc".source = "${pkgs.rustup}/bin/rustdoc";
    ".local/bin/rustfmt".source = "${pkgs.rustup}/bin/rustfmt";
  };
}
