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
  return 127
}
