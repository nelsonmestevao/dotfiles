# FUNCTIONS

function gi() {
  curl -L -s https://www.gitignore.io/api/$@ ;
}

function mkcd() {
  mkdir -p $@ ;
  cd $@ ;
}

function weather() {
  curl 'wttr.in/~'${1:-Braga}'+'$2'?'$3 ;
}

