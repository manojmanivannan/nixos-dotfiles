{ ... }: {
  # bat — a `cat` clone with syntax highlighting. Used as a manpager here
  # (supersedes the oh-my-zsh `colored-man-pages` plugin, removed from
  # zsh.nix), and as the file-preview backend for fzf / fzf-tab (see fzf.nix
  # and the fzf-tab zstyles in zsh.nix). bat itself is added to the profile
  # by programs.bat.enable; no need to list it in terminal.nix.
  programs.bat.enable = true;

  # `man` respects $MANPAGER. Pipe through `col -bx` (strip backspaces from
  # tbl/eqn output) then bat with the `man` language for correct highlighting.
  # MANROFFOPT=-c makes groff emit ANSI color escapes bat can parse.
  home.sessionVariables = {
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    MANROFFOPT = "-c";
  };
}