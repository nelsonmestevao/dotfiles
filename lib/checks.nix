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

  # The lib tests (tests/lib.nix) run while this is evaluated, so
  # `bin/check --eval` runs them, and a failure names its cases. They are the
  # same on every system, so they run once.
  failedLibTests = import ../tests/lib.nix { inherit nixpkgs home-manager; };
  show = lib.generators.toPretty { };
  libTestsReport = lib.concatMapStringsSep "\n" (
    case: "  ${case.name}: expected ${show case.expected}, got ${show case.result}"
  ) failedLibTests;

  # The system each configuration runs, from the checked host data. Asking
  # the configuration would evaluate its modules, and a broken Mac module
  # would then hide the Linux checks too.
  systemOfHost = hostname: checkedData.hosts.${hostname}.system;
  systemOfHome = home: systemOfHost (lib.last (lib.splitString "@" home));
in
system:
let
  pkgs = nixpkgs.legacyPackages.${system};
  runningHere = systemOf: lib.filterAttrs (name: _: systemOf name == system);

  # A check that evaluates a system configuration without building it.
  # Working out the top-level derivation's path evaluates every module,
  # option and assertion, which is where configuration errors show up.
  # Building the closure would take hours on a runner. `nix flake check`
  # doesn't know darwinConfigurations at all, so this is the only check the
  # Mac system config gets.
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
# With a mistake in the host or user data, one check, `data`, fails with the
# data's message in place of the configurations. Lint and the lib tests still
# run.
// (if dataIsRight then configurations else { data = checkedData; })
