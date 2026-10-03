# The vicinae package, with numen built by the same toolchain as vicinae.
#
# Upstream builds vicinae with gcc15Stdenv but numen with the default stdenv
# (GCC 16 on unstable), so linking vicinae-server fails on GLIBCXX_3.4.36
# symbols from libnumen. Drop this once upstream builds both with one stdenv.
vicinae: system:
vicinae.packages.${system}.default.override (old: {
  numen = old.numen.override { stdenv = old.gcc15Stdenv; };
})
