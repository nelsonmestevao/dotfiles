# What changed between two versions of a flake.lock. bin/update hands it the
# lock's text from before and after `nix flake update`:
#
#   nix-instantiate --eval --strict --json lib/lockChanges.nix --argstr before … --argstr after …
#
# and turns the list into its summary and commit. Each change is
# { name, kind, old, new, page, compare }:
#
# - name: the input's path, like "vicinae/numen" for an input of an input.
# - kind: "updated", "added" or "removed".
# - old, new: null, or the pin { rev, lastModified, ref }. ref is what to show
#   when there is no rev, like "follows 'nixpkgs'".
# - page: the repo's page on GitHub, GitLab or sourcehut, else null.
# - compare: a link that compares the two commits, else null.
#
# The list is in nix's own order. It uses only builtins, so it needs no nixpkgs.
{ before, after }:
let
  inherit (builtins)
    attrNames
    attrValues
    concatMap
    concatStringsSep
    filter
    fromJSON
    head
    isList
    listToAttrs
    sort
    tail
    ;

  # Every input of a lock, keyed by its path joined with "/", as
  # { path, value }. value is the input's `locked` attributes, or
  # { follows = "nixpkgs"; } for an input that follows another.
  inputsOf =
    text:
    let
      lock = fromJSON text;
      walk =
        node: prefix:
        concatMap (
          name:
          let
            target = lock.nodes.${node}.inputs.${name};
            path = prefix ++ [ name ];
          in
          # A list is the path of the input this one follows.
          if isList target then
            [
              {
                inherit path;
                value.follows = concatStringsSep "/" target;
              }
            ]
          else
            [
              {
                inherit path;
                value = lock.nodes.${target}.locked;
              }
            ]
            ++ walk target path
        ) (attrNames (lock.nodes.${node}.inputs or { }));
    in
    listToAttrs (
      map (input: {
        name = concatStringsSep "/" input.path;
        value = input;
      }) (walk lock.root [ ])
    );

  old = inputsOf before;
  new = inputsOf after;

  # Nix sorts paths name by name, so vicinae/numen comes before
  # vicinae-extensions. Sorting the joined names would swap them.
  sortsBefore =
    a: b:
    if a == [ ] || b == [ ] then
      b != [ ]
    else if head a == head b then
      sortsBefore (tail a) (tail b)
    else
      head a < head b;

  sites = {
    github = "https://github.com";
    gitlab = "https://gitlab.com";
    sourcehut = "https://git.sr.ht";
  };
  # sourcehut has no page that compares two commits.
  compareAt = {
    github = "/compare/";
    gitlab = "/-/compare/";
  };
  pageOf =
    value:
    if sites ? ${value.type or ""} then "${sites.${value.type}}/${value.owner}/${value.repo}" else null;

  pinOf =
    value:
    if value == null then
      null
    else
      {
        rev = value.rev or null;
        lastModified = value.lastModified or null;
        ref = if value ? follows then "follows '${value.follows}'" else value.url or value.type;
      };

  pairs = map (
    path:
    let
      name = concatStringsSep "/" path;
    in
    {
      inherit name;
      was = old.${name}.value or null;
      is = new.${name}.value or null;
    }
  ) (sort sortsBefore (map (input: input.path) (attrValues (old // new))));

  # An input that only follows another pins nothing, so there's nothing to
  # say when it comes or goes. It shows when it gains or drops a pin of its
  # own.
  changed =
    { was, is, ... }: was != is && !(was == null && is ? follows) && !(is == null && was ? follows);
in
map (
  {
    name,
    was,
    is,
  }:
  {
    inherit name;
    kind =
      if was == null then
        "added"
      else if is == null then
        "removed"
      else
        "updated";
    old = pinOf was;
    new = pinOf is;
    page = if pageOf is != null then pageOf is else pageOf was;
    compare =
      if was ? rev && compareAt ? ${is.type or ""} then
        "${pageOf is}${compareAt.${is.type}}${was.rev}...${is.rev}"
      else
        null;
  }
) (filter changed pairs)
