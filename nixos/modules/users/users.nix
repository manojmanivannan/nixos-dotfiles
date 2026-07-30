{ pkgs, user, ... }:

{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  # `user` is the flake-level specialArg (flake.nix: `user = "manoj"`), so a
  # cloner only changes that one let-binding — no username is hardcoded here.
  users.users.${user} = {
    isNormalUser = true;
    description = user;
    extraGroups = [ "networkmanager" "input" "wheel" "video" "audio" "tss" "docker" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      vscode
      brave
      google-chrome
    ];

    # Public keys authorised to log into this account over SSH. Password auth
    # is disabled (openssh.nix), so this list is the *only* way in — keep at
    # least one working key here before rebuilding, or you'll lock yourself out.
    #
    # To add a laptop: run `cat ~/.ssh/id_ed25519.pub` on it and paste the
    # whole printed line below. Removing a key here + rebuilding revokes it.
    # Pubkeys aren't secret, but listing them in the repo does reveal which
    # keys are valid on this host — fine for a home machine.
    openssh.authorizedKeys.keys = [
      # Macbook Air Pub Key
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKe4ST8GjQ3h/6WYzu19+Mi1sXFmIEOqPedQ4oRriI6b manojm18@live.in"
      # laptop-2 — TODO: replace with `cat ~/.ssh/id_ed25519.pub` from laptop 2
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI-REPLACE-WITH-LAPTOP-2-PUBKEY manoj@laptop-2"
    ];
  };

  # Cap for the per-user XDG_RUNTIME_DIR tmpfs (/run/user/<uid>) that
  # systemd-logind mounts for the session — sockets, pipes, caches live here.
  # systemd default is min(RAM/2, 4G); this raises it to 8G so large runtimes
  # (Flatpak sandboxes, Steam/Proton, GPU buffer staging) don't hit ENOSPC.
  # Remove if usage stays well under the default — it only sets a ceiling,
  # it does not reserve RAM.
  services.logind.settings.Login = {
    RuntimeDirectorySize="8G";
  };
}
