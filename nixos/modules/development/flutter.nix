{ pkgs, ... }:

let
  # Declarative Android SDK for Flutter (`flutter build appbundle` / `apk`).
  # License acceptance is enabled in `nixos/modules/users/work.nix`
  # (`nixpkgs.config.android_sdk.accept_license = true`).
  # Versions match Flutter 3.41 (`compileSdk = 36`, `ndkVersion = "28.2.13676358"`)
  # alongside AGP 8.9 defaults (`build-tools 35.0.0`, `ndk 27.0.12077973`) and
  # older plugin compileSdk targets (`33`–`35`).
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    cmdLineToolsVersion = "latest";
    platformToolsVersion = "latest";
    buildToolsVersions = [
      "34.0.0"
      "35.0.0"
      "36.0.0"
    ];
    platformVersions = [
      "33"
      "34"
      "35"
      "36"
    ];
    cmakeVersions = [ "3.22.1" ];
    includeNDK = true;
    ndkVersions = [
      "26.3.11579264"
      "27.0.12077973"
      "28.2.13676358"
    ];
  };
  androidSdk = androidComposition.androidsdk;
  androidSdkRoot = "${androidSdk}/libexec/android-sdk";
in
{
  environment.variables = {
    JAVA_HOME = "${pkgs.jdk17}";
    ANDROID_HOME = androidSdkRoot;
    ANDROID_SDK_ROOT = androidSdkRoot;
    GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdkRoot}/build-tools/36.0.0/aapt2";
  };

  # Re-export in interactive zsh shells so terminals spawned inside an
  # already-running graphical session pick up the updated Nix store SDK path
  # immediately after `nrs` (since /etc/set-environment is guarded by
  # __NIXOS_SET_ENVIRONMENT_DONE after login).
  programs.zsh.interactiveShellInit = ''
    export JAVA_HOME="${pkgs.jdk17}"
    export ANDROID_HOME="${androidSdkRoot}"
    export ANDROID_SDK_ROOT="${androidSdkRoot}"
    export GRADLE_OPTS="-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdkRoot}/build-tools/36.0.0/aapt2"
  '';

  environment.systemPackages = with pkgs; [
    flutter
    jdk17
    androidSdk
  ];
}
