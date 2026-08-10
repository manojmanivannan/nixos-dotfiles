{ ... }: {
  programs.git = {
    enable = true;
    settings = {
      user.email = "manojm18@live.in";
      user.name = "Manoj Manivannan";
      init.defaultBranch = "main";
      diff.colorMoved = "default";
      diff.colorMovedWS = "allow-indentation-change";
      # Use `gh` as the HTTPS credential helper for GitHub. `~/.config/git/config`
      # is a read-only Nix-store symlink, so `gh auth setup-git` can't write this
      # itself — it must live here. The leading `!` makes git run it as a command.
      credential."https://github.com".helper = "!gh auth git-credential";

      # Aliases (HM release-26.05 renamed `programs.git.aliases` →
      # `programs.git.settings.alias`). The legacy `config/.gitconfig` was
      # orphaned (not wired into HM), so aliases must live here to reach the
      # generated `~/.config/git/config`. `recentb` backs the
      # `gcorecent`/`grecent` zsh function (zshrc.d/20-git.zsh).
      alias = {
        tree = "log --all --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        recentb = "for-each-ref --count=20 --sort=-committerdate refs/heads/ --format='%(authordate:short) %(color:red)%(objectname:short) %(color:yellow)%(refname:short)%(color:reset) (%(color:green)%(committerdate:relative)%(color:reset))'";
      };
    };
  };

  # delta — syntax-highlighted, side-by-side diff pager. With
  # `enableGitIntegration` HM wires core.pager + interactive.diffFilter
  # automatically (so `git diff`, `git show`, `git log -p`, and `git add -p`
  # all use it). `navigate` lets n/N jump between hunks. The `git-delta`
  # package is added by HM, so no terminal.nix entry needed. Supersedes the
  # `gdiff='ydiff ...'` alias in zshrc.d/30-aliases.zsh (left in place —
  # harmless). (Note: `programs.git.delta.*` was renamed to top-level
  # `programs.delta.*` in newer HM.)
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      line-numbers = true;
      side-by-side = true;
      navigate = true;

      # Ported from the orphaned config/.gitconfig. The catppuccin theme
      # include (`features`/`syntax-theme`) is dropped — its target file
      # `~/.config/delta/catppuccin.gitconfig` never existed on this host, so
      # it was a no-op. gpg signing, core.excludesfile, and the gitdir
      # includes were also dropped: their target files don't exist here.
      width = "variable";
      whitespace-error-style = "22 reverse";
      merge-conflict-style = "diff3";

      file-added-label = "[added]";
      file-copied-label = "[copied]";
      file-modified-label = "[modified]";
      file-removed-label = "[removed]";
      file-renamed-label = "[renamed]";

      commit-decoration-style = "bold box ul";
      commit-style = "raw";
      file-decoration-style = "bold yellow ul";
      file-style = "bold blue";

      hunk-header-style = "file line-number syntax";
      hunk-header-decoration-style = "bold box ul";

      word-diff-regex = "\\w+";
      # Quoted as strings: HM's `programs.delta.options` type is
      # string|bool|int (no floats), but delta parses both as numbers.
      max-line-distance = "0.6";
      max-line-length = "512";
      wrap-max-lines = "unlimited";

      line-numbers-left-format = "{nm:>4}┊";
      line-numbers-right-format = "{np:>4}│";
      line-numbers-left-style = "blue";
      line-numbers-right-style = "blue";
      line-numbers-minus-style = "bold red";
      line-numbers-plus-style = "bold green";
      line-numbers-zero-style = "dim";

      minus-empty-line-marker-style = "normal";
      plus-empty-line-marker-style = "normal";

      blame-code-style = "syntax";
      blame-format = "{author:<18} ({commit:>7}) {timestamp:<16} │ ";
      blame-timestamp-format = "%Y-%m-%d %H:%M";

      inspect-raw-lines = false;
      paging = "auto";
      keep-plus-minus-markers = false;
      show-syntax-themes = false;
      show-themes = false;
    };
  };
}