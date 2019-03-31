# FUNCTIONS

function backup() {
  git add --all
  git commit -am ':wrench: [WIP] Done for today, cya tomorrow [ci skip] :wave:'
  git push $@
}

function git-ignore() {
  curl -L -s https://www.gitignore.io/api/$@
}

function most () {
  history | awk '{
      cmd[$2]++; count++;
    }
    END {
      for (i in cmd) print cmd[i]/count*100 "%", i
    }' | sort -nr | head -n20 | column -c3 -s " " -t
}

function mkcd() {
  mkdir -p $@
  cd $@
}

function open() {
  xdg-open $@ & disown
}

function please() {
  CMD=$(history -1 | cut -d" " -f4-)
  sudo "$CMD"
}

function weather() {
  curl 'wttr.in/~'${1:-Braga}'+'$2'?'${3:-0}
}
