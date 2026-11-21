# The prompt's `mise` segment: the version of each tool that a file in this
# folder, or a folder above it, asks mise for (.tool-versions, mise.toml).
#
# Powerlevel10k has a segment like this for asdf and none for mise. This one
# is made with what both tools document: `p10k segment` (see `p10k help
# segment`) and `mise ls --json`. p10k.zsh names `mise` among the prompt's
# segments. zshrc loads this file after it, which the colors below need.

# The icon of each tool, by mise's name for it: the name Powerlevel10k has an
# icon under, or a glyph from Nerd Fonts, by its number. A glyph is here
# where Powerlevel10k has no icon, has one that today's fonts draw wrong
# (node), or has one that is not the tool's logo (terraform, flutter,
# kubectl). Every glyph is in Nerd Fonts 3.4, the fonts the desktops have.
typeset -gA prompt_mise_icons=(
  ansible         $'\ue723'
  aws-cli         AWS_ICON
  awscli          AWS_ICON
  azure-cli       $'\ue754'
  bun             $'\ue76f'
  clojure         $'\ue768'
  cmake           $'\ue794'
  consul          $'\ue79a'
  crystal         $'\ue62f'
  dart            $'\ue64c'
  deno            $'\ue7c0'
  direnv          DIRENV_ICON
  docker-cli      $'\uf308'
  docker-compose  $'\uf308'
  dotnet          DOTNET_CORE_ICON
  elixir          ELIXIR_ICON
  elm             $'\ue62c'
  erlang          ERLANG_ICON
  ffmpeg          $'\uf008'
  flutter         $'\ue7dd'
  gcloud          $'\U000f11f6'
  gh              VCS_GIT_GITHUB_ICON
  ghc             HASKELL_ICON
  glab            VCS_GIT_GITLAB_ICON
  go              GOLANG_ICON
  gradle          $'\ue660'
  haskell         HASKELL_ICON
  helm            $'\ue7fb'
  java            JAVA_ICON
  julia           JULIA_ICON
  kotlin          $'\ue634'
  kubectl         $'\U000f10fe'
  lefthook        $'\U000f06e2'
  lua             LUA_ICON
  maven           $'\ue674'
  mysql           $'\ue704'
  neovim          VIM_ICON
  node            $'\U000f0399'
  npm             $'\ue71e'
  packer          $'\ue85c'
  perl            PERL_ICON
  php             PHP_ICON
  pnpm            $'\ue865'
  poetry          $'\ue867'
  postgres        POSTGRES_ICON
  pulumi          $'\ue873'
  python          PYTHON_ICON
  redis           $'\ue76d'
  ruby            RUBY_ICON
  rust            RUST_ICON
  scala           SCALA_ICON
  sqlite          $'\ue7c4'
  swift           SWIFT_ICON
  terraform       $'\ue8bd'
  tmux            $'\uebc8'
  typst           $'\uf37f'
  vault           $'\ue8d2'
  vim             VIM_ICON
  yarn            $'\ue6a7'
  yazi            YAZI_ICON
  yq              $'\ue8eb'
  zig             $'\ue6a9'
)

# A tool with no icon of its own gets the icon of where mise takes it from,
# the part of its name before the colon (npm:prettier), and shows its name.
typeset -gA prompt_mise_source_icons=(
  cargo   RUST_ICON
  dotnet  DOTNET_CORE_ICON
  gem     RUBY_ICON
  github  VCS_GIT_GITHUB_ICON
  gitlab  VCS_GIT_GITLAB_ICON
  go      GOLANG_ICON
  npm     $'\ue71e'
  pipx    PYTHON_ICON
)

# Any other tool gets a package, and shows its name.
typeset -g prompt_mise_any_icon=$'\ueb29'

# The colors in p10k.zsh go by asdf's name for a tool, in capitals. For these
# three it is not mise's.
typeset -gA prompt_mise_styles=(
  dotnet  DOTNET_CORE
  go      GOLANG
  node    NODEJS
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

  local line tool version source name icon text lookup
  for line in $prompt_mise_found; do
    tool=${line%% *}
    version=${${line#* }//\%/%%}
    # "aqua:pnpm/pnpm" comes from aqua and is called pnpm.
    source=${${(M)tool:#*:*}%%:*}
    name=${${tool#*:}:t}
    icon=$prompt_mise_icons[$name]
    text=$version
    if [[ -z $icon ]]; then
      icon=${prompt_mise_source_icons[$source]:-$prompt_mise_any_icon}
      text="${name//\%/%%} $version"
    fi
    # A name in capitals is one of Powerlevel10k's, for it to look up (-r).
    # Anything else is the glyph, to draw as it is (+r).
    [[ $icon == [A-Z]*_ICON ]] && lookup=-r || lookup=+r
    p10k segment -s ${prompt_mise_styles[$name]:-${(U)name//[^[:alnum:]]/_}} $lookup -i $icon -t $text
  done
}
