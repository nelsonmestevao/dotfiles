# ── Hosts ──────────────────────────────────────────────────────────────────
{
  framework = {
    system = "x86_64-linux";
    nixos = true;
    users = [ "nelson" ];
  };
  thinkpad = {
    system = "x86_64-linux";
    users = [ "nelson" ];
  };
  temis = {
    system = "x86_64-linux";
    nixos = true;
    users = [ "nelson" ];
  };
  "Remote-Nelson-Estevao" = {
    system = "aarch64-darwin";
    darwin = true;
    users = [ "nelson.estevao" ];
  };
}
