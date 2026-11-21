# How framework's disk is laid out, for the next install. Nothing reads this
# while the system runs: ./hardware.nix names the same partitions by their
# UUIDs. disko reads it once, from the installer, on an empty disk.
#
# It makes each partition with the UUID that ./hardware.nix already names, so
# that file stays as it is and the install needs nothing else:
#
#   sudo nix --extra-experimental-features 'nix-command flakes' run \
#     github:nix-community/disko/latest -- \
#     --mode destroy,format,mount system/hosts/framework/disks.nix
#   sudo nixos-install --flake .#framework
#
# The first command ERASES the disk named in `device`. Check the name with
# `lsblk` first. It asks for the passphrase of the encrypted partition.
{
  disko.devices.disk.main = {
    type = "disk";
    # The laptop's only NVMe drive.
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        # The EFI partition, where systemd-boot and the kernels live.
        boot = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [
              "fmask=0077"
              "dmask=0077"
            ];
            # The volume ID that ./hardware.nix knows as 2CDA-2304.
            extraArgs = [
              "-i"
              "2CDA2304"
            ];
          };
        };

        # The rest of the disk: one encrypted partition with the system in it.
        root = {
          size = "100%";
          content = {
            type = "luks";
            name = "luks-bfff715e-9c8d-4a3a-866f-61f5943cc300";
            extraFormatArgs = [
              "--uuid"
              "bfff715e-9c8d-4a3a-866f-61f5943cc300"
            ];
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              extraArgs = [
                "-U"
                "f615d95c-c890-439f-965e-7d0d835471b6"
              ];
            };
          };
        };
      };
    };
  };
}
