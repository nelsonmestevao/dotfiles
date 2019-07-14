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
  alias   | sed "s/'//g" > /tmp/aliases.tmp
  history | sed "s/'//g" > /tmp/history.tmp
  python -c "aliases = {}
aliases_file = open('/tmp/aliases.tmp')
for line in aliases_file:
    alias, command  = line.strip().split('=', 1)
    aliases[alias] = command.split()[0]

statistics = {}
history_file = open('/tmp/history.tmp')
for line in history_file:
    trash, command = line.strip().split(' ', 1)
    command = command.split()[0]
    if command in aliases:
        if aliases[command] in statistics:
            statistics[aliases[command]] += 1
        else:
            statistics[aliases[command]] = 1
    else:
        if command in statistics:
            statistics[command] += 1
        else:
            statistics[command] = 1

for k, v in statistics.items():
    print('{}\t{}'.format(v, k))" | sort -nr | head -20
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
