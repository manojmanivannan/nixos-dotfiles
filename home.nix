{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

  # Standard .config/directory
  configs = {
    qtile = "qtile";
    nvim = "nvim";
    rofi = "rofi";
    alacritty = "alacritty";
    picom = "picom";
    hypr = "hypr";
    waybar = "waybar";
  };
in

{
  home.username = "manoj";
  home.homeDirectory = "/home/manoj";
  programs.git = {
	enable = true;
	settings = {
		user.email = "manojm18@live.in";
		user.name = "Manoj Manivannan";
		init.defaultBranch = "main";
	};

#	userName = "Manoj Manivannan";
#	userEmail = "manojm18@live.in";
#	extraConfig = {
#		init.defaultBranch = "main";
#	};
  };
  home.stateVersion = "26.05";
  programs.bash = {
    enable = true;
    shellAliases = {
      btw = "echo i use nixos-btw";
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos";
    };
    initExtra = ''
      	  export PS1="\[\e[38;5;75m\]\u@\h \[\e[38;5;113m\]\w \[\e[38;5;189m\]\$ \[\e[0m\]"
      	'';
  };

xdg.configFile = builtins.mapAttrs
  (name: subpath: {
    source = create_symlink "${dotfiles}/${subpath}";
    recursive = true;
  })
  configs;

home.packages = with pkgs; [
  neovim
  ripgrep
  nil
  nixpkgs-fmt
  nodejs
  gcc
  rofi
  xwallpaper
  sublime4
  docker-compose
];

# VS Code — managed by Home Manager so extensions/settings are declarative.
programs.vscode = {
  enable = true;
  profiles.default = {
    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix # Nix syntax support
    ];
    userSettings = {
      "editor.fontSize" = 14;
    };
  };
};

wayland.windowManager.hyprland.systemd.enable = false;
}
