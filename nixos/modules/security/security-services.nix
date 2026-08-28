{ pkgs, lib, ... }:

{
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Enable Security Services
  security.sudo-rs = {
    enable = true;
    execWheelOnly = true;
  };
  security.sudo.enable = false;
  users.users.root.hashedPassword = "!";
  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };
  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = true;
    packages = with pkgs; [
      apparmor-utils
      apparmor-profiles
    ];
  };

  security.pam.services = {
    login.enableAppArmor = true;
    sshd.enableAppArmor = true;
    sudo-rs.enableAppArmor = true;
    su.enableAppArmor = true;
    greetd.enableAppArmor = true;
    u2f.enableAppArmor = true;
  };

  services.dbus.apparmor = "enabled";
  services.fail2ban.enable = true;
  # Explicitly enable polkit rather than rely on a transitive enabler (it was
  # coming up only because virtualisation.libvirtd enables it). The polkit
  # rule in ./polkit.nix (passwordless logind power actions for the active
  # wheel user) and the hyprpolkitagent autostart both depend on polkitd
  # being up; if libvirtd is ever disabled, those would silently break and
  # the caelestia power menu would stop turning the PC off again.
  security.polkit.enable = true;
  programs.firejail = {
    enable = true;
    wrappedBinaries = { 
      mpv = {
        executable = "${lib.getBin pkgs.mpv}/bin/mpv";
        profile = "${pkgs.firejail}/etc/firejail/mpv.profile";
      };
      imv = {
        executable = "${lib.getBin pkgs.imv}/bin/imv";
        profile = "${pkgs.firejail}/etc/firejail/imv.profile";
      };
      zathura = {
        executable = "${lib.getBin pkgs.zathura}/bin/zathura";
        profile = "${pkgs.firejail}/etc/firejail/zathura.profile";
      };
      discord = {
        executable = "${lib.getBin pkgs.discord}/bin/discord";
        profile = "${pkgs.firejail}/etc/firejail/discord.profile";
      };
      slack = {
        executable = "${lib.getBin pkgs.slack}/bin/slack";
        profile = "${pkgs.firejail}/etc/firejail/slack.profile";
      };
      Telegram = {
        executable = "${lib.getBin pkgs.telegram-desktop}/bin/Telegram";
        profile = "${pkgs.firejail}/etc/firejail/Telegram.profile";
      };
      qutebrowser = {
        executable = "${lib.getBin pkgs.qutebrowser}/bin/qutebrowser";
        profile = "${pkgs.firejail}/etc/firejail/qutebrowser.profile";
      };
      google-chrome = {
        executable = "${lib.getBin pkgs.google-chrome}/bin/google-chrome-stable";
        profile = "${pkgs.firejail}/etc/firejail/google-chrome.profile";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    gnupg
    openssl
  ];
}
