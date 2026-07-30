{ config, ... }:

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
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.config/rsync/archive_to_nas.sh";
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
