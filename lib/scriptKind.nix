# The kind of a script, read from its first line: "shell" or "xonsh". The lint
# check sorts the scripts in bin/ and .github/scripts/ with it. Anything else
# stops the evaluation and names the script, so a new kind of script can't
# slip through unchecked.
{ lib }:
root: path:
let
  line = lib.head (lib.splitString "\n" (builtins.readFile (root + "/${path}")));
in
if builtins.match "#!.*xonsh.*" line != null then
  "xonsh"
else if builtins.match "#!.*(bash.*|[/ ]sh( .*)?)" line != null then
  "shell"
else
  throw "${path} is neither a shell nor a xonsh script"
