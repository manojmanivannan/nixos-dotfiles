{ pkgs, user, ... }:

{
  # Enable Display Manager
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --time-format '%I:%M %p | %a • %h | %F' --cmd '${pkgs.uwsm}/bin/uwsm start -e -D Hyprland hyprland.desktop'";
        user    = "greeter";
      };
      # Auto-login `${user}` into Hyprland on boot. After logout the normal
      # tuigreet greeter takes over for subsequent logins.
      initial_session = {
        command = "${pkgs.uwsm}/bin/uwsm start -e -D Hyprland hyprland.desktop";
        user    = user;
      };
    };
  };

  users.users.greeter = {
    isNormalUser = false;
    description  = "greetd greeter user";
    extraGroups  = [ "video" "audio" ];
    linger        = true;
  };

  environment.systemPackages = with pkgs; [
    tuigreet
  ];
}
