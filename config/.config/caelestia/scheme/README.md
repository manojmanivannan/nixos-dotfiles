# WF-10 placeholder. The vendored warm-metal scheme lands here in WF-12
# (docs/wayfinder/tickets/pin-warm-metal-theming.md): a static
# scheme.json encoding the warm-metal -> M3 role mapping from the build
# spec, with `services.smartScheme = false` set in shell.json to pin it.
# Until then this directory is intentionally empty so the recursive
# symlink in dotfiles-symlinks.nix resolves; caelestia falls back to its
# built-in default scheme (smartScheme is left at its default `true` in
# the WF-10 caelestia.nix module, so WF-11 launches on the default
# theme).