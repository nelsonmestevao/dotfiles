{ lib, hostname }: names: attrs: lib.mkIf (builtins.elem hostname names) attrs
