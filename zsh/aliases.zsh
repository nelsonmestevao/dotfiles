# GLOBAL ALIASES

alias -g H='| head'
alias -g T='| tail'
alias -g G='| grep'
alias -g L="| less"

# ALIASES

alias dot="cd $DOTFILES"

alias c="coding $HOME/Code"
alias s="coding $HOME/Snippets"

alias cv="cd $HOME/Code/curriculum-vitae/ && exa --long --header --git"
alias ocv="cd $HOME/Code/online-curriculum/ && exa --long --header --git"

alias um="cd $HOME/Code/uminho/"

alias ls="exa"
alias cat="bat"
alias r="ranger"
alias scim="sc-im"
alias p="sudo pacman"
alias y="yay"
alias ka="killall"
alias :q="exit"

alias o=open
alias f=find-file
alias m=find-tmuxinator-project

alias bsc=backup
alias pls=please

alias g-='cd $(git rev-parse --show-toplevel || echo ".")'
alias grw=git-review
alias ght=git-history
alias gfz=git-fuzzy

alias v="nvim -p"
alias vim="nvim"

alias py="ipython -i"
alias pm="python -m"

alias r3="rebar3"

alias t=tmux
alias tc=tmux-connect
alias mux=tmuxinator

alias bs="bin/server"
alias bb="bin/build"
alias br="bin/run"
alias bt="bin/test"
alias bf="bin/format"
alias bl="bin/lint"
alias bcs="bin/console"
alias bcl="bin/clean"
alias bst="bin/setup"
alias bsr="bin/start"
alias bsp="bin/stop"

alias mk=make
alias mkh="make help"
alias mkc="make clean"
alias mkr="make run"
alias mkt="make test"

alias n="npm"
alias nr="npm-run-all"

alias a="ansible"
alias ac="ansible-console"
alias ap="ansible-playbook"

alias firefox=firefox-developer-edition

alias joão="date -d '+2 hour' '+%T' && weather Tampere Finland 0"

alias cesium="xrandr --output HDMI1 --auto --above eDP1"
alias ip='ip -c=auto'

alias activate-ssh='eval $(ssh-agent -s); ssh-add ~/.ssh/id_rsa'

# useful comands
# xdotool key Caps_Lock
# setxkbmap -option ctrl:nocaps
