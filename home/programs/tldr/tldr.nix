{
  ...
}:
{
  # tealdeer is the `tldr` command. It keeps every page on disk, so a page
  # opens at once and works offline.
  programs.tealdeer = {
    enable = true;

    # On a `tldr`, fetch the pages first when the copy on disk is missing or
    # over a month old. So nobody has to run `tldr --update`.
    settings.updates.auto_update = true;

    # Home Manager would also update the pages from a timer. One way is
    # enough.
    enableAutoUpdates = false;
  };
}
