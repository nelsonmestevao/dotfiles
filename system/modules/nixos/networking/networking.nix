{
  hostname,
  ...
}:
{
  networking.hostName = hostname;

  networking.extraHosts = "";

  networking.networkmanager.enable = true;
}
