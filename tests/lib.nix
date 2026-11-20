# Tests for the helpers in lib/ and home/lib/, against the small made-up
# repository in ./fixtures. They only evaluate: nothing is built, and no real
# home is touched.
#
# This returns the cases in nix-unit's shape. The flake gives them as
# `lib.tests`, and nix-unit runs them in the check `lib-tests`, which
# `bin/check --eval` builds. It names each case that fails, even one that
# throws.
{ nixpkgs, home-manager }:
let
  inherit (nixpkgs) lib;

  # ── Fixtures ───────────────────────────────────────────────────────────────

  # Three hosts: box (a NixOS desktop), shed (home-manager only, no roles) and
  # mac (a Mac). alice has a home on box and shed, bob on mac.
  repo = ./fixtures/repo;
  hosts = import (repo + "/config/hosts.nix");
  users = import (repo + "/config/users.nix");

  # One entry changed: `set` adds or replaces fields, `drop` removes one.
  edit =
    entries: name: change:
    entries // { ${name} = change entries.${name}; };
  set = fields: entry: entry // fields;
  drop = field: entry: removeAttrs entry [ field ];

  # True when one sentence holds every word.
  mentions =
    words: sentences: lib.any (sentence: lib.all (word: lib.hasInfix word sentence) words) sentences;

  # ── The data check ─────────────────────────────────────────────────────────

  schema = import ../lib/schema.nix { inherit lib; };
  isMac = system: (import ../lib/roles.nix { inherit lib; }).osOf system == "darwin";
  dataOf = hosts: users: {
    inherit hosts users;
    root = repo;
  };
  check = hosts: users: schema.check (dataOf hosts users);
  problems = hosts: users: schema.problems (dataOf hosts users);
  # The check hands the data back when it passes, and throws when it doesn't.
  passes = hosts: users: check hosts users ? hosts;
  hostProblems = name: change: problems (edit hosts name change) users;

  # The fixture with one mistake.
  brokenHosts = edit hosts "box" (set {
    platform = "nixoss";
  });

  # ── Building the configurations ────────────────────────────────────────────

  # lib/default.nix over some data. Home Manager is replaced by a function
  # that hands back what it was given, so a test can read what a home gets
  # without building it. No test builds a system or a home's modules, so the
  # other inputs are never read and can be left out.
  assemble =
    hosts: users:
    import ../lib {
      inherit hosts users;
      root = repo;
      overlays = [ ];
      inputs = {
        inherit nixpkgs;
        home-manager.lib.homeManagerConfiguration = lib.id;
      };
    };

  # The checks lib/checks.nix makes for a system, by name.
  checksOn =
    hosts: system:
    let
      assembly = assemble hosts users;
    in
    lib.attrNames (
      import ../lib/checks.nix {
        inputs = {
          inherit nixpkgs home-manager;
          self = repo;
        };
        inherit (assembly)
          checkedData
          dataIsRight
          nixosConfigs
          darwinConfigs
          homeConfigs
          ;
      } system
    );

  # What the modules of a home, like "alice@box", get.
  argsOf =
    home: hosts: users:
    (assemble hosts users).homeConfigs.${home}.extraSpecialArgs;
  onBox = argsOf "alice@box" hosts users;
  onShed = argsOf "alice@shed" hosts users;
  onMac = argsOf "bob@mac" hosts users;

  # ── Modules ────────────────────────────────────────────────────────────────

  importModules = import ../lib/importModules.nix { inherit lib; };
  mkHomeModule = import ../home/lib/mkHomeModule.nix;
  mkSystemModule = import ../system/lib/mkSystemModule.nix;

  # The fixture programs, by the folder importModules finds them in.
  programs = "tests/fixtures/programs";
  namesIn = importModules ({ name, ... }: _: name);
  filesIn = importModules ({ file, ... }: _: file);

  # A tiny home on a fixture host, with the fixture programs in the real
  # wrapper and the named ones turned on. homeOn gives its config.
  evalHomeOn =
    hostname: enabled:
    let
      host = hosts.${hostname};
      pkgs = nixpkgs.legacyPackages.${host.system};
    in
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit hostname; };
      modules = [
        ../home/lib
        {
          home.username = "alice";
          home.homeDirectory = if isMac host.system then "/Users/alice" else "/home/alice";
          home.stateVersion = host.stateVersion;
          dotfiles.programs = lib.genAttrs enabled (_: {
            enable = true;
          });
        }
      ]
      ++ importModules mkHomeModule programs
      ++ import ../home/lib/plainPrograms.nix { inherit lib pkgs; }
      ++ import ../home/lib/gnomeExtensions.nix { inherit lib pkgs; };
    };
  homeOn = hostname: enabled: (evalHomeOn hostname enabled).config;

  # Evaluated once: Home Manager checks every assertion of a home it hands
  # back, so each evaluation costs the same as a whole home.
  boxEval = evalHomeOn "box" [
    "demo"
    "links"
  ];
  boxHome = boxEval.config;
  macHome = homeOn "mac" [ "mac-only" ];
  wrongOsHome = homeOn "box" [ "mac-only" ];
  brokenLinkHome = homeOn "box" [ "broken-link" ];
  plainHome = homeOn "box" [ "tokei" ];

  # boxHome with one more module, not wrapped like the fixture programs.
  boxHomeWith = module: (boxEval.extendModules { modules = [ module ]; }).config;

  # The helpers every home module gets, and the link mkSymlink must make: one
  # out of the store, to `target` in the checkout.
  inherit (boxEval._module.args) checkoutPath mkSymlink;
  linksTo =
    target: entry: entry.source.outPath == (boxHome.lib.file.mkOutOfStoreSymlink target).outPath;

  # GNOME (a fixture that imports the real program) with one of the real
  # extensions in plain.nix turned on.
  gnomeHome = boxHomeWith {
    dotfiles.programs.gnome.enable = true;
    dotfiles.programs.gnome.extensions.vitals.enable = true;
  };
  inherit (nixpkgs.legacyPackages.x86_64-linux.gnomeExtensions) vitals printers;

  # The real zsh program (a fixture that imports it), and a home without it.
  zshHome = homeOn "box" [ "zsh" ];
  noZshHome = homeOn "box" [ ];

  # A system module that sets one value, turned on or off.
  systemWith =
    enabled:
    (lib.evalModules {
      specialArgs.pkgs = { };
      modules = [
        { options.environment = lib.mkOption { type = lib.types.attrs; }; }
        { environment.ALWAYS = "on"; }
        { dotfiles.modules.demo.enable = enabled; }
        (mkSystemModule
          {
            name = "demo";
            file = "tests/fixtures/demo.nix";
          }
          (_: {
            environment.DEMO = "on";
          })
        )
      ];
    }).config.environment;

  # ── Scripts ────────────────────────────────────────────────────────────────

  # The kind of a script in ./fixtures/scripts: one of each kind, and a Python
  # one, which is neither.
  scriptKind = import ../lib/scriptKind.nix { inherit lib; } ./fixtures/scripts;

  # ── Cases ──────────────────────────────────────────────────────────────────

  # An expression and the value it must have.
  values = {
    enableForPicksByHostOrRole = {
      expr = {
        host = onBox.enableFor [ "box" ];
        anotherHost = onShed.enableFor [ "box" ];
        role = onBox.enableFor [ "desktop" ];
        aRoleTheHostLacks = onShed.enableFor [ "desktop" ];
        aMix = onShed.enableFor [
          "desktop"
          "shed"
        ];
        disableFor = onBox.disableFor [ "desktop" ];
      };
      expected = {
        host = true;
        anotherHost = false;
        role = true;
        aRoleTheHostLacks = false;
        aMix = true;
        disableFor = false;
      };
    };
    everyHostGetsItsOsAsARole = {
      expr = {
        nixos = onBox.enableFor [ "linux" ];
        homeOnly = onShed.enableFor [ "linux" ];
        mac = onMac.enableFor [ "darwin" ];
        macIsNotLinux = onMac.enableFor [ "linux" ];
        darwinWithNoMacLeft = (argsOf "alice@box" (removeAttrs hosts [ "mac" ]) users).enableFor [
          "darwin"
        ];
      };
      expected = {
        nixos = true;
        homeOnly = true;
        mac = true;
        macIsNotLinux = false;
        darwinWithNoMacLeft = false;
      };
    };
    leftOutFieldsGetTheirDefaults = {
      expr = {
        inherit ((check hosts users).hosts.shed) platform roles darwinStateVersion;
        inherit ((check hosts users).users.bob) extraGroups;
      };
      expected = {
        platform = null;
        roles = [ ];
        darwinStateVersion = null;
        extraGroups = [ ];
      };
    };
    theRulesListEverythingTheyFind = {
      expr = lib.length (
        problems (edit hosts "shed" (set {
          users = [ "alicia" ];
          roles = [ "box" ];
        })) (users // { carol.name = "Carol"; })
      );
      # alicia is unknown, box is a host, and carol has no home file.
      expected = 3;
    };
    theConfigurationsOfTheFixture = {
      expr =
        let
          assembly = assemble hosts users;
        in
        {
          homes = lib.attrNames assembly.homeConfigs;
          nixos = lib.attrNames assembly.nixosConfigs;
          darwin = lib.attrNames assembly.darwinConfigs;
          systems = assembly.hostSystems;
        };
      expected = {
        homes = [
          "alice@box"
          "alice@shed"
          "bob@mac"
        ];
        nixos = [ "box" ];
        darwin = [ "mac" ];
        systems = [
          "x86_64-linux"
          "aarch64-darwin"
        ];
      };
    };
    # With a mistake in the data, the checks are made for all four systems, so
    # the one that reports it shows up on every machine.
    theChecksSurviveBrokenData = {
      expr =
        let
          broken = assemble brokenHosts users;
        in
        broken.hostSystems == broken.toolSystems && !broken.dataIsRight;
      expected = true;
    };
    aHomeGetsItsEntries = {
      expr = {
        hostSystem = onBox.host.system;
        userName = onBox.user.name;
      };
      expected = {
        hostSystem = "x86_64-linux";
        userName = "Alice";
      };
    };
    eachSystemGetsItsChecks = {
      expr = {
        linux = checksOn hosts "x86_64-linux";
        mac = checksOn hosts "aarch64-darwin";
        brokenDataOnIntelMac = checksOn brokenHosts "x86_64-darwin";
      };
      expected = {
        linux = [
          "alice@box"
          "alice@shed"
          "lib-tests"
          "lint"
          "nixos-box"
        ];
        mac = [
          "bob@mac"
          "darwin-mac"
          "lib-tests"
          "lint"
        ];
        brokenDataOnIntelMac = [
          "data"
          "lib-tests"
          "lint"
        ];
      };
    };
    # checkoutPath gives the place in the checkout as a string, for scripts.
    aCheckoutPathIsInTheCheckout = {
      expr = checkoutPath ./fixtures/programs/links/folder/inside.conf;
      expected = "/home/alice/.dotfiles/tests/fixtures/programs/links/folder/inside.conf";
    };
    # A wrapped module gets every module arg it names, not only the ones its
    # wrapper names.
    aWrappedModuleGetsAnyModuleArg = {
      expr =
        (boxHomeWith {
          imports = [
            (mkHomeModule {
              name = "greeter";
              file = "tests/lib.nix";
            } ({ greeting, ... }: { home.sessionVariables.GREETING = greeting; }))
          ];
          _module.args.greeting = "hello";
          dotfiles.programs.greeter.enable = true;
        }).home.sessionVariables.GREETING;
      expected = "hello";
    };
    # The stray notes.md and the `_draft` folder are left out.
    modulesAreFoundByFolder = {
      expr = namesIn programs;
      expected = [
        "broken-link"
        "demo"
        "gnome"
        "idle"
        "links"
        "mac-only"
        "zsh"
      ];
    };
    # ~/.zshrc loads in the order the shell needs: the instant prompt first,
    # zshrc (sourced from the checkout, so an edit needs no rebuild) before
    # oh-my-zsh so its plugins wrap the handlers there, fzf-tab after compinit
    # and before the plugins that wrap widgets, the jump to the `chwd` folder
    # after oh-my-zsh so it lands on the folder stack and in zoxide, and
    # syntax highlighting last.
    zshLoadsInOrder =
      let
        zshrc = zshHome.home.file."./.zshrc".text;
        at = step: lib.stringLength (lib.head (lib.splitString step zshrc));
        steps = [
          "p10k-instant-prompt"
          "source /home/alice/.dotfiles/home/programs/zsh/zshrc"
          "source $ZSH/oh-my-zsh.sh"
          "fzf-tab/fzf-tab.plugin.zsh"
          "zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"
          "&& gtwd"
          "zsh-syntax-highlighting.zsh"
        ];
      in
      {
        expr = lib.sort (a: b: at a < at b) (lib.filter (step: lib.hasInfix step zshrc) steps);
        expected = steps;
      };
    aProgramAppliesOnlyWhereItIsOn = {
      expr = {
        enabled = boxHome.home.sessionVariables.DEMO or null;
        disabled = boxHome.home.sessionVariables ? IDLE;
        onItsOwnOs = macHome.home.sessionVariables.MAC_ONLY or null;
      };
      expected = {
        enabled = "on";
        disabled = false;
        onItsOwnOs = "on";
      };
    };
    aPlainProgramIsAProgramToo = {
      expr = {
        on = lib.elem nixpkgs.legacyPackages.x86_64-linux.tokei plainHome.home.packages;
        off = lib.elem nixpkgs.legacyPackages.x86_64-linux.gvfs plainHome.home.packages;
      };
      expected = {
        on = true;
        off = false;
      };
    };
    # An extension in plain.nix is an extension like one with a folder: turned
    # on, GNOME enables it and its package is installed.
    aPlainExtensionIsAnExtensionToo = {
      expr = {
        enabled = gnomeHome.dotfiles.programs.gnome.enabledExtensions;
        installed = lib.elem vitals gnomeHome.home.packages;
        off = lib.elem printers gnomeHome.home.packages;
      };
      expected = {
        enabled = [ vitals.extensionUuid ];
        installed = true;
        off = false;
      };
    };
    aSystemModuleAppliesOnlyWhenItIsOn = {
      expr = {
        on = systemWith true;
        off = systemWith false;
      };
      expected = {
        on = {
          ALWAYS = "on";
          DEMO = "on";
        };
        off.ALWAYS = "on";
      };
    };
    aShellScript = {
      expr = scriptKind "shell";
      expected = "shell";
    };
    aXonshScript = {
      expr = scriptKind "xonsh";
      expected = "xonsh";
    };
  };

  # Each must be true. Most read the sentence a rule of the schema writes.
  holds = {
    theFixturePasses = passes hosts users;
    aLessCommonSystemPasses = passes (edit hosts "shed" (set {
      system = "riscv64-linux";
    })) users;
    aHomeOnlyHostNeedsNoSystemFiles = problems (hosts // { loft = hosts.shed; }) users == [ ];

    # Turning zsh on adds no activation step, so a switch fetches nothing.
    zshAddsNoActivationStep =
      lib.attrNames zshHome.home.activation == lib.attrNames noZshHome.home.activation;

    anUnknownUserIsNamed = mentions [ "config/hosts.nix: shed.users has \"alicia\"" ] (
      hostProblems "shed" (set {
        users = [ "alicia" ];
      })
    );
    aPlatformMustFitTheSystem =
      mentions
        [ "box.platform is \"darwin\", which needs a darwin system, but box.system is \"x86_64-linux\"" ]
        (
          hostProblems "box" (set {
            platform = "darwin";
            darwinStateVersion = 6;
          })
        );
    aMacNeedsDarwinStateVersion = mentions [ "mac is a Mac, so it needs `darwinStateVersion`" ] (
      hostProblems "mac" (drop "darwinStateVersion")
    );
    aRoleCannotBeNamedLikeAHost = mentions [ "\"shed\" is both a host and a role" ] (
      hostProblems "box" (set {
        roles = [ "shed" ];
      })
    );
    aHostCannotBeNamedLikeAnOsRole = mentions [ "\"linux\" is both a host and a role" ] (
      problems (hosts // { linux = hosts.shed; }) users
    );
    aUserNeedsAHomeFile = mentions [ "config/users.nix: carol needs home/users/carol.nix" ] (
      problems hosts (users // { carol.name = "Carol"; })
    );
    aNixosHostNeedsItsFiles =
      let
        found = problems (hosts // { attic = hosts.box; }) users;
      in
      mentions [ "attic needs system/hosts/attic.nix" ] found
      && mentions [ "attic needs system/hosts/attic/hardware.nix" ] found;

    # importModules hands each wrapper the module's file, from the repo root,
    # for messages. Each one must be there.
    aModuleKnowsItsFile =
      let
        files = filesIn programs;
      in
      lib.elem "tests/fixtures/programs/links/links.nix" files
      && lib.all (file: builtins.readFileType (../. + "/${file}") == "regular") files;

    aLinkPointsIntoTheCheckout =
      linksTo "/home/alice/.dotfiles/tests/fixtures/programs/links/linked.conf"
        boxHome.home.file.".linked";
    aFolderCanBeLinkedAndForced =
      linksTo "/home/alice/.dotfiles/tests/fixtures/programs/links/folder"
        boxHome.home.file.".linked-folder"
      && boxHome.home.file.".linked-folder".force;
    # A checkout somewhere else gets links to it, not to ~/.dotfiles.
    aLinkFollowsTheDotfilesDirectory =
      linksTo "/srv/dots/tests/fixtures/programs/links/linked.conf"
        (boxHomeWith { dotfiles.directory = "/srv/dots"; }).home.file.".linked";
    # Every home module can take mkSymlink, wrapped or not.
    aModuleOutsideTheWrapperCanLink =
      linksTo "/home/alice/.dotfiles/tests/fixtures/programs/links/linked.conf"
        (boxHomeWith (
          { mkSymlink, ... }:
          {
            home.file.".bare" = mkSymlink ./fixtures/programs/links/linked.conf;
          }
        )).home.file.".bare";
  };

  # Each must stop the evaluation with an error that `expectedError.msg`, a
  # regular expression, finds. The text keeps a fixture that breaks for some
  # other reason from passing as a caught mistake.
  stops = {
    # The four typos that used to pass in silence, and others like them.
    aMisspelledPlatform = {
      expr = check brokenHosts users;
      expectedError.msg = "hosts\\.box\\.platform' is not of type";
    };
    aMisspelledField = {
      expr = check (edit hosts "box" (set {
        rolse = [ "desktop" ];
      })) users;
      expectedError.msg = "hosts\\.box\\.rolse' does not exist";
    };
    aMisspelledSystem = {
      expr = check (edit hosts "shed" (set {
        system = "x86-64-linux";
      })) users;
      expectedError.msg = "hosts\\.shed\\.system' is not of type";
    };
    aMissingStateVersion = {
      expr = check (edit hosts "shed" (drop "stateVersion")) users;
      expectedError.msg = "hosts\\.shed\\.stateVersion' was accessed but has no value";
    };
    aUserListedTwice = {
      expr = check (edit hosts "shed" (set {
        users = [
          "alice"
          "alice"
        ];
      })) users;
      expectedError.msg = "hosts\\.shed\\.users' is not of type .*each listed once";
    };
    aRoleListedTwice = {
      expr = check (edit hosts "box" (set {
        roles = [
          "desktop"
          "desktop"
        ];
      })) users;
      expectedError.msg = "hosts\\.box\\.roles' is not of type .*each listed once";
    };
    # A field the schema doesn't know, in a user entry: a typo, or one it has
    # dropped.
    anUnknownUserField = {
      expr = check hosts (
        edit users "alice" (set {
          extraSpecialArgs.tea = "yes";
        })
      );
      expectedError.msg = "users\\.alice\\.extraSpecialArgs' does not exist";
    };
    brokenDataStopsTheHomes = {
      expr = lib.attrNames (assemble brokenHosts users).homeConfigs;
      expectedError.msg = "hosts\\.box\\.platform' is not of type";
    };

    anUnknownNameInEnableFor = {
      expr = onBox.enableFor [ "dekstop" ];
      expectedError.msg = "unknown host or role dekstop";
    };
    aHostWhereTheUserHasNoHome = {
      expr = onBox.enableFor [ "mac" ];
      expectedError.msg = "mac is a host where alice has no home";
    };

    aFolderWithoutItsModule = {
      expr = namesIn "tests/fixtures/broken-modules";
      expectedError.msg = "broken-modules/half-made has no half-made\\.nix";
    };
    aWrongOsProgramNamesItselfAndTheHost = {
      expr = wrongOsHome.home.sessionVariables;
      expectedError.msg = "dotfiles.programs.mac-only only runs on darwin, but it's enabled on box [(]linux[)]";
    };
    aLinkToAMissingFile = {
      expr = brokenLinkHome.home.file.".missing".source;
      expectedError.msg = "broken-link/not-here\\.conf does not exist";
    };
    # The old way, `mkSymlink "file"`, must stop the build.
    aLinkFromAString = {
      expr = (mkSymlink "linked.conf").source;
      expectedError.msg = "mkSymlink takes a path like \\./config [(]no quotes[)]";
    };
    # A path outside the repo has no place in the checkout. The message names
    # the helper, not lib.path.
    aLinkFromOutsideTheRepo = {
      expr = (mkSymlink /nowhere/config).source;
      expectedError.msg = "mkSymlink: /nowhere/config is not in this repo";
    };
    aCheckoutPathToAMissingFile = {
      expr = checkoutPath ./fixtures/programs/links/not-here;
      expectedError.msg = "checkoutPath: tests/fixtures/programs/links/not-here does not exist";
    };

    aScriptOfNeitherKind = {
      expr = scriptKind "python";
      expectedError.msg = "python is neither a shell nor a xonsh script";
    };
  };

  # Every case under the name nix-unit reports it by, like
  # "test values: enableForPicksByHostOrRole". nix-unit runs only the
  # attributes whose name starts with "test".
  casesOf =
    kind: toCase: lib.mapAttrs' (name: case: lib.nameValuePair "test ${kind}: ${name}" (toCase case));
in
casesOf "values" lib.id values
// casesOf "holds" (expr: {
  inherit expr;
  expected = true;
}) holds
// casesOf "stops" lib.id stops
# The docs checks in ./docs.nix, each a list of problems that must be empty.
// casesOf "docs" (problems: {
  expr = problems;
  expected = [ ];
}) (import ./docs.nix { inherit lib; })
