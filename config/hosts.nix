# ── Hosts ──────────────────────────────────────────────────────────────────
#
# `platform` selects the system builder ("nixos" or "darwin"); omit it for
# hosts that only get a home-manager configuration.
#
# `roles` say what a host is for ("desktop", "server"). User files turn
# programs on by role or host name, e.g. `enableFor [ "desktop" "temis" ]`, so
# a role can't share a host's name.
#
# Each host also gets a role for its OS, "linux" or "darwin", taken from its
# `system`. You don't need to list it.
#
# `git.signingKey` is the SSH key that signs commits on this host: the public
# key, or the path of its file. `git.signingProgram` is the program that signs
# with it, when it isn't ssh-keygen (1Password on a Mac). Leave both out and
# commits aren't signed there.
{
  framework = {
    system = "x86_64-linux";
    platform = "nixos";
    roles = [ "desktop" ];
    users = [ "nelson" ];
    git.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINt6s4KNjVHcH0qA0CPKWYPyCTPXkbwXFlfljrToN8b6";
  };
  thinkpad = {
    system = "x86_64-linux";
    users = [ "nelson" ];
    git.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINt6s4KNjVHcH0qA0CPKWYPyCTPXkbwXFlfljrToN8b6";
  };
  temis = {
    system = "x86_64-linux";
    platform = "nixos";
    roles = [ "server" ];
    users = [ "nelson" ];
    # The key file, so no ssh-agent is needed.
    git.signingKey = "~/.ssh/id_ed25519.pub";
  };
  "Remote-Nelson-Estevao" = {
    system = "aarch64-darwin";
    platform = "darwin";
    roles = [ "desktop" ];
    users = [ "nelson.estevao" ];
    git.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDLaSmNmQBu2OUMctje364/orYOTUwpIq/7V+az8b+dw";
    git.signingProgram = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
  };
}
