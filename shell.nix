let
  pkgs = import <nixpkgs> { };
in
  pkgs.mkShell {
    packages = (with pkgs;
      [
        upx
        git
        vim
        openssh_gssapi
        less
        zig
        ncurses.dev
        qemu
      ]
      ++ linux.moduleBuildDependencies
    );
    shellHook = ''
      export KERNELDIR=$(echo ${pkgs.linux.dev}/lib/modules/*/build)
    '';
  }
