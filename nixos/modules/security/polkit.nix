{ ... }:

{
  # Passwordless logind power actions for the wheel user.
  #
  # Caelestia's session menu (modules/session/Content.qml) calls
  # org.freedesktop.login1.Manager.PowerOff / Reboot / Suspend / Hibernate
  # with `interactive = true`
  # (plugin/src/Caelestia/Services/sessionmanager.cpp: `callManager` passes
  # `{ /* interactive = */ true }`; systemd 260's PowerOff signature is `b`).
  # Two things conspire to deny that call without this rule:
  #
  #   1. Multiple logind sessions are present — the tuigreet greeter (uid 995,
  #      `manager-early`) lingers alongside the Hyprland user session — so
  #      logind maps PowerOff to `org.freedesktop.login1.power-off-multiple-
  #      sessions`, whose default is `auth_admin` (a password challenge),
  #      not the single-session action whose default is `yes`.
  #
  #   2. Caelestia runs as a systemd `--user` service, whose subject lives in
  #      the `manager`-class session — NO seat, so polkit treats it as neither
  #      `local` nor `active`. An earlier version of this rule gated on
  #      `subject.local && subject.active`; that guard never matched for the
  #      shell, so the call fell through to `auth_admin` and was denied with
  #      "requires interactive authentication ... not been enabled by the
  #      calling program" (a per-session polkit agent in the seat0 Hyprland
  #      session can't help, because agents are registered per-subject and
  #      caelestia's subject is the seatless manager session).
  #
  # The fix is to authorise the wheel user outright (polkit.Result.YES) for
  # every power/reboot/suspend/hibernate variant — including the
  # `-multiple-sessions` and `-ignore-inhibit` forms — with NO local/active
  # requirement, so the call succeeds immediately regardless of which session
  # the shell runs in and needs no agent. This is not a new exposure: the
  # sole wheel user (manoj) can already `sudo poweroff` from any session
  # (sudo-rs is `execWheelOnly`, see security-services.nix), and SSH wheel
  # logins could power the box off regardless. Wheel-scoping matches that
  # existing security model.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
        if (!subject.isInGroup("wheel"))
            return;
        if (action.id == "org.freedesktop.login1.power-off" ||
            action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
            action.id == "org.freedesktop.login1.power-off-ignore-inhibit" ||
            action.id == "org.freedesktop.login1.reboot" ||
            action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
            action.id == "org.freedesktop.login1.reboot-ignore-inhibit" ||
            action.id == "org.freedesktop.login1.suspend" ||
            action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
            action.id == "org.freedesktop.login1.hibernate" ||
            action.id == "org.freedesktop.login1.hibernate-multiple-sessions") {
            return polkit.Result.YES;
        }
    });
  '';
}