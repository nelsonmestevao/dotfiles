timestamp = fn ->
  {_date, {hour, minute, _second}} = :calendar.local_time
  [hour, minute]
  |> Enum.map(&(String.pad_leading(Integer.to_string(&1), 2, "0")))
  |> Enum.join(":")
end

IEx.configure(
  colors: [
    syntax_colors: [
      number: :light_yellow,
      atom: :light_cyan,
      string: :light_green,
      boolean: :red,
      nil: [:magenta, :bright],
    ],
    ls_directory: :cyan,
    ls_device: :yellow,
    doc_code: :green,
    doc_inline_code: :magenta,
    doc_headings: [:cyan, :underline],
    doc_title: [:cyan, :bright, :underline],
  ],
  default_prompt:
  "#{IO.ANSI.green}%prefix#{IO.ANSI.reset} " <>
    "[#{IO.ANSI.magenta}#{timestamp.()}#{IO.ANSI.reset} " <>
      "#{IO.ANSI.cyan}%counter#{IO.ANSI.reset}] |>",
  alive_prompt:
  "#{IO.ANSI.green}%prefix#{IO.ANSI.reset} " <>
    "(#{IO.ANSI.yellow}%node#{IO.ANSI.reset}) " <>
      "[#{IO.ANSI.magenta}#{timestamp.()}#{IO.ANSI.reset} " <>
        "#{IO.ANSI.cyan}%counter#{IO.ANSI.reset}] |>",
  history_size: 50,
  inspect: [
    pretty: true,
    limit: :infinity,
    width: 80
  ],
  width: 80
  )
