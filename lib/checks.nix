# The flake's checks for one system: lint, the lib tests, and one check per
# configuration that runs on that system.
{
  nixpkgs,
  home-manager,
  self,
  checkedData,
  dataIsRight,
  nixosConfigs,
  darwinConfigs,
  homeConfigs,
}:
let
  inherit (nixpkgs) lib;

  # The tests in tests/lib.nix run whenever the flake is checked, so
  # `bin/check --eval` runs them, and a failed test is named. They don't
  # depend on the system, so they run once.
  failedLibTests = import ../tests/lib.nix { inherit nixpkgs home-manager; };
  show = lib.generators.toPretty { };
  libTestsReport = lib.concatMapStringsSep "\n" (
    case: "  ${case.name}: expected ${show case.expected}, got ${show case.result}"
  ) failedLibTests;

  # Which system each configuration is for, read from config/hosts.nix.
  # Asking the configuration itself would load its modules, and then a broken
  # Mac module would hide the Linux checks too.
  systemOfHost = hostname: checkedData.hosts.${hostname}.system;
  systemOfHome = home: systemOfHost (lib.last (lib.splitString "@" home));
in
system:
let
  pkgs = nixpkgs.legacyPackages.${system};
  runningHere = systemOf: lib.filterAttrs (name: _: systemOf name == system);

  # Checks a system configuration without building it. Nix still reads every
  # module, option and assertion, which is where mistakes show up; building
  # the whole system would take hours in CI. `nix flake check` skips
  # darwinConfigurations, so this is the only check the Mac system gets.
  evalOnly =
    name: toplevel:
    pkgs.runCommand "eval-${name}" {
      drvPath = builtins.unsafeDiscardStringContext toplevel.drvPath;
    } ''echo "$drvPath" > "$out"'';

  systemChecks =
    prefix: toplevelOf: configs:
    lib.mapAttrs' (
      name: cfg: lib.nameValuePair "${prefix}-${name}" (evalOnly "${prefix}-${name}" (toplevelOf cfg))
    ) (runningHere systemOfHost configs);

  configurations =
    lib.mapAttrs (_: cfg: cfg.activationPackage) (runningHere systemOfHome homeConfigs)
    // systemChecks "nixos" (cfg: cfg.config.system.build.toplevel) nixosConfigs
    // systemChecks "darwin" (cfg: cfg.system) darwinConfigs;
in
{
  # deadnix, statix and nixfmt over every .nix file. CI runs it before the
  # builds, and bin/lint runs it here.
  lint =
    pkgs.runCommand "lint"
      {
        nativeBuildInputs = with pkgs; [
          deadnix
          statix
          nixfmt
        ];
      }
      ''
        cd ${self}
        deadnix --fail .
        statix check .
        nixfmt --check $(find . -name '*.nix')
        touch "$out"
      '';

  lib-tests = pkgs.runCommand "lib-tests" { } (
    lib.throwIf (
      failedLibTests != [ ]
    ) "these cases in tests/lib.nix failed:\n${libTestsReport}" ''touch "$out"''
  );
}
# With a mistake in config/hosts.nix or config/users.nix, one check, `data`,
# fails with the message in place of the configuration checks. Lint and the
# tests still run.
// (if dataIsRight then configurations else { data = checkedData; })
