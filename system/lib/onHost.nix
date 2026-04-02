{ lib, hostname }: name: attrs: lib.mkIf (hostname == name) attrs
