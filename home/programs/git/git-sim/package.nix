# git-sim 0.4.0, while nixpkgs still ships 0.3.5.
#
# 0.4.0 draws static images with skia-python, which nixpkgs doesn't package,
# so it comes from PyPI's prebuilt wheels. It also needs mcp >= 2 (only
# nixpkgs-unstable has it, as mcp_2) and git-dummy >= 0.2, which is why
# everything here builds against unstable. Manim and OpenCV are kept so
# `git-sim --animate` still works.
{ pkgs }:
let
  inherit (pkgs.unstable)
    lib
    stdenv
    fetchFromGitHub
    fetchPypi
    python3Packages
    ;

  skia-python = python3Packages.buildPythonPackage rec {
    pname = "skia-python";
    version = "144.1";
    format = "wheel";

    # Wheels are per Python ABI: bump these when unstable's python3 moves on.
    src = fetchPypi (
      {
        pname = "skia_python";
        inherit version format;
        dist = "cp314";
        python = "cp314";
        abi = "cp314";
      }
      // {
        x86_64-linux = {
          platform = "manylinux_2_28_x86_64";
          hash = "sha256-X1KGJBP645dMH/768iIGr0wN6MuZEv+2YuqseNeUdG4=";
        };
        aarch64-darwin = {
          platform = "macosx_11_0_arm64";
          hash = "sha256-NhLv+YlRfkETHoLnG4oIbtCPCHHq6Om92Lsz+GqYLDo=";
        };
      }
      .${stdenv.hostPlatform.system}
    );

    nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ pkgs.unstable.autoPatchelfHook ];

    buildInputs = lib.optionals stdenv.hostPlatform.isLinux (
      with pkgs.unstable;
      [
        expat
        libGL
        stdenv.cc.cc.lib
        zlib
      ]
    );

    dependencies = with python3Packages; [
      numpy
      pybind11
    ];

    pythonImportsCheck = [ "skia" ];
  };

  git-dummy = python3Packages.git-dummy.overridePythonAttrs {
    version = "0.2.1";
    src = fetchFromGitHub {
      owner = "initialcommit-com";
      repo = "git-dummy";
      tag = "v0.2.1";
      hash = "sha256-YDbBl4zQVCXJ/LHi6w7Ai/7EkpAKni3jaeCIUcURsnc=";
    };
    # 0.2 dropped typer's --show-completion, which nixpkgs' postInstall calls.
    postInstall = "";
  };

  # unstable's manim isn't cached because this test fails: it compares the
  # usage line verbatim, and newer click prints `[COMMAND]` instead of `COMMAND`.
  manim = python3Packages.manim.overridePythonAttrs (old: {
    disabledTests = (old.disabledTests or [ ]) ++ [ "test_manim_init_subcommand" ];
  });
in
python3Packages.buildPythonApplication (finalAttrs: {
  pname = "git-sim";
  version = "0.4.0";
  pyproject = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "initialcommit-com";
    repo = "git-sim";
    tag = "v${finalAttrs.version}";
    hash = "sha256-A4BqTnxGZut4/qfVR0y10qfspT2QTbZG0S1m9NVKyNI=";
  };

  build-system = with python3Packages; [ setuptools ];

  dependencies = [
    git-dummy
    skia-python
    # the 'extras' install, for --animate
    manim
    python3Packages.opencv4
  ]
  ++ (with python3Packages; [
    fonttools
    gitpython
    mcp_2
    numpy
    pydantic-settings
    typer
  ]);

  # https://github.com/NixOS/nixpkgs/commit/8033561015355dd3c3cf419d81ead31e534d2138
  makeWrapperArgs = [
    "--prefix"
    "PYTHONWARNINGS"
    ","
    "ignore:::pydub.utils:"
  ];

  nativeBuildInputs = [ pkgs.unstable.installShellFiles ];

  postInstall =
    # https://github.com/NixOS/nixpkgs/issues/308283
    lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform)
      # Otherwise, typer ignores the requested shell and detects it by walking
      # the process tree, which yields bash on linux and fails on darwin.
      ''
        export _TYPER_COMPLETE_TEST_DISABLE_SHELL_DETECTION=1
        installShellCompletion --cmd git-sim \
          --bash <($out/bin/git-sim --show-completion bash) \
          --fish <($out/bin/git-sim --show-completion fish) \
          --zsh <($out/bin/git-sim --show-completion zsh)
      ''
    + ''
      ln -s ${lib.getExe git-dummy} $out/bin/
    '';

  # The e2e tests render images and compare them against reference files.
  doCheck = false;

  meta = {
    description = "Visually simulate Git operations in your own repos with a single terminal command";
    homepage = "https://initialcommit.com/tools/git-sim";
    changelog = "https://github.com/initialcommit-com/git-sim/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.gpl2Only;
    mainProgram = "git-sim";
  };
})
