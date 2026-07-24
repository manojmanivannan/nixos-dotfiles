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
    # Settings synced from the VSCode account (2026-07-24) and pinned here so
    # Home Manager is the source of truth. Settings Sync is left ON for
    # extensions/keybindings/snippets only — 'Settings' is unchecked in the
    # sync dialog to avoid re-introducing the conflict loop.
    userSettings = {
      "workbench.sideBar.location" = "right";
      "tabnine.experimentalAutoImports" = true;
      "remote.SSH.remotePlatform" = {
        "172.20.52.78" = "linux";
        "ec2" = "linux";
        "centos-nfv" = "linux";
        "manoj-desktop" = "linux";
      };
      "workbench.startupEditor" = "none";
      "kite.showWelcomeNotificationOnStartup" = false;
      "vs-kubernetes" = {
        "vs-kubernetes.crd-code-completion" = "disabled";
        "vscode-kubernetes.minikube-path.linux" = "/home/mmanivannan/.vs-kubernetes/tools/minikube/linux-amd64/minikube";
      };
      "redhat.telemetry.enabled" = false;
      "security.workspace.trust.untrustedFiles" = "open";
      "editor.stickyScroll.enabled" = true;
      "editor.minimap.showSlider" = "always";
      "[python]" = {
        "editor.defaultFormatter" = "charliermarsh.ruff";
        "editor.formatOnSave" = true;
        "editor.codeActionsOnSave" = {
          "source.organizeImports" = "explicit";
          "source.fixAll" = "explicit";
        };
      };
      "yaml.schemas" = {
        "file:///home/manoj/.vscode/extensions/atlassian.atlascode-3.0.10/resources/schemas/pipelines-schema.json" = "bitbucket-pipelines.yml";
      };
      "editor.fontLigatures" = true;
      "editor.fontFamily" = "Cascadia Code,'Fira Code',monospace";
      "remoteHub.commitDirectlyWarning" = "off";
      "terminal.integrated.fontWeight" = "normal";
      "terminal.integrated.fontWeightBold" = "normal";
      "jupyter.askForKernelRestart" = false;
      "telemetry.telemetryLevel" = "off";
      "editor.minimap.sectionHeaderFontSize" = 11;
      "explorer.confirmDelete" = false;
      "terminal.integrated.cursorStyle" = "line";
      "workbench.list.multiSelectModifier" = "alt";
      "explorer.confirmDragAndDrop" = false;
      "gitlens.telemetry.enabled" = false;
      "workbench.iconTheme" = "vscode-icons";
      "vsicons.dontShowNewVersionMessage" = true;
      "editor.lineHeight" = 1.3;
      "githubPullRequests.pushBranch" = "always";
      "git.autofetch" = true;
      "python.analysis.typeCheckingMode" = "strict";
      "github.copilot.nextEditSuggestions.enabled" = true;
      "task.allowAutomaticTasks" = "on";
      "diffEditor.codeLens" = true;
      "github.copilot.advanced" = { };
      "githubPullRequests.pullBranch" = "never";
      "git.confirmSync" = false;
      "editor.cursorSmoothCaretAnimation" = "on";
      "editor.cursorBlinking" = "smooth";
      "editor.formatOnSave" = true;
      "editor.fontSize" = 14;
      "docker.extension.enableComposeLanguageServer" = false;
      "geminicodeassist.project" = "reflecting-maker-r1tnf";
      "[dockercompose]" = {
        "editor.insertSpaces" = true;
        "editor.tabSize" = 2;
        "editor.autoIndent" = "advanced";
        "editor.quickSuggestions" = {
          "other" = true;
          "comments" = false;
          "strings" = true;
        };
        "editor.defaultFormatter" = "redhat.vscode-yaml";
      };
      "[github-actions-workflow]" = {
        "editor.defaultFormatter" = "redhat.vscode-yaml";
      };
      "gitlens.ai.model" = "vscode";
      "gitlens.ai.vscode.model" = "copilot:gpt-4.1";
      "remote.autoForwardPortsSource" = "hybrid";
      "geminicodeassist.displayInlineContextHint" = false;
      "chat.tools.terminal.autoApprove" = {
        "mv" = true;
        "npx vitest" = true;
        "npx tsc" = true;
      };
      "geminicodeassist.enableTelemetry" = false;
      "workbench.secondarySideBar.defaultVisibility" = "hidden";
      "diffEditor.renderSideBySide" = true;
      "explorer.fileNesting.patterns" = {
        "*.ts" = "\${capture}.js";
        "*.js" = "\${capture}.js.map, \${capture}.min.js, \${capture}.d.ts";
        "*.jsx" = "\${capture}.js";
        "*.tsx" = "\${capture}.ts";
        "tsconfig.json" = "tsconfig.*.json";
        "package.json" = "package-lock.json, yarn.lock, pnpm-lock.yaml, bun.lockb, bun.lock";
        "*.sqlite" = "\${capture}.\${extname}-*";
        "*.db" = "\${capture}.\${extname}-*";
        "*.sqlite3" = "\${capture}.\${extname}-*";
        "*.db3" = "\${capture}.\${extname}-*";
        "*.sdb" = "\${capture}.\${extname}-*";
        "*.s3db" = "\${capture}.\${extname}-*";
      };
      "claudeCode.preferredLocation" = "panel";
      "update.showReleaseNotes" = false;
      "workbench.colorTheme" = "Dark+";
      "terminal.integrated.fontFamily" = "CaskaydiaMono Nerd Font, monospace";
      "git.enableSmartCommit" = true;
      "terminal.integrated.mouseWheelScrollSensitivity" = 3;
      "terminal.integrated.gpuAcceleration" = "off";
      "yaml.disableSchemaDetection" = [
        "**/.github/workflows/*.yml"
        "**/.github/workflows/*.yaml"
        "**/.gitea/workflows/*.yml"
        "**/.gitea/workflows/*.yaml"
        "**/.forgejo/workflows/*.yml"
        "**/.forgejo/workflows/*.yaml"
      ];
    };
  };
};

wayland.windowManager.hyprland.systemd.enable = false;
}
