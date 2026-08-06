{ ... }: {
  programs.git = {
    enable = true;
    settings = {
      user.email = "manojm18@live.in";
      user.name = "Manoj Manivannan";
      init.defaultBranch = "main";
      # Use `gh` as the HTTPS credential helper for GitHub. `~/.config/git/config`
      # is a read-only Nix-store symlink, so `gh auth setup-git` can't write this
      # itself — it must live here. The leading `!` makes git run it as a command.
      credential."https://github.com".helper = "!gh auth git-credential";
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
    };
  };
}