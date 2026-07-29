{ ... }:

{
  # ~/.ssh/config, managed by Home Manager.
  #
  # The Ghostty double-typing-over-SSH issue is handled at the source:
  # ghostty/config sets `term = xterm-256color`, a TERM every remote has
  # terminfo for, so no per-host terminfo install is needed here.
  programs.ssh = {
    enable = true;
    # Home Manager used to inject a `Host *` block of legacy defaults and
    # warn that it's going away. Carry the ones we want explicitly instead.
    enableDefaultConfig = false;

    # Named hosts. Home Manager always emits the `*` (catch-all) block last,
    # so first-match-wins keeps these ahead of the defaults below.
    settings.homelab = {
      HostName = "192.168.1.120";
      User = "manoj";
    };

    # Defaults applied to every host. These are the legacy Home Manager
    # defaults, with `ServerAliveInterval` and `AddKeysToAgent` set to our
    # preferred values.
    settings."*" = {
      ForwardAgent = false;
      AddKeysToAgent = "yes";
      Compression = false;
      ServerAliveInterval = 60;
      ServerAliveCountMax = 3;
      HashKnownHosts = false;
      UserKnownHostsFile = "~/.ssh/known_hosts";
      ControlMaster = "no";
      ControlPath = "~/.ssh/master-%r@%n:%p";
      ControlPersist = "no";
    };
  };
}