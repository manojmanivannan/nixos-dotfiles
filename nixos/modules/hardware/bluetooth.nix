{
  # BlueZ: the kernel/userspace Bluetooth stack. Caelestia's bluetooth UI
  # (the bar indicator + the Nexus "Bluetooth" pairing page,
  # modules/nexus/pages/bluetooth/BluetoothPairing.qml) talks to BlueZ over
  # D-Bus via `Quickshell.Bluetooth` — power on/off, scan, pair and
  # connect/disconnect are all handled in-shell, so this is the only bluetooth
  # service needed.
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;

  # Blueman is NOT enabled: caelestia's built-in bluetooth indicator and
  # Nexus pairing page replaced `blueman-manager` (the GUI) once waybar was
  # retired as the shell (WF-11). Enabling `services.blueman` would also
  # autostart `blueman-applet` via its XDG autostart entry, which surfaced a
  # redundant bluetooth tray icon alongside caelestia's built-in one — the
  # duplicate we removed. `blueman-mechanism` went with it (only
  # `blueman-manager` needed it).
}
