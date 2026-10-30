{ config, pkgs, user, lib, ... }:

{
  # Setup Env Variables
  # Override the NixOS default (shells-environment.nix sets EDITOR to nano);
  # py-file-opener's editor chain prefers $VISUAL -> $EDITOR -> vim, so a
  # system-wide default keeps its picks falling back to vim. mkForce because
  # NixOS's own default is also mkDefault, which would tie.
  environment.variables.EDITOR = lib.mkForce "vim";
  environment.variables.SPOTIFY_PATH = "${pkgs.spotify}/";
  environment.variables.JDK_PATH = "${pkgs.jdk17}/";
  environment.variables.NODEJS_PATH = "${pkgs.nodejs}/";
  environment.variables.ANDROID_SDK_ROOT = "${config.users.users.${user}.home}/android-sdk";
  environment.variables.ANDROID_AVD_HOME = "${config.users.users.${user}.home}/.android/avd";
}
