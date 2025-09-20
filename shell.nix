let
  pkgs = import <nixpkgs> { };
  unstableTarball = fetchTarball
      https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz;
  unstable = import unstableTarball { };
in pkgs.mkShell {
  packages = [
    pkgs.upx
	pkgs.gnumake
	pkgs.git
	pkgs.vim
	pkgs.openssh_gssapi
	pkgs.less
	unstable.zig
  ];
}
