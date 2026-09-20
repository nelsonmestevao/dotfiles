# Host-scoped config fragments, for modules shared across hosts.
{ lib, hostname }:
let
  onHosts = names: attrs: lib.mkIf (builtins.elem hostname names) attrs;
in
{
  inherit onHosts;
  onHost = name: onHosts [ name ];
}
