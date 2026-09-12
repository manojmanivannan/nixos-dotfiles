{
  config,
  pkgs,
  ...
}:

# NAS backup — a user systemd oneshot service driven by a timer.
#
# Defined in Nix (rather than symlinked from the repo) so Home Manager enables
# the timer declaratively on every `switch` and reloads the user manager.
# The actual backup logic lives in the symlinked
# config/.config/rsync/archive_to_nas.sh (see dotfiles-symlinks.nix), which is
# the part worth editing live; the unit wiring rarely changes.
{
  systemd.user.services.nas-backup = {
    Unit = {
      Description = "Backup linux-machine directories to NAS, as defined in ${config.home.homeDirectory}/.config/rsync/archive_to_nas.sh";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
      # Fire a desktop notification whenever the backup exits non-zero
      # (missing password file, missing Apps dir, rsync failure, ...)
      OnFailure = [ "nas-backup-failure-alert.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.config/rsync/archive_to_nas.sh";
      # Makes `journalctl --user -t nas-backup` work regardless of the
      # script's process name.
      SyslogIdentifier = "nas-backup";
    };
  };

  # One-shot unit triggered by OnFailure above: pops a critical desktop
  # notification containing the last lines the backup script printed (its
  # stdout is tagged SYSLOG_IDENTIFIER=nas-backup, so `-t` filters out
  # systemd's generic "job failed" chatter and shows the actual reason).
  # %t expands to the user runtime dir, so this works without relying on
  # the user manager having DBUS_SESSION_BUS_ADDRESS exported.
  systemd.user.services.nas-backup-failure-alert = {
    Unit = {
      Description = "Desktop notification when the NAS backup fails";
    };
    Service = {
      Type = "oneshot";
      Environment = [ "DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus" ];
      ExecStart = pkgs.writeShellScript "nas-backup-failure-alert" ''
        reason="$(${pkgs.systemd}/bin/journalctl --user -t nas-backup -n 3 --no-pager -o cat)"
        if [ -z "$reason" ]; then
          reason="No reason captured. See: journalctl --user -u nas-backup.service -e"
        fi
        ${pkgs.libnotify}/bin/notify-send -u critical -a nas-backup "NAS backup FAILED" "$reason"
      '';
    };
  };

  systemd.user.timers.nas-backup = {
    Unit.Description = "Run NAS backup on schedule and on boot if missed";
    Timer = {
      # Run every Saturday at 3 AM
      OnCalendar = "Sat *-*-* 03:00:00";
      # If the machine was off at 3am, run immediately on next boot
      Persistent = true;
      # Settle Wi-Fi/LAN before the first post-boot run
      OnStartupSec = "5min";
    };
    # Declarative enable — HM reads Install.WantedBy and creates the
    # timers.target.wants/nas-backup.timer symlink on every switch. (This HM
    # version has no top-level `wantedBy` on timer units — only the Install
    # section works.)
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
