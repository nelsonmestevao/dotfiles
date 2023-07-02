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
alias r="ranger"
alias scim="sc-im"
alias p="sudo pacman"
alias y="yay"
alias ka="killall"
alias :q="exit"

alias o=open
alias f=find-file
alias ft=find-tmuxinator-project

alias bsc=backup
alias pls=please

alias g-='cd $(git rev-parse --show-toplevel || echo ".")'
alias grw=git-review
alias ght=git-history
alias gfz=git-fuzzy
alias grbma='git fetch origin; git fetch origin --prune; git rebase origin/$(git_main_branch)'
alias grbdv='git fetch origin; git fetch origin --prune; git rebase origin/$(git_develop_branch)'

alias v="nvim -p"
alias vi="nvim"
alias vim="nvim"

alias py="ipython -i"
alias pm="python -m"

alias r3="rebar3"

alias j=z
alias ji=zi

alias zj=zellij

alias t=tmux
alias tc=tmux-connect
alias mux=tmuxinator

alias bs="bin/server"
alias bb="bin/build"
alias br="bin/run"
alias bt="bin/test"
alias bf="bin/format"
alias bl="bin/lint"
alias bd="bin/dockerw"
alias bsh="bin/console"
alias bcl="bin/clean"
alias bst="bin/setup"
alias bsr="bin/start"
alias bsp="bin/stop"

alias m=mix
alias im="iex -S mix"
alias ms="mix phx.server"
alias mc="mix do clean, compile"
alias mf="mix format"
alias ml="mix lint"
alias mt="mix test"

alias mk=make
alias mkh="make help"
alias mkl="make lint"
alias mkc="make clean"
alias mkr="make run"
alias mkst="make setup"
alias mkt="make test"
alias mkut="make unit-tests"
alias mkts="make tests"

alias stg="stack ghci"
alias str="stack run"
alias stc="stack test --coverage"
alias sth="stack haddock"

alias n="npm"
alias nr="npm run"
alias nd="npm run dev"
alias nb="npm run build"
alias nbw="npm run build:watch"
alias ns="npm run start"
alias nl="npm run lint"
alias nf="npm run format"
alias nt="npm run test"
alias ntw="npm run test:watch"
alias nsb="npm run storybook"

alias a="ansible"
alias ac="ansible-console"
alias ap="ansible-playbook"

alias todo='git grep -l TODO | xargs -n1 git blame -f -n -w | grep "$(git config user.name)" | grep TODO | sed "s/.\{9\}//" | sed "s/(.*)[[:space:]]*//"'

alias firefox=firefox-developer-edition

alias joão="date -d '+2 hour' '+%T' && weather Tampere Finland 0"

alias hollywood='docker run --rm -it bcbcarl/hollywood'
alias cesium="xrandr --output HDMI1 --auto --above eDP1"
alias ip='ip -c=auto'

alias activate-ssh='eval $(ssh-agent -s); ssh-add ~/.ssh/id_rsa'

