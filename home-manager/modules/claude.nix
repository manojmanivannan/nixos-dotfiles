{ config, pkgs, lib, ... }:

let
  # Seed kept in the repo for fresh clones. The live ~/.claude/settings.json is
  # NOT symlinked: Claude Code rewrites it at runtime (plugin installs, /config,
  # permission toggles), and any home-manager-managed file is a read-only Nix-store
  # symlink that makes those writes fail with EROFS. We copy the seed in once, then
  # let Claude Code own the file.
  seed = "${config.home.homeDirectory}/nixos-dotfiles/config/.claude/settings.json";
in
{
  # Claude Code — the agentic coding CLI (nixpkgs `claude-code`, binary `claude`).
  home.packages = with pkgs; [
    claude-code
  ];

  # Seed ~/.claude/settings.json on first run only. Re-edits to the seed apply
  # only on a machine that doesn't yet have the file; existing installs keep
  # whatever Claude Code has written.
  home.activation.seedClaudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.claude/settings.json" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.claude"
      $DRY_RUN_CMD cp ${seed} "$HOME/.claude/settings.json"
    fi
  '';
}