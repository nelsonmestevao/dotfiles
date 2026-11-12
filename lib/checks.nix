# The flake's checks for one system: lint, the lib tests, and one check per
# configuration that runs on that system.
{
  nixpkgs,
  home-manager,
  self,
  nixosConfigs,
  darwinConfigs,
  homeConfigs,
}:
system:
let
  inherit (nixpkgs) lib;
  pkgs = nixpkgs.legacyPackages.${system};

  runsHere = _: cfg: cfg.pkgs.stdenv.hostPlatform.system == system;

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
    ) (lib.filterAttrs runsHere configs);

  configurations =
    lib.mapAttrs (_: cfg: cfg.activationPackage) (lib.filterAttrs runsHere homeConfigs)
    // systemChecks "nixos" (cfg: cfg.config.system.build.toplevel) nixosConfigs
    // systemChecks "darwin" (cfg: cfg.system) darwinConfigs;

  # The lib tests (tests/lib.nix) run while this is evaluated, so
  # `bin/check --eval` runs them, and a failure names its cases.
  failed = import ../tests/lib.nix { inherit nixpkgs home-manager; };
  describe =
    case:
    "  ${case.name}: expected ${builtins.toJSON case.expected}, got ${builtins.toJSON case.result}";
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
    lib.throwIf (failed != [ ]) "these cases in tests/lib.nix failed:\n${
      lib.concatMapStringsSep "\n" describe failed
    }" ''touch "$out"''
  );
}
# With a mistake in the host or user data, not even the names of the
# configurations can be listed. They become one check that fails with the
# data's message, so lint and the lib tests still run.
// (
  if (builtins.tryEval (lib.attrNames configurations)).success then
    configurations
  else
    { inherit configurations; }
)
