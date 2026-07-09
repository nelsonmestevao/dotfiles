{
  config,
  lib,
  pkgs,
  onHost,
  ...
}:
lib.mkMerge [
  {
    time.timeZone = "Europe/Lisbon";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "pt_PT.UTF-8";
      LC_IDENTIFICATION = "pt_PT.UTF-8";
      LC_MEASUREMENT = "pt_PT.UTF-8";
      LC_MONETARY = "pt_PT.UTF-8";
      LC_NAME = "pt_PT.UTF-8";
      LC_NUMERIC = "pt_PT.UTF-8";
      LC_PAPER = "pt_PT.UTF-8";
      LC_TELEPHONE = "pt_PT.UTF-8";
      LC_TIME = "pt_PT.UTF-8";
    };
  }
  (onHost "framework" {
    services.xserver.xkb.layout = "pt";
    console.keyMap = "pt-latin1";
  })
  (onHost "temis" {
    services.xserver.xkb.layout = "us";
    console.keyMap = "us";
  })
]
