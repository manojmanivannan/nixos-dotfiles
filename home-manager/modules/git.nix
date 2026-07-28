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
}