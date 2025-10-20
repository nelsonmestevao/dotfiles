# FUNCTIONS

function backup() {
  git add --all
  git commit --no-verify --no-gpg-sign \
    --message ":wrench: [WIP] Done for today, cya tomorrow [ci skip] :wave:" \
    --message "$(curl -s https://whatthecommit.com/index.txt)"
  git push $@
}

function mkcd() {
  mkdir -p $@
  cd $@
}

function cd!() {
  # if it was bash: cd $(dirname $_)
  local last_arg=$(fc -ln -1 | awk '{print $NF}')
  [[ -e "$last_arg" ]] && cd "${last_arg:h}"
}

function gclcd() {
  git clone --recurse-submodules $@
  cd "$(basename "$_" .git)"
}

function open() {
  xdg-open $@ &
  disown
}

function timestamp() {
  date --utc '+%Y%m%d%H%M%S'
}

function most_used_commands() {
  omz_history | awk '{print $2}' | sort | uniq -c | sort -nr | column -t | \nl | head -n40
}

function mark() {
  file="$HOME/.markfile"
  [ -f $file ] || touch $file
  if grep "^$1=" $file >/dev/null; then
    sed -i -e "s:$1\=.*$:$1\=${PWD}:g" $file
    echo "entry $1 changed"
  else
    echo "$1=$PWD" >>$file
    echo "entry $1 added"
  fi
}

function goto() {
  file="$HOME/.markfile"
  if [ $# -eq 1 ]; then
    dest=$(grep "^$1=" $file | cut -d= -f2)
    cd $dest
  else
    echo "no mark specified"
  fi
}

function chwd() {
  mark WORKING_DIR
  touch "$HOME/.wdfile"
}

function clwd() {
  if [[ -f "$HOME/.wdfile" ]]; then
    rm "$HOME/.wdfile"
  fi
}

function gtwd() {
  if [[ -f "$HOME/.wdfile" ]] && [ -z "$TMUX" ]; then
    goto WORKING_DIR
  fi
}

function tmux-connect() {
  local HOSTNAME=$1
  ssh $HOSTNAME -t tmux new-session -A -d -s ssh_tmux
}

function coding() {
  local PROJECT=$(ls $1 | fzf)
  [ -z "$PROJECT" ] && return

  tmuxinator start code "$1/$PROJECT"
}

function find-tmuxinator-project() {
  local PROJECT=$(ls -1 ~/.dotfiles/tmux/projects | cut -d. -f1 | awk '!/code/' | fzf)
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

function get_location_gps() {
  curl -s "https://location.services.mozilla.com/v1/geolocate?key=geoclue" | awk 'OFS=":" {print $3,$5}' | tr -d ',}'
}

function bwu(){
  export BW_SESSION=$(bw unlock --raw $1)
}

function grupo() {
  printf -v group_number "%03d" "$1"

  cd "$HOME/Code/UMinho/repos/projetos/2024li1g${group_number}"
}

function aluno() {
  local uminho_id="$(echo $1 | tr '[:upper:]' '[:lower:]')"

  cd "$HOME/Code/UMinho/repos/acompanhamento/${uminho_id}"
}
