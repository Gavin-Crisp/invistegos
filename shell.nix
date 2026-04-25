let
  pkgs = import <nixpkgs> { };
in pkgs.mkShell {
  packages = with pkgs; [
    upx
	git
	vim
	openssh_gssapi
	less
	zig
  ];
}
