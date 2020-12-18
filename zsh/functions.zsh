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

function open() {
  xdg-open $@ & disown
}

function mark () {
  file=~/.markfile
  [ -f $file ] || touch $file
  if grep "^$1=" $file > /dev/null; then
    sed -i -e "s:$1\=.*$:$1\=${PWD}:g" $file
    echo "entry $1 changed"
  else
    echo "$1=$PWD" >> $file
    echo "entry $1 added"
  fi
}

function goto () {
  file=~/.markfile
  if [ $# -eq 1 ]; then
    dest=$(grep "^$1=" $file | cut -d= -f2)
    cd $dest
  else
    echo "no mark specified"
  fi
}

function tmux-connect() {
  local HOSTNAME=$1
  local PORT=${2:-22}
  ssh $HOSTNAME -p $PORT -t tmux new-session -A -d -s ssh_tmux
}

function coding() {
  local PROJECT=$(ls $1 | fzf)
  [ -z "$PROJECT" ] && return

  tmuxinator start code "$1/$PROJECT"
}

function find-tmuxinator-project() {
  local PROJECT=$(ls -l ~/.dotfiles/tmux/projects | grep "^-" | awk {'print $9'} | cut -d. -f1 | awk '!/code/' | fzf)
  [ -z "$PROJECT" ] && return

  tmuxinator start $PROJECT
}

function find-file() {
  local FILE=$(fzf --preview-window=right:60% --preview='bat --color "always" {}')

  if [ ! -z $FILE ]; then
    $EDITOR $FILE
  fi
}

function send-sms() {
  curl -X POST https://textbelt.com/text \
    --data-urlencode phone="$1" \
    --data-urlencode message="$2" \
    -d key=textbelt
}

function please() {
  local CMD=$(history -1 | tr -s ' ' | cut -d' ' -f2-)
  sudo "$CMD"
}

function weather() {
  curl 'wttr.in/~'${1:-Braga}'+'$2'?'${3:-0}
}

function show_ip() {
  ifconfig wlp3s0 | awk '$1 == "inet" {print $2}'
}
