{
  hostname,
  ...
}:
{
  networking.hostName = hostname;

  networking.networkmanager.enable = true;
}
