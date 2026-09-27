{
  config,
  lib,
  pkgs,
  hostname,
  onHost,
  ...
}:
lib.mkMerge [
  {
    networking.hostName = hostname;

    networking.extraHosts = "";

    networking.networkmanager.enable = true;
  }
  (onHost "framework" {
    networking.firewall.enable = true;

    # Allow access to localsend
    networking.firewall.allowedTCPPorts = [
      53317
      53318
    ];
    networking.firewall.allowedUDPPorts = [ 53317 ];

    networking.networkmanager.plugins = with pkgs; [
      networkmanager-openconnect
      networkmanager-openvpn
    ];

    environment.systemPackages = with pkgs; [
      networkmanager-openconnect
      networkmanager-openvpn
    ];
  })
  (onHost "temis" {
    networking.firewall.enable = false;
  })
]
