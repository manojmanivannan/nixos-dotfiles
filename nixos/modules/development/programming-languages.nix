{ pkgs, config, lib, ... }:

lib.mkIf (config.manoj.profile == "full") {
  # nix-ld provides a system-wide ldso loader so generic Linux binaries
  # (e.g. uv-managed cpython downloaded from python-build-standalone, and the
  # manylinux wheels it installs) run unpatched on NixOS.
  programs.nix-ld = {
    enable = true;

    # Libraries exposed to nix-ld binaries via NIX_LD_LIBRARY_PATH.
    # - nvidia_x11: provides libcuda.so, which pip wheels like
    #   `tensorflow[and-cuda]` / `torch` expect the system to supply (they
    #   bundle the CUDA *runtime* but not the driver lib). Without this, uv's
    #   Python sees cuInit fail with "libcuda.so NOT_FOUND" even though the
    #   kernel module is loaded.
    # - The rest are common runtime deps manylinux wheels dlopen at import
    #   time (libstdc++, libgomp, zlib, etc.).
    libraries = with pkgs; [
      config.boot.kernelPackages.nvidia_x11
      stdenv.cc.cc.lib
      zlib
      zstd
    ];
  };

  environment.systemPackages = with pkgs; [
    uv
    nodejs # runtime for several kept LSPs (yaml/bash/dockerfile/docker-compose/jsonnet)
    bun
  ];
}
