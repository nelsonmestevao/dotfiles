{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    gnumake
  ];

  home.shellAliases = {
    mk = "make";
    mkh = "make help";
    mkl = "make lint";
    mkc = "make clean";
    mkr = "make run";
    mkst = "make setup";
    mkt = "make test";
    mkut = "make unit-tests";
    mkts = "make tests";
  };
}
