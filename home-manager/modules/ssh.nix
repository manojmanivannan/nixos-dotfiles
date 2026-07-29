{ ... }:

{
  # ~/.ssh/config, managed by Home Manager.
  #
  # The Ghostty double-typing-over-SSH issue is handled at the source:
  # ghostty/config sets `term = xterm-256color`, a TERM every remote has
  # terminfo for, so no per-host terminfo install is needed here.
  programs.ssh = {
    enable = true;
    extraConfig = ''
      # Specific hosts first — ssh uses first-match-wins per option, so a
      # named host must appear before the `Host *` defaults below.
      Host homelab
          HostName 192.168.1.120
          User manoj

      # Defaults applied to every host.
      Host *
          ServerAliveInterval 60
          ServerAliveCountMax 3
          AddKeysToAgent yes
    '';
  };
}