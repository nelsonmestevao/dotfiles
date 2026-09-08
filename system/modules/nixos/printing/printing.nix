{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.printing.enable = true;

  # The Brother HL-L3240CDW is IPP Everywhere / AirPrint capable and accepts
  # application/pdf natively, so it needs no vendor driver. Avoid cups-browsed:
  # the `implicitclass://` queue it auto-creates silently wedges (queue goes
  # disabled and jobs pile up unfiltered) — declare the queue directly instead.
  services.printing.browsed.enable = false;

  # mDNS, so the printer's .local name resolves without a static DHCP lease.
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;
  services.avahi.openFirewall = true;

  hardware.printers.ensurePrinters = [
    {
      name = "Brother_HL_L3240CDW";
      description = "Brother HL-L3240CDW (driverless IPP)";
      deviceUri = "ipp://BRWACF23CED0E9B.local:631/ipp/print";
      model = "everywhere";
      ppdOptions = {
        PageSize = "A4";
        Duplex = "DuplexNoTumble";
      };
    }
  ];
  hardware.printers.ensureDefaultPrinter = "Brother_HL_L3240CDW";
}
