{ pkgs, lib, user, osConfig, ... }:

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

  # Auto-generate an ed25519 keypair for this user on first activation. The
  # private key is written to ~/.ssh (not the Nix store, not git), so it stays
  # secret and is unique to this machine. Idempotent: it only acts when the
  # key is missing, so an existing key is never overwritten. The public key
  # is echoed after generation so it can be pasted into other hosts'
  # ~/.ssh/authorized_keys (or a Git host's deploy keys).
  home.activation.generateSshKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.ssh/id_ed25519" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.ssh"
      $DRY_RUN_CMD chmod 700 "$HOME/.ssh"
      $DRY_RUN_CMD ${pkgs.openssh}/bin/ssh-keygen \
        -t ed25519 -N "" \
        -f "$HOME/.ssh/id_ed25519" \
        -C "${user}@${osConfig.networking.hostName}"
      # Only chmod/print when the keygen actually ran (skipped in dry-run).
      if [ -e "$HOME/.ssh/id_ed25519.pub" ]; then
        chmod 600 "$HOME/.ssh/id_ed25519"
        chmod 644 "$HOME/.ssh/id_ed25519.pub"
        echo "Generated ~/.ssh/id_ed25519. Public key (add to other hosts' authorized_keys):"
        cat "$HOME/.ssh/id_ed25519.pub"
      fi
    fi
  '';
}