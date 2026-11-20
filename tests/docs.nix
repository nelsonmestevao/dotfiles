# The docs have tables that change over time: the scripts in bin/, and the
# hosts. These checks fail when a table leaves one out or names one that is
# gone, so the docs can't quietly fall behind the repo.
#
# Each check is the list of its problems, and tests/lib.nix makes each one a
# case that expects none, so a failure names what is wrong. The docs' links
# are checked by lychee, in the lint check (lib/checks.nix).
{ lib }:
let
  root = ../.;
  read = name: builtins.readFile (root + "/${name}");

  # How the docs name a host's build, from its `platform` in config/hosts.nix.
  buildOf =
    platform:
    if platform == null then
      "Home Manager"
    else
      {
        nixos = "NixOS";
        darwin = "nix-darwin";
      }
      .${platform} or null;

  # ── Text ───────────────────────────────────────────────────────────────────

  # A text without every `char` at its end, or at both ends.
  dropEnd =
    char: text: if lib.hasSuffix char text then dropEnd char (lib.removeSuffix char text) else text;
  strip =
    char: text:
    if lib.hasPrefix char text then strip char (lib.removePrefix char text) else dropEnd char text;

  # Every match of a regular expression in a text, as the list of its groups.
  matches = regex: text: lib.filter lib.isList (builtins.split regex text);

  # The lines of a text without its fenced code blocks (``` or ~~~, indented
  # or not), where a table is only an example. A block ends at
  # the next line that starts with the same fence, and the rest of that line
  # stays. A fence that never closes is an ordinary line.
  linesWithoutBlocks =
    text:
    let
      lines = lib.splitString "\n" text;
      fenceOf = i: builtins.match "[ \t]*(```|~~~)(.*)" (lib.elemAt lines i);
      closingOf =
        i:
        lib.findFirst (j: fenceOf j != null && lib.head (fenceOf j) == lib.head (fenceOf i)) null (
          lib.range (i + 1) (lib.length lines - 1)
        );
      step =
        state: i:
        let
          closing = closingOf i;
        in
        if i < state.next then
          state
        else if fenceOf i == null || closing == null then
          {
            next = i + 1;
            kept = state.kept ++ [ (lib.elemAt lines i) ];
          }
        else
          {
            next = closing + 1;
            kept = state.kept ++ [ (lib.elemAt (fenceOf closing) 1) ];
          };
    in
    (lib.foldl' step {
      next = 0;
      kept = [ ];
    } (lib.range 0 (lib.length lines - 1))).kept;

  # ── Tables ─────────────────────────────────────────────────────────────────

  # A table row's cells, split on the pipes that aren't escaped with `\`.
  cellsOf =
    line:
    let
      pieces = lib.foldl' (
        cells: piece:
        if cells != [ ] && lib.hasSuffix "\\" (lib.last cells) then
          lib.init cells ++ [ "${lib.last cells}|${piece}" ]
        else
          cells ++ [ piece ]
      ) [ ] (lib.splitString "|" (lib.trim line));
    in
    map lib.trim (lib.sublist 1 (lib.max 0 (lib.length pieces - 2)) pieces);

  # The first table whose header starts with `start`, as its header and rows
  # of cells, or null.
  tableIn =
    text: start:
    let
      lines = linesWithoutBlocks text;
      at = lib.lists.findFirstIndex (line: lib.hasPrefix start (lib.trim line)) null lines;
      after = lib.drop (at + 2) lines;
      count = lib.lists.findFirstIndex (
        line: !lib.hasPrefix "|" (lib.trim line)
      ) (lib.length after) after;
    in
    if at == null then
      null
    else
      {
        header = cellsOf (lib.elemAt lines at);
        rows = map cellsOf (lib.take count after);
      };

  hosts = import (root + "/config/hosts.nix");
  sorted = lib.sort lib.lessThan;

  # The hosts table of one doc, against config/hosts.nix.
  hostsTableIn =
    doc:
    let
      table = tableIn (read doc) "| Host ";
      named = map (row: strip "`" (lib.head row)) table.rows;
      twice = lib.unique (lib.filter (name: lib.count (other: other == name) named > 1) named);
      rowProblems =
        row:
        let
          name = strip "`" (lib.head row);
          host = hosts.${name};
          columns = lib.listToAttrs (
            lib.zipListsWith lib.nameValuePair (lib.tail table.header) (lib.tail row)
          );
          build = buildOf (host.platform or null);
          builtWith = columns.Build or "";
          system = columns.System or "nothing";
          roles = map lib.head (matches "`([^`]+)`" columns.Roles);
        in
        if !hosts ? ${name} then
          [ ]
        else if build == null then
          [ "the docs have no name for platform ${host.platform}" ]
        else
          lib.optional (
            system != "`${host.system}`"
          ) "${doc} gives ${name} the system ${system}, not `${host.system}`"
          ++ lib.optional (
            builtWith != build && !lib.hasPrefix "${build} " builtWith
          ) "${doc} gives ${name} the build \"${builtWith}\", not ${build}"
          ++ lib.optional (
            columns ? Roles && sorted roles != sorted (host.roles or [ ])
          ) "${doc} gives ${name} the roles ${columns.Roles}";
    in
    if table == null then
      [ "${doc} has no hosts table (a header starting with \"| Host\")" ]
    else
      map (name: "${doc} lists ${name} twice") twice
      ++ map (name: "${doc} leaves out ${name}") (lib.subtractLists named (lib.attrNames hosts))
      ++ map (name: "${doc} lists ${name}, which config/hosts.nix lacks") (
        lib.subtractLists (lib.attrNames hosts) named
      )
      ++ lib.concatMap rowProblems (lib.filter (row: row != [ ]) table.rows);
in
{
  everyScriptIsInTheScriptsTable =
    let
      table = tableIn (read "README.md") "| Script";
      listed = lib.concatMap (
        row:
        let
          found = builtins.match "`bin/([^` ]+).*" (lib.head row);
        in
        lib.optional (row != [ ] && found != null) (lib.head found)
      ) table.rows;
      scripts = lib.attrNames (builtins.readDir (root + "/bin"));
    in
    if table == null then
      [ "README.md has no scripts table (a header starting with \"| Script\")" ]
    else
      map (name: "bin/${name} is missing from the README's scripts table") (
        lib.subtractLists listed scripts
      )
      ++ map (name: "the README's scripts table lists bin/${name}, which is gone") (
        lib.unique (lib.subtractLists scripts listed)
      );

  theHostsTablesMatchTheData = lib.concatMap hostsTableIn [
    "README.md"
    "AGENTS.md"
  ];
}
