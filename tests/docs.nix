# The docs name files, scripts and hosts that change over time. These checks
# fail when README.md, AGENTS.md or ROADMAP.md names one that is gone or leaves
# one out, so the docs can't quietly fall behind the repo.
#
# Each check is the list of its problems, and tests/lib.nix makes each one a
# case that expects none, so a failure names what is wrong. The repo here is
# the flake's source, which holds only the files git tracks: a link to an
# untracked file fails, as it would on GitHub. Names are looked up in
# builtins.readDir, case and all, because a Mac's disk is case-blind and a
# plain path check there would pass a link that GitHub can't follow.
{ lib }:
let
  root = ../.;
  read = name: builtins.readFile (root + "/${name}");
  docs = [
    "README.md"
    "AGENTS.md"
    "ROADMAP.md"
  ];

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
  # or not), where a link or a `#` line is only an example. A block ends at
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

  # The text without any code: blocks, and inline spans too.
  prose =
    text:
    lib.concatMapStringsSep "\n" (
      line: lib.concatStrings (lib.filter lib.isString (builtins.split "`[^`]*`" line))
    ) (linesWithoutBlocks text);

  # ── Links ──────────────────────────────────────────────────────────────────

  # Every link target: inline `[x](target "title")`, reference `[x]: target`,
  # and the `src`, `srcset` and `href` of the HTML in the README.
  linksIn =
    text:
    let
      words = prose text;
      inline = map lib.head (matches "[]][(]<?([^)>[:space:]]+)>?([[:space:]]+\"[^\"]*\")?[)]" words);
      # The target may sit in <>, which is not part of it.
      unwrap =
        target:
        let
          bare = if lib.stringLength target > 1 then lib.removePrefix "<" target else target;
        in
        if lib.stringLength bare > 1 then lib.removeSuffix ">" bare else bare;
      reference = lib.concatMap (
        line:
        let
          found = builtins.match "[[:space:]]*[[][^]]+[]]:[[:space:]]*([^[:space:]]+)([[:space:]]+\"[^\"]*\")?[[:space:]]*" line;
        in
        lib.optional (found != null) (unwrap (lib.head found))
      ) (lib.splitString "\n" words);
      html = map (found: lib.elemAt found 1) (matches "(src|srcset|href)=\"([^\"]+)\"" words);
    in
    inline ++ reference ++ html;

  # True when the repo has this file or folder, each name in it written
  # exactly.
  exists =
    path:
    let
      walk =
        folder: names:
        let
          entries = builtins.readDir folder;
          name = lib.head names;
        in
        entries ? ${name}
        && (
          lib.tail names == [ ]
          || entries.${name} == "directory" && walk (folder + "/${name}") (lib.tail names)
        );
    in
    walk root (lib.splitString "/" path);

  # GitHub's anchor for a heading: its words in lower case, links reduced to
  # their text, anything but letters, digits, `_`, spaces and hyphens dropped,
  # then each space a hyphen. "📄 License" is #-license. Only ASCII letters
  # stay: GitHub keeps a letter like é too, but no heading here has one.
  slug =
    heading:
    let
      linkText = found: lib.head found;
      plain = lib.concatMapStrings (part: if lib.isList part then linkText part else part) (
        builtins.split "[[]([^]]*)[]][(][^)]*[)]" heading
      );
      kept = lib.concatStrings (
        lib.filter lib.isString (builtins.split "[^a-z0-9_ -]" (lib.toLower (lib.trim (dropEnd "#" plain))))
      );
    in
    lib.replaceStrings [ " " ] [ "-" ] kept;

  # The `#name` targets a doc has: its `id` attributes and its headings. A
  # repeated heading gets -1, -2 and so on, as on GitHub.
  anchorsIn =
    text:
    let
      ids = map (found: lib.elemAt found 1) (matches "(^|[^[:alnum:]_])id=\"([^\"]+)\"" text);
      headings = lib.concatMap (
        line:
        let
          found = builtins.match "#+[[:space:]]+(.+)" line;
        in
        lib.optional (found != null) (slug (lib.head found))
      ) (linesWithoutBlocks text);
      numbered =
        (lib.foldl'
          (state: name: {
            seen = state.seen // {
              ${name} = (state.seen.${name} or 0) + 1;
            };
            names = state.names ++ [
              (if state.seen ? ${name} then "${name}-${toString state.seen.${name}}" else name)
            ];
          })
          {
            seen = { };
            names = [ ];
          }
          headings
        ).names;
    in
    lib.genAttrs (ids ++ numbered) (_: true);

  # Each link of the docs that isn't a URL, split into the file and the
  # anchor. A link with no file points into its own doc.
  links = lib.concatMap (
    doc:
    lib.concatMap (
      target:
      let
        pieces = lib.splitString "#" target;
        scheme = lib.splitString ":" target;
        path = strip "/" (lib.head pieces);
      in
      lib.optional (lib.length scheme == 1 || builtins.match "[a-z]+" (lib.head scheme) == null) {
        inherit doc path;
        anchor = lib.concatStringsSep "#" (lib.tail pieces);
        file = if path == "" then doc else path;
      }
    ) (linksIn (read doc))
  ) docs;

  # The anchors of each doc a link points into, read once.
  anchorsOf = lib.genAttrs (lib.unique (
    map (link: link.file) (
      lib.filter (link: link.anchor != "" && lib.hasSuffix ".md" link.file && exists link.file) links
    )
  )) (file: anchorsIn (read file));

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
  everyLinkPointsToSomething = lib.concatMap (
    link:
    lib.optional (
      link.path != "" && !exists link.path
    ) "${link.doc} links to ${link.path}, which git does not track"
    ++ lib.optional (
      link.anchor != "" && anchorsOf ? ${link.file} && !anchorsOf.${link.file} ? ${link.anchor}
    ) "${link.doc} links to ${link.file}#${link.anchor}, which it lacks"
  ) links;

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
