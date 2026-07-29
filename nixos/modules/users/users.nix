{ pkgs, user, ... }:

{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  # `user` is the flake-level specialArg (flake.nix: `user = "manoj"`), so a
  # cloner only changes that one let-binding — no username is hardcoded here.
  users.users.${user} = {
    isNormalUser = true;
    description = user;
    extraGroups = [ "networkmanager" "input" "wheel" "video" "audio" "tss" "docker" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      vscode
      brave
      google-chrome
    ];
  };

  # Change runtime directory size
  services.logind.settings.Login = {
    RuntimeDirectorySize="8G";
  };
}
