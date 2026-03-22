{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:
{
  networking.hostName = hostname;

  networking.extraHosts = ''
    127.0.0.1 livecomp.test
  '';

  networking.networkmanager.enable = true;
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openconnect
    networkmanager-openvpn
    networkmanager-vpnc
  ];

  networking.firewall.enable = true;

  # Allow access to localsend
  networking.firewall.allowedTCPPorts = [ 53317 ];
  networking.firewall.allowedUDPPorts = [ 53317 ];

  environment.systemPackages = with pkgs; [
    networkmanager-openconnect
    networkmanager-openvpn
    networkmanager-vpnc
  ];
}
