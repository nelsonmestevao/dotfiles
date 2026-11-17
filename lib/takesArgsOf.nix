# `takesArgsOf body wrapper` is `wrapper`, asking for every module arg that
# `body` asks for too.
#
# The module system hands a module only the args it names, besides config,
# lib, options and the special args. A wrapper that calls `body args` would
# have to name pkgs, mkSymlink and any later helper itself, just to pass them
# on. With this, body names what it needs, as a plain module does.
body: wrapper: {
  __functor = _: wrapper;
  __functionArgs = builtins.functionArgs wrapper // builtins.functionArgs body;
}
