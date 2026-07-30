{ pkgs, ... }:

{
  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;

  # Blueman: GTK Bluetooth manager. `blueman-manager` is the GUI launched from
  # the waybar bluetooth pill (on-click) for power on/off, scan, pair and
  # connect/disconnect. Enabling the service also starts blueman-mechanism,
  # which blueman-manager needs for privileged operations.
  services.blueman.enable = true;

}
