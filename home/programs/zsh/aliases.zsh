# The aliases that belong to no program. An alias for a program lives with it,
# as `home.shellAliases` in its module, so it only exists where the program
# is on: see home/programs/git/git.nix.

# GLOBAL ALIASES

alias -g H='| head'
alias -g T='| tail'
alias -g G='| grep'
alias -g L="| less"
alias -g N="| nvim +'setlocal buftype=nofile noswapfile' +':0' -"

# ALIASES

alias dot="cd $DOTFILES"

alias scim="sc-im"
alias ka="killall"
alias :q="exit"

alias o=open
alias f=find-file

alias bsc=backup
alias pls=please

alias bs="bin/server"
alias bb="bin/build"
alias br="bin/run"
alias bt="bin/test"
alias bf="bin/format"
alias bl="bin/lint"
alias bd="bin/dockerw"
alias bp="bin/podmanw"
alias bsh="bin/console"
alias bcs="bin/console"
alias bcl="bin/clean"
alias bst="bin/setup"
alias bsr="bin/start"
alias bsp="bin/stop"

alias ip='ip -c=auto'

alias tp5="$HOME/Code/UMinho/aulas-pi/2526/tp5"
alias tp6="$HOME/Code/UMinho/aulas-pi/2526/tp6"
