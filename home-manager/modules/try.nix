# try (github.com/tobi/try) — a single-file Ruby CLI for date-prefixed
# experiment directories with fuzzy search. The upstream HM module is
# registered in nixos/modules/nix/home-manager.nix via
# `home-manager.sharedModules` and defines the `programs.try` options; this
# module enables it.
#
# Shell integration is handled by the upstream module: when
# `programs.zsh.enable` is true (it is — home-manager/modules/zsh.nix) it
# appends `eval "$(${cfg.package}/bin/try init ${cfg.path})"` to
# `programs.zsh.initContent`, which defines the `try` shell function. No
# manual init line is needed here. The `~` in `path` is tilde-expanded by
# zsh when the eval'd command runs, so try receives the absolute
# ~/Experiments path.
#
# Package override: the upstream derivation wraps `try.rb` with
# `wrapProgram`, which renames the raw script to `$out/bin/.try-wrapped`
# and creates an ELF `try` that puts Ruby on PATH. But `try init` emits a
# shell function that calls `.try-wrapped` *directly*, bypassing that
# wrapper. The script's shebang is `#!/usr/bin/env ruby`, and Ruby is not
# on the user's PATH, so every `try` invocation died with
# `env: 'ruby': No such file or directory`. The fix is to rewrite the
# shebang to the absolute Nix Ruby so the unwrapped script is
# self-sufficient. Two notes on *how*:
#   - Ruby must be added to `nativeBuildInputs` so `patchShebangs` can
#     resolve `ruby` to a store path during the build (the upstream
#     derivation only references Ruby inside `wrapProgram`, not as a build
#     input, so it isn't on the build-time PATH).
#   - The patch must run in `postFixup`, not `postInstall`: the upstream
#     derivation overrides `installPhase` with a custom body, which
#     replaces the stdenv hook that would have called `postInstall` — so a
#     `postInstall` override is silently dropped. `fixupPhase` is not
#     overridden, so `postFixup` runs.

{ inputs, pkgs, ... }:

let
  tryPkg = inputs.try.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  programs.try = {
    enable = true;
    path = "~/Experiments";
    package = tryPkg.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.ruby_3_3 ];
      postFixup = (old.postFixup or "") + ''
        patchShebangs $out/bin/.try-wrapped
      '';
    });
  };
}