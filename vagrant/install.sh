sudo dnf install -y qemu-kvm libvirt libvirt-daemon-kvm
sudo systemctl enable libvirtd
vagrant plugin install vagrant-libvirt