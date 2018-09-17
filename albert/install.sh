#!/usr/bin/env sh

sudo yaourt -Syu albert --needed --noconfirm

ln -sfT ~/.dotfiles/albert/albert.conf  ~/.config/albert/albert.conf
ln -sfT ~/.dotfiles/albert/engines.json ~/.config/albert/org.albert.extension.websearch/engines.json

curl -o ~/.config/albert/org.albert.extension.websearch/gitlab. "https://about.gitlab.com/images/press/logo/logo.png"
curl -o ~/.config/albert/org.albert.extension.websearch/amazon. "https://upload.wikimedia.org/wikipedia/commons/thumb/7/70/Amazon_logo_plain.svg/2000px-Amazon_logo_plain.svg.png"
