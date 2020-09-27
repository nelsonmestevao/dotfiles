# PLUGINS

plugins=(
  asdf
  colored-man-pages
  command-not-found
  extract
  fzf-tab
  git
  # golang #
  # mercurial #
  # npm #
  rails
  tmux
  tmuxinator
  # themes #
  # vi-mode #
  z
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# source $DOTFILES/zsh/plugins/syntax-highlighting.zsh

### zplug #####################################################################

# Check if zplug is installed
# if [[ ! -d ~/.zplug ]]; then
#   curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
#   source ~/.zplug/init.zsh && zplug update --self
# fi

# source ~/.zplug/init.zsh

# Plugins List

# zplug "zsh-users/zsh-syntax-highlighting"

# -----------------------------------------------------------------------------

# Themes List

# zplug "bhilburn/powerlevel9k", use:powerlevel9k.zsh-theme

# -----------------------------------------------------------------------------

# Install packages that have not been installed yet
# if ! zplug check --verbose; then
#   printf "Install? [y/N]: "
#   if read -q; then
#     echo
#     zplug install
#   else
#     echo
#   fi
# fi

# zplug load
