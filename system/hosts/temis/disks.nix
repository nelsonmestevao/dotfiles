# How temis's disk is laid out, for the next install. Nothing reads this
# while the system runs: ./hardware.nix names the root partition by its UUID.
# disko reads it once, from the installer, on an empty disk.
#
# It makes the root partition with the UUID that ./hardware.nix already names,
# so that file stays as it is and the install needs nothing else:
#
#   sudo nix --extra-experimental-features 'nix-command flakes' run \
#     github:nix-community/disko/latest -- \
#     --mode destroy,format,mount system/hosts/temis/disks.nix
#   sudo nixos-install --flake .#temis
#
# The first command ERASES the disk named in `device`. Check the name with
# `lsblk` first.
{
  disko.devices.disk.main = {
    type = "disk";
    # The server's only disk, the one temis.nix installs GRUB on.
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        # temis starts the old way, with a BIOS and no EFI. On a GPT disk GRUB
        # keeps its second part in this small partition.
        grub = {
          size = "1M";
          type = "EF02";
        };

        # The rest of the disk: the system. There is no swap partition.
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            extraArgs = [
              "-U"
              "a2fb2b46-a482-41a3-bf09-1cf10d31602f"
            ];
          };
        };
      };
    };
  };
}
