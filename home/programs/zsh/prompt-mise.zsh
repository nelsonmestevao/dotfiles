# The prompt's `mise` segment: the version of each tool that a file in this
# folder, or a folder above it, asks mise for (.tool-versions, mise.toml).
#
# Powerlevel10k has a segment like this for asdf and none for mise. This one
# is made with what both tools document: `p10k segment` (see `p10k help
# segment`) and `mise ls --json`. p10k.zsh names `mise` among the prompt's
# segments. zshrc loads this file after it, which the colors below need.

# mise's name for a tool, and asdf's name for it. Powerlevel10k's icons and
# the colors in p10k.zsh go by asdf's names. A tool that isn't listed shows
# by its own name, in the plain colors.
typeset -gA prompt_mise_names=(
  dotnet    dotnet-core
  elixir    elixir
  erlang    erlang
  flutter   flutter
  go        golang
  haskell   haskell
  java      java
  julia     julia
  lua       lua
  node      nodejs
  perl      perl
  php       php
  postgres  postgres
  python    python
  ruby      ruby
  rust      rust
)

# Dress each tool the way p10k.zsh dresses it for asdf.
() {
  local setting
  for setting in ${(k)parameters[(I)POWERLEVEL9K_ASDF_*(FORE|BACK)GROUND]}; do
    typeset -g ${setting/ASDF/MISE}=${(P)setting}
  done
}

# What mise was last asked about, and the "tool version" lines it gave.
typeset -g prompt_mise_asked_for=
typeset -ga prompt_mise_found=()

function prompt_mise() {
  (( $+commands[mise] && $+commands[jq] )) || return

  # Ask mise again only in another folder, or when PATH changed, which is how
  # mise makes a tool the current one. Every other prompt reuses the answer.
  local asking_for=$PWD:$PATH
  if [[ $asking_for != $prompt_mise_asked_for ]]; then
    prompt_mise_asked_for=$asking_for
    # The tools a file here or above sets, and that are installed. The ones
    # set for every folder (~/.config/mise) are left out.
    prompt_mise_found=(
      ${(f)"$(
        mise ls --current --local --installed --json 2> /dev/null |
          jq --raw-output 'to_entries[] | "\(.key) \(.value[0].version)"' 2> /dev/null
      )"}
    )
  fi

  local line tool version name
  for line in $prompt_mise_found; do
    tool=${line%% *}
    version=${${line#* }//\%/%%}
    name=$prompt_mise_names[$tool]
    if [[ -n $name ]]; then
      name=${(U)name//-/_}
      p10k segment -s $name -r -i ${name}_ICON -t $version
    else
      p10k segment -t "$tool $version"
    fi
  done
}
