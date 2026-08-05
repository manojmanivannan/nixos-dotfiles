{ ... }: {
  # fzf key bindings + fuzzy completion. HM's enableZshIntegration sources the
  # fzf key-bindings (Ctrl-T files, Ctrl-R history, Alt-C dirs) and completion
  # — this replaces the old `source <(fzf --zsh)`.
  #
  # Preview plumbing:
  #  - file/dir listings use `fd` (system package, terminal.nix) which respects
  #    .gitignore by default, so Ctrl-T/Alt-C don't dump node_modules/.git noise.
  #  - Ctrl-T previews files with `bat`, dirs with an `eza --tree` (both
  #    installed: bat via programs.bat in bat.nix, eza in home-packages.nix).
  #  - Alt-C previews the candidate directory with `eza --tree`.
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    # Used when fzf is invoked with no input (e.g. plain `fzf`).
    defaultCommand = "fd --type f --hidden --follow --exclude .git";

    # Ctrl-T: fuzzy-find files under $PWD.
    # NOTE: HM joins the list with spaces into one FZF_CTRL_T_OPTS string, so
    # each preview command must be wrapped in single quotes — otherwise fzf
    # parses `--preview` as taking only the first space-separated token
    # (`if` / `eza`) and the preview breaks. The quotes make fzf treat the
    # whole command as the --preview argument.
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidgetOptions = [
      "--preview"
      "'if [ -d {} ]; then eza --tree --color=always --icons {} | head -200; else bat --style=numbers --color=always {} 2>/dev/null; fi'"
    ];

    # Alt-C: fuzzy-find a directory under $PWD and cd into it.
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
    changeDirWidgetOptions = [
      "--preview"
      "'eza --tree --color=always --icons {} | head -200'"
    ];

    # Apply to every fzf invocation (history widget, tab completion, etc.).
    defaultOptions = [ "--height" "40%" "--layout=reverse" "--border" ];
  };
}