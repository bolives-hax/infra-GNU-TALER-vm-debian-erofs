{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";

    image-debian-rootfs-tarball = {
      url = "https://jenkins.linuxcontainers.org/job/image-debian/lastStableBuild/architecture=amd64,release=bookworm,variant=cloud/artifact/rootfs.tar.xz";
      flake = false;
      type = "file";
    };
  };

  outputs = {self,nixpkgs,image-debian-rootfs-tarball,...}: let
    pkgs = import nixpkgs {
      system="x86_64-linux";
    };
  in {
    packages.x86_64-linux.default = pkgs.stdenv.mkDerivation {
      name = "taler-debian";

      # we take cmake from pkgs not crossPkgs because
      # it needs to run natively on the builder
      #
      # depsBuildBuild is specific to build helpers/tools
      # such as cmake that need to be run on the host
      # to coordinate the actual build (call the compiler and so on)
      depsBuildBuild = with pkgs; [
        erofs-utils
        libguestfs-with-appliance
        guestfs-tools
        qemu-utils
        cloud-hypervisor
        cpio
        #guestfish #part of libguestfs
      ];


      buildPhase = ''
        install -m 600 ${image-debian-rootfs-tarball} ./rootfs.tar.xz
        ROOTFS_CACHED=1 make build
      '';

      installPhase = "DESTDIR=$out make install";

      # libs native to the target arch 
      nativeBuildInputs = with pkgs; [
        #libguestfs-appli
        #libguestfs
      ];
      src = ./.; # ideally put this in git as then not whole dir is
    };
  };
}
