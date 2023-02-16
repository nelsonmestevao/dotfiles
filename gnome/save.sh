dconf dump / | sed -n '/\[org.gnome.settings-daemon.plugins.media-keys/,/^$/p' > ~/.dotfiles/gnome/user.conf
