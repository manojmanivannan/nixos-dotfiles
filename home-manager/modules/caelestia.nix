# WF-10 — Wire caelestia (the quickshell full shell) into Home-Manager.
#
# This is the build-only slice: caelestia is present in the evaluation
# graph and its systemd user service evaluates, but it is NOT launched
# yet — waybar/swaync still autostart (launching is WF-11). See the ticket
# docs/wayfinder/tickets/wire-caelestia-flake-hm.md and the build spec
# docs/wayfinder/tickets/build-spec.md (Solution: Flake & Home-Manager
# integration; Vendored runtime config).
#
# The upstream HM module is registered in
# nixos/modules/nix/home-manager.nix via `home-manager.sharedModules` and
# defines the `programs.caelestia` options; this module enables it.

{ inputs, pkgs, ... }:

{
  programs.caelestia = {
    enable = true;
    # `with-cli` bundles `caelestia-cli` into the shell wrapper so the
    # shell's own IPC works (scheme/wallpaper/shell subcommands). The
    # spec's "with the `with-cli` package" decision (WF-2). Stated
    # explicitly (rather than relying on the option's identical default)
    # so the ticket's "with the `with-cli` package" wording reads off the
    # module directly.
    package = inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli;

    systemd = {
      enable = true;
      # `target` is left at its default — `config.wayland.systemd.target`,
      # which HM defines (in its always-imported `wayland.nix`) as
      # "graphical-session.target", the target uwsm activates for this
      # Hyprland session (`programs.hyprland.withUWSM = true`). Not
      # hard-coded so the WF-11 launch slice can repoint it (build-phase
      # risk #2): if a real session shows uwsm activates a different
      # target, set `target = "…"` here then. `QT_QPA_PLATFORM=wayland`
      # is set by the upstream module's own service `Environment=`, so
      # nothing extra is needed in `environment`.
    };

    # Non-empty so the upstream module generates
    # ~/.config/caelestia/shell.json (and the systemd `X-Restart-Triggers`
    # fire on edit). This is a deliberate no-op: `smartScheme` is left at
    # its default (`true`, wallpaper-driven) so WF-11 can launch on the
    # default theme. WF-12 flips this to `false` and pins the vendored
    # warm-metal scheme/ — the real theming payload lands there, not here.
    # Generating the (no-op) shell.json now also proves the single-file
    # symlinks in dotfiles-symlinks.nix (shell-tokens.json / hypr-user.conf
    # / scheme/) coexist alongside the HM-generated shell.json without
    # colliding with it.
    settings = {
      services.smartScheme = true;
    };
  };
}