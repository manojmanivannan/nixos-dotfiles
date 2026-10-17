# hyprwhspr — voice dictation (github.com/goodroot/hyprwhspr). The flake
# ships a NixOS module that installs the package system-wide, loads `uinput`,
# declares a udev rule for it, and puts every listed user in the `input`
# group (relogin needed to take effect). The user service is a
# `graphical-session.target` part — with uwsm running Hyprland
# (nixos/modules/desktop/hyprland.nix) that target is already active, so the
# daemon follows the session. Security note (upstream docs): `input` group
# membership grants read of input devices and keystroke injection.
#
# The module only wires the unit; upstream's manual first-run steps are
# replaced declaratively:
#   ~/.config/hyprwhspr/config.json  <- symlinked from config/.config/hyprwhspr/
#     (home-manager/modules/dotfiles-symlinks.nix). The unit gates on it via
#     ConditionPathExists=%E/hyprwhspr/config.json.
#   ggml-small.en.bin                <- fetched into the store and symlinked
#     into ~/.local/share/pywhispercpp/models/ by home-manager/modules/hyprwhspr.nix.
#
# GPU — the flake's own pywhispercpp hardcodes GGML_CUDA=OFF (CPU-only Nix
# build), which made dictation latency fall back to CPU (~seconds per utterance
# on this machine). Upstream ships prebuilt whisper.cpp wheels ("wheels-v2"
# GitHub release, pinned at pywhispercpp 1.5.1 / build 1) for the cpu/cuda12
# variants; the cuda12 wheel is dropped in below, replacing the flake package's
# pywhispercpp through the package's `callPackage` seam (package.nix's only
# callPackage call constructs pywhispercpp). whisper.cpp auto-detects the GPU
# at model load, so the `cpu`/`pywhispercpp` transcription_backend in
# config.json stays as-is. Verified on this machine: libcuda from the driver
# (595.71.05) + cublas/cudart 12.9 resolve, and a ggml-base pass runs in ~30ms
# (GPU) rather than seconds (CPU).
#
# Runtime lib wiring: the wheel links libcublas/libcudart with no RPATH, so
# postFixup stamps one in (CUDA-12 store libs + libstdc++); the driver's
# libcuda.so.1 can only come from the host, hence the unit's
# LD_LIBRARY_PATH. Interactive `hyprwhspr test`/`transcribe` runs (which also
# import the native lib) need it too:
#   LD_LIBRARY_PATH=/run/opengl-driver/lib hyprwhspr test
{
  inputs, pkgs, lib, ...
}:

let
  cu12 = pkgs.cudaPackages_12_9;
  # cuda12 (not the default nixpkgs CUDA 13) — the wheel was built against
  # the cu12 sonames (libcudart.so.12, libcublas.so.12). CUDA EULA license,
  # permitted by nixpkgs.config.allowUnfree (nixos/modules/nix/nixpkgs.nix).
  pywhispercppCuda = pkgs.python313.pkgs.buildPythonPackage {
    pname = "pywhispercpp";
    version = "1.5.1";
    format = "wheel";
    src = pkgs.fetchurl {
      url = "https://github.com/goodroot/hyprwhspr/releases/download/wheels-v2/pywhispercpp-1.5.1-1-cp313-cp313-linux_x86_64+cuda12.whl";
      hash = "sha256-P2w5gOsH6FI9Pzz/GBd9SSi4yyEHowZD07jjZmYW3V0=";
    };
    dependencies = with pkgs.python313.pkgs; [
      numpy
      requests
      tqdm
      platformdirs
    ];
    postFixup = ''
      for lib in "$out"/lib/python3.13/site-packages/*.so*; do
        patchelf --add-rpath "${
          lib.makeLibraryPath [
            cu12.cuda_cudart
            cu12.libcublas
            pkgs.stdenv.cc.cc.lib
          ]
        }" "$lib"
      done
    '';
  };
  hyprwhsprCuda = inputs.hyprwhspr.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
    callPackage = _: _: pywhispercppCuda;
  };
in {
  imports = [ inputs.hyprwhspr.nixosModules.default ];

  services.hyprwhspr = {
    enable = true;
    users = [ "manoj" ];
    package = hyprwhsprCuda;
  };

  # Driver-side libcuda.so.1 lives only on the host (/run/opengl-driver/lib is
  # the NixOS symlink farm created by hardware.nvidia); no store path can
  # provide it, so the user service must get it via environment.
  systemd.user.services.hyprwhspr.environment.LD_LIBRARY_PATH =
    "/run/opengl-driver/lib";
}