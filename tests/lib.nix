# Tests for the helpers in lib/ and home/lib/, against the small made-up
# repository in ./fixtures. They only evaluate: nothing is built, and no real
# home is touched.
#
# lib/checks.nix runs them as the check `lib-tests`, so `bin/check --eval`
# does too. This returns the failed cases; an empty list means all passed.
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

  succeeds = value: (builtins.tryEval value).success;

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
  passes = hosts: users: succeeds (check hosts users);
  hostProblems = name: change: problems (edit hosts name change) users;

  # The fixture as written, and one host entry with one change.
  theFixture = check hosts users;
  inHost = name: change: {
    sound = theFixture;
    broken = check (edit hosts name change) users;
  };

  # ── Building the configurations ────────────────────────────────────────────

  # lib/default.nix over some data. Home Manager is replaced by a function
  # that hands back what it was given, so a test can read what a home gets
  # without building it. Only the arguments lib/default.nix asks for are
  # passed, so this keeps working when it gains or loses a flake input.
  assemble =
    hosts: users:
    let
      assembly = import ../lib;
    in
    assembly (
      lib.intersectAttrs (lib.functionArgs assembly) {
        inherit nixpkgs hosts users;
        root = repo;
        overlays = [ ];
        home-manager.lib.homeManagerConfiguration = lib.id;
        nix-darwin = { };
      }
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
  namesIn = folder: builtins.deepSeq (importModules ({ name, ... }: _: name) folder) true;

  # A tiny home on a fixture host, with the fixture programs in the real
  # wrapper and the named ones turned on.
  homeOn =
    hostname: enabled:
    let
      host = hosts.${hostname};
    in
    (home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${host.system};
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
      ++ importModules mkHomeModule programs;
    }).config;

  boxHome = homeOn "box" [
    "demo"
    "links"
  ];
  macHome = homeOn "mac" [ "mac-only" ];
  wrongOsHome = homeOn "box" [ "mac-only" ];
  brokenLinkHome = homeOn "box" [ "broken-link" ];

  # What a program's wrapper complains about on a host. Home Manager turns a
  # failed assertion into an error, whose text can't be read back, so this
  # evaluates the wrapped program on its own.
  complaintsOf =
    hostname: name:
    let
      wrapped = lib.evalModules {
        specialArgs = {
          inherit hostname;
          pkgs.stdenv.hostPlatform.isDarwin = isMac hosts.${hostname}.system;
        };
        modules = [
          {
            options.assertions = lib.mkOption { type = lib.types.listOf lib.types.attrs; };
            options.home = lib.mkOption { type = lib.types.attrs; };
            config.dotfiles.programs.${name}.enable = true;
          }
          (mkHomeModule {
            inherit name;
            folder = "${programs}/${name}";
          } (import (./fixtures/programs + "/${name}/${name}.nix")))
        ];
      };
    in
    map (assertion: assertion.message) (
      lib.filter (assertion: !assertion.assertion) wrapped.config.assertions
    );

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
            folder = "tests/fixtures";
          }
          (_: {
            environment.DEMO = "on";
          })
        )
      ];
    }).config.environment;

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
        inherit ((check hosts users).users.bob) extraGroups extraSpecialArgs;
      };
      expected = {
        platform = null;
        roles = [ ];
        darwinStateVersion = null;
        extraGroups = [ ];
        extraSpecialArgs = { };
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
          broken = assemble (edit hosts "box" (set {
            platform = "nixoss";
          })) users;
        in
        broken.hostSystems == broken.toolSystems && !broken.dataIsRight;
      expected = true;
    };
    aHomeGetsItsEntriesAndArguments = {
      expr = {
        hostSystem = onBox.host.system;
        userName = onBox.user.name;
        ownArgument =
          (argsOf "alice@box" hosts (
            edit users "alice" (set {
              extraSpecialArgs.tea = "yes";
            })
          )).tea;
      };
      expected = {
        hostSystem = "x86_64-linux";
        userName = "Alice";
        ownArgument = "yes";
      };
    };
    # The stray notes.md and the `_draft` folder are left out.
    modulesAreFoundByFolder = {
      expr = importModules ({ name, ... }: _: name) programs;
      expected = [
        "broken-link"
        "demo"
        "idle"
        "links"
        "mac-only"
      ];
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
  };

  # Each must be true. Most read the sentence a rule of the schema writes.
  holds = {
    theFixturePasses = passes hosts users;
    aLessCommonSystemPasses = passes (edit hosts "shed" (set {
      system = "riscv64-linux";
    })) users;
    aHomeOnlyHostNeedsNoSystemFiles = problems (hosts // { loft = hosts.shed; }) users == [ ];

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
    aUserCannotTakeAModuleArgument = mentions [ "alice.extraSpecialArgs can't use \"host\"" ] (
      problems hosts (
        edit users "alice" (set {
          extraSpecialArgs.host = "mine";
        })
      )
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

    aWrongOsProgramNamesItselfAndTheHost = mentions [
      "dotfiles.programs.mac-only only runs on darwin, but it's enabled on box (linux)"
    ] (complaintsOf "box" "mac-only");
  };

  # Each `broken` must stop the evaluation while `sound`, the same thing
  # without the mistake, goes through. An error's text can't be read back, so
  # the pair is what keeps a broken fixture from passing as a caught mistake.
  stops = {
    # The four typos that used to pass in silence, and others like them.
    aMisspelledPlatform = inHost "box" (set {
      platform = "nixoss";
    });
    aMisspelledField = inHost "box" (set {
      rolse = [ "desktop" ];
    });
    aMisspelledSystem = inHost "shed" (set {
      system = "x86-64-linux";
    });
    aMissingStateVersion = inHost "shed" (drop "stateVersion");
    aUserListedTwice = inHost "shed" (set {
      users = [
        "alice"
        "alice"
      ];
    });
    aRoleListedTwice = inHost "box" (set {
      roles = [
        "desktop"
        "desktop"
      ];
    });
    brokenDataStopsTheHomes = {
      sound = lib.attrNames (assemble hosts users).homeConfigs;
      broken =
        lib.attrNames
          (assemble (edit hosts "box" (set {
            platform = "nixoss";
          })) users).homeConfigs;
    };

    anUnknownNameInEnableFor = {
      sound = onBox.enableFor [ "desktop" ];
      broken = onBox.enableFor [ "dekstop" ];
    };
    aHostWhereTheUserHasNoHome = {
      sound = onBox.enableFor [ "shed" ];
      broken = onBox.enableFor [ "mac" ];
    };

    aFolderWithoutItsModule = {
      sound = namesIn programs;
      broken = namesIn "tests/fixtures/broken-modules";
    };
    aProgramOnTheWrongOs = {
      sound = boxHome.home.sessionVariables;
      broken = wrongOsHome.home.sessionVariables;
    };
    aLinkToAMissingFile = {
      sound = boxHome.home.file.".linked".source;
      broken = brokenLinkHome.home.file.".missing".source;
    };
  };

  casesOf =
    kind: toCase: lib.mapAttrs' (name: case: lib.nameValuePair "test ${kind}: ${name}" (toCase case));

  # Like lib.runTests, but a test that fails with an error is reported by name,
  # instead of stopping every test. (A missing attribute still stops them
  # all: Nix can only catch errors raised with `throw`.)
  failedCases =
    cases:
    lib.concatLists (
      lib.mapAttrsToList (
        name: case:
        let
          got = builtins.tryEval (builtins.deepSeq case.expr case.expr);
        in
        lib.optional (!got.success || got.value != case.expected) {
          inherit name;
          inherit (case) expected;
          result = if got.success then got.value else "an error";
        }
      ) cases
    );
in
failedCases (
  casesOf "values" lib.id values
  // casesOf "holds" (expr: {
    inherit expr;
    expected = true;
  }) holds
  // casesOf "stops" (case: {
    expr = {
      sound = succeeds case.sound;
      broken = !succeeds case.broken;
    };
    expected = {
      sound = true;
      broken = true;
    };
  }) stops
)
