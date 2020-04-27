# FUNCTIONS

function backup() {
  git add --all
  git commit -am ':wrench: [WIP] Done for today, cya tomorrow [ci skip] :wave:'
  git push $@
}

function git-ignore() {
  curl -L -s https://www.gitignore.io/api/$@
}

function mkcd() {
  mkdir -p $@
  cd $@
}

function filter() {
  flex $1
  gcc -o $2.out lex.yy.c -lfl
  rm lex.yy.c
}

function open() {
  xdg-open $@ & disown
}

function coding() {
  local PROJECT=$(ls $1 | fzf)

  tmuxinator start code "$1/$PROJECT"
}

function find-file() {
  local FILE=$(fzf --preview-window=right:60% --preview='bat --color "always" {}')

  if [ ! -z $FILE ]; then
    $EDITOR $FILE
  fi
}

function find-tmuxinator-project() {
  local PROJECT=$(ls -l ~/.dotfiles/tmux/projects | grep "^-" | awk {'print $9'} | cut -d. -f1 | awk '!/code/' | fzf)
  [ -z "$PROJECT" ] && exit

  tmuxinator start $PROJECT
}

function send-sms() {
  curl -X POST https://textbelt.com/text \
    --data-urlencode phone="$1" \
    --data-urlencode message="$2" \
    -d key=textbelt
}

function please() {
  local CMD=$(history -1 | cut -d" " -f4-)
  sudo "$CMD"
}

function weather() {
  curl 'wttr.in/~'${1:-Braga}'+'$2'?'${3:-0}
}

function show_ip() {
  ifconfig wlp3s0 | awk '$1 == "inet" {print $2}'
}

