# The flake's checks for one system: lint, the lib tests, and one check per
# configuration that runs on that system.
{
  inputs,
  checkedData,
  nixosConfigs,
  darwinConfigs,
  homeConfigs,
}:
let
  inherit (inputs) nixpkgs home-manager self;
  inherit (nixpkgs) lib;

  # The scripts in bin/ and .github/scripts/, sorted by ./scriptKind.nix, like
  # { shell = [ "bin/lint" … ]; xonsh = [ "bin/check" … ]; }. A script of
  # neither kind stops the evaluation, so `bin/check --eval` names it too.
  scripts = lib.groupBy (import ./scriptKind.nix { inherit lib; } "${self}") (
    lib.concatMap
      (folder: map (name: "${folder}/${name}") (lib.attrNames (builtins.readDir "${self}/${folder}")))
      [
        "bin"
        ".github/scripts"
      ]
  );

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
  # Every Nix file (deadnix, statix, nixfmt), the shell and xonsh scripts, the
  # zsh files (zsh -n), the workflow (actionlint) and the docs' links (lychee).
  # CI runs it before the builds, and bin/lint runs it here.
  lint =
    pkgs.runCommand "lint"
      {
        nativeBuildInputs = with pkgs; [
          deadnix
          statix
          nixfmt
          shellcheck
          zsh
          actionlint
          lychee
          python3Packages.xonsh
        ];
      }
      ''
        cd ${self}
        deadnix --fail .
        statix check .
        nixfmt --check $(find . -name '*.nix')

        # The shell scripts, and the .sh files next to the programs (not the
        # Herdr mods, which come from upstream, should one ever ship one).
        # Each list is read into a variable first, so a failing find stops
        # the lint instead of quietly checking fewer files.
        shell=(${lib.escapeShellArgs (scripts.shell or [ ])})
        found=$(find home/programs -name '*.sh' -not -path '*/herdr-app/mods/*')
        while IFS= read -r file; do
          [ -n "$file" ] && shell+=("$file")
        done <<< "$found"
        shellcheck "''${shell[@]}"

        # The xonsh scripts, only parsed: their own code doesn't run here.
        xonsh=(${lib.escapeShellArgs (scripts.xonsh or [ ])} scripts/*.xsh)
        HOME=$TMPDIR python3 ${./xonsh-syntax.py} "''${xonsh[@]}"

        # The zsh files, only read: a typo there would break every new shell.
        found=$(find home/programs/zsh -name '*.zsh')
        while IFS= read -r file; do
          [ -n "$file" ] && zsh -n "$file"
        done <<< "$found"
        zsh -n home/programs/zsh/zshrc

        # The workflow, with the shell in its steps checked by shellcheck too.
        actionlint .github/workflows/*.yml

        # The docs' links. Each must point to a file or folder that is here,
        # which holds only what git tracks, and to a heading that exists.
        # --offline leaves the URLs alone: the sandbox has no network. lychee
        # still sets up its web client, which stops without a certificate
        # file, and the Linux sandbox has none.
        SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
          lychee --offline --include-fragments --no-progress --root-dir "$PWD" \
          README.md AGENTS.md ROADMAP.md

        touch "$out"
      '';

  # tests/lib.nix and tests/docs.nix, run by nix-unit, which names each failed
  # case and shows how it differs. --quiet leaves out the cases that pass, so
  # a failed build's last log lines show the ones that failed. The sandbox has
  # no network, so nix-unit gets a store of its own and the inputs the tests
  # read, already in the Nix store. A test that reads another input needs an
  # --override-input here too. They don't depend on the system, but each
  # system runs them, like its CI runner.
  lib-tests = pkgs.runCommand "lib-tests" { nativeBuildInputs = [ pkgs.nix-unit ]; } ''
    export HOME=$TMPDIR
    nix-unit --quiet --eval-store "$HOME" \
      --extra-experimental-features 'nix-command flakes' \
      --override-input nixpkgs ${nixpkgs} \
      --override-input home-manager ${home-manager} \
      --flake ${self}#lib.tests
    touch "$out"
  '';
}
// configurations
