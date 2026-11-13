{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    pdfmixtool
  ];
}
