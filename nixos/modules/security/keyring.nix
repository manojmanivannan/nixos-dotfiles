{ ... }:

{
  # GNOME Keyring provides the org.freedesktop.secrets D-Bus service that
  # credential-aware tools (e.g. `gh`, browsers) use to store secrets. Without
  # it, `gh` falls back to `pass` at ~/.password-store and fails if the store
  # is uninitialized. The daemon is D-Bus-activated on first use; the Hyprland
  # session also starts it explicitly (see config/.config/hypr/hyprland.lua).
  services.gnome.gnome-keyring.enable = true;

  # gnome-keyring pulls in GNOME's gcr SSH agent, which conflicts with
  # programs.ssh.startAgent (the OpenSSH agent used with the Yubikey, set
  # up in yubikey.nix). Keep the existing SSH agent and use gnome-keyring
  # only for its secrets component.
  services.gnome.gcr-ssh-agent.enable = false;

  # Auto-unlock the "login" keyring at greetd login via pam_gnome_keyring.
  # This only works if the login keyring's password matches the user's login
  # password — on first unlock gnome-keyring creates the keyring with that
  # password, so the common case needs no extra setup.
  security.pam.services.greetd.enableGnomeKeyring = true;
}