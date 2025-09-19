{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  packages = with pkgs; [
    upx
	gnumake
	git
	vim
	openssh_gssapi
  ];
}
