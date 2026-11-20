function command_not_found_handler () {
  >&2 echo "
  ┌──────────────────┐
  │ Unknown command! │
  └────. .───────────┘
        V
       ╭─╮
       ⌾ ⌾
       │▕│
       ╰─╯"
  echo -e "\033[44m$1\033[0m"
  echo

  # Say which packages have the command, where nix-index is installed (the
  # nix-index program). The lookup is the one nix-index's own handler does.
  if (( $+commands[nix-locate] )); then
    local -a packages
    packages=(${(f)"$(nix-locate --minimal --no-group --type x --type s --whole-name --at-root "/bin/$1" 2> /dev/null)"})
    if (( $#packages )); then
      packages=(${packages%.out})
      echo "It is in: ${(j:, :)packages}"
      (( $+commands[,] )) && echo "Run it once: , $*"
      echo
    fi
  fi

  return 127
}
