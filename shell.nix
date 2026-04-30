let
  pkgs = import <nixpkgs> { };
in
(pkgs.buildFHSEnv {
  name = "build-env";
  targetPkgs = pkgs: (with pkgs;
    [
      upx
      git
      vim
      openssh_gssapi
      less
      zig
      pkg-config
      ncurses.dev
      qemu
      musl.dev
      clang-tools
      clang
      lld
      llvm
    ]
    ++ pkgs.linux.nativeBuildInputs);
}).env
