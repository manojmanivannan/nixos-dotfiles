# 🎚️ Profile Tiers Guide (Minimal vs Full)

This guide documents the **minimal** and **full** installation profile tiers in `nixos-dotfiles`. It details how the tiers are designed across system, per-user, and Home-Manager layers, how packages and services are assigned, how to configure or override the profile per host, and how automated tests verify profile integrity.

---

## 📑 Table of Contents

- [Overview & Philosophy](#-overview--philosophy)
- [Layering & Architecture](#-layering--architecture)
- [Software Tier Matrix](#-software-tier-matrix)
  - [System Layer (`nixos/modules/`)](#1-system-layer-nixosmodules)
  - [Per-User Layer (`users.users.<user>.packages`)](#2-per-user-layer-usersusersuserpackages)
  - [Home-Manager Layer (`home-manager/`)](#3-home-manager-layer-home-manager)
- [Configuration & Host Overrides](#-configuration--host-overrides)
  - [Configuring `profile` in `flake.nix`](#configuring-profile-in-flakenix)
  - [Overriding in Host `configuration.nix`](#overriding-in-host-configurationnix)
  - [Adding a Second Host with a Different Profile](#adding-a-second-host-with-a-different-profile)
  - [Developer Guide: Gating New Modules and Packages](#developer-guide-gating-new-modules-and-packages)
- [Evaluation Checks & CI](#-evaluation-checks--ci)

---

## 🌟 Overview & Philosophy

The profile system allows configuring NixOS hosts according to their intended role and resource constraints without duplicating module configurations:

1. **`full` (Default)**:
   - Complete batteries-included workstation and daily-driver setup.
   - Includes full developer toolchains, LSPs, dynamic binary loader (`nix-ld`), containerised gaming (Steam + GameMode + 32-bit graphics), media editing/playback suites, desktop GUI applications (Google Chrome, VS Code), and heavy desktop suites (Google Antigravity Base App/IDE/CLI, Obsidian, Playwright browser binaries, and Herdr).
   - Reproduces the complete workstation setup bit-for-bit with zero regressions.

2. **`minimal`**:
   - Lightweight, lean desktop/utility profile suitable for secondary machines, lighter laptops, testing VMs, or hosts requiring fast rebuild times and reduced disk footprints.
   - Retains the full Hyprland compositor, Caelestia Quickshell desktop shell, warm-metal theming, audio/video subsystem, security stack, core terminal environment (Zsh, Ghostty, Starship, ripgrep, fzf, bat, git), and base Wayland utility toolchain.
   - Omits heavy development runtimes, LSPs, gaming stacks, media suites, and large binary applications.

---

## 🏗 Layering & Architecture

The active profile is defined per-host in `flake.nix` and flows cleanly through three configuration layers:

```
                      flake.nix (hosts = [{ profile = "minimal" | "full"; ... }])
                                           │
                                           │ specialArgs = { profile, ... }
                                           ▼
             ┌───────────────────────────────────────────────────────────┐
             │                   NixOS System Layer                      │
             │           (nixos/modules/profile/default.nix)             │
             │                options.manoj.profile                      │
             └─────────────────────────────┬─────────────────────────────┘
                                           │
                       ┌───────────────────┴───────────────────┐
                       │                                       │
                       ▼                                       ▼
    ┌─────────────────────────────────────┐ ┌─────────────────────────────────────┐
    │          Per-User Layer             │ │         Home-Manager Layer          │
    │   (nixos/modules/users/users.nix)   │ │  (nixos/modules/nix/home-manager.nix│
    │     users.users.<user>.packages     │ │   home-manager.extraSpecialArgs     │
    │ lib.optionals (profile == "full")   │ │                │                    │
    └─────────────────────────────────────┘ │                ▼                    │
                                            │ (home-manager/modules/profile.nix)  │
                                            │        options.manoj.profile        │
                                            │                │                    │
                                            │                ▼                    │
                                            │ (home-manager/home-packages.nix)    │
                                            │ lib.optionals (profile == "full")   │
                                            └─────────────────────────────────────┘
```

1. **Flake Level (`flake.nix`)**: `makeSystem` receives `profile ? "full"` (defaults to `"full"` if omitted). Host definitions can explicitly specify `profile = "minimal"` or `profile = "full"`.
2. **NixOS System Level (`nixos/modules/profile/default.nix`)**: Declares `options.manoj.profile` with `enum [ "minimal" "full" ]` defaulting to `"full"`, populated by `config.manoj.profile = lib.mkDefault profile;`. Heavy system modules check `config.manoj.profile == "full"`.
3. **Per-User Level (`nixos/modules/users/users.nix`)**: Gated packages in `users.users.<user>.packages` are filtered using `lib.optionals (config.manoj.profile == "full")`.
4. **Home-Manager Level (`home-manager/modules/profile.nix`)**: Declares a matching `options.manoj.profile` in Home-Manager. `nixos/modules/nix/home-manager.nix` sets `home-manager.extraSpecialArgs.profile = config.manoj.profile;`, allowing user modules and `home-packages.nix` to gate packages consistently.

---

## 📊 Software Tier Matrix

The table below breaks down package and subsystem assignments across all configuration layers.

### 1. System Layer (`nixos/modules/`)

| Subsystem / Module | Minimal (`minimal`) | Full (`full`) | Notes |
| :--- | :--- | :--- | :--- |
| **Boot & Kernel** (`boot/`) | `systemd-boot`, Plymouth (Catppuccin Macchiato), Linux Kernel, zram/swap | `systemd-boot`, Plymouth, Linux Kernel, zram/swap | Unconditional base bootloader & kernel stack. |
| **Hardware** (`hardware/`) | NVIDIA drivers, modesetting, Bluetooth, brightness control (`brightnessctl`) | NVIDIA drivers, modesetting, Bluetooth, brightness control (`brightnessctl`) | Unconditional hardware acceleration & peripherals. |
| **Security** (`security/`) | `sudo-rs`, TPM2, Yubikey PAM/u2f, AppArmor, kernel hardening | `sudo-rs`, TPM2, Yubikey PAM/u2f, AppArmor, kernel hardening | Full LSM and hardware security stack is always enabled. |
| **Networking** (`networking/`) | NetworkManager, firewall, Avahi, Tailscale VPN | NetworkManager, firewall, Avahi, Tailscale VPN | Full networking & mesh VPN stack is always enabled. |
| **Desktop Environment** (`desktop/`) | Hyprland (UWSM), `greetd` + `tuigreet`, warm-metal GTK themes, fonts | Hyprland (UWSM), `greetd` + `tuigreet`, warm-metal GTK themes, fonts | Core Wayland compositor and theming environment. |
| **Base Core Utilities** (`services/services.nix`) | `grim`, `slurp`, `wl-screenrec`, `wl-clipboard`, `wl-clip-persist`, `cliphist`, `libnotify`, `xdg-utils`, `at-spi2-atk`, `qt6.qtwayland`, `playerctl`, `psmisc`, `libfido2` | `grim`, `slurp`, `wl-screenrec`, `wl-clipboard`, `wl-clip-persist`, `cliphist`, `libnotify`, `xdg-utils`, `at-spi2-atk`, `qt6.qtwayland`, `playerctl`, `psmisc`, `libfido2` | Essential Wayland clipboard, screenshotting, screenrecording, accessibility, and notifications. |
| **Media Suite** (`services/services.nix`) | *None* | `qutebrowser`, `zathura`, `mpv`, `mpv-handler`, `imv`, `imagemagick`, `swappy`, `ffmpeg_6-full` | Gated to `full` via `lib.optionals`. |
| **Core Dev Tools & Terminal** (`development/`) | `zsh`, `ghostty`, `starship`, `ripgrep`, `yt-dlp`, `jq`, `fzf`, `bat`, `fd`, `gcc`, `git`, `gh` | `zsh`, `ghostty`, `starship`, `ripgrep`, `yt-dlp`, `jq`, `fzf`, `bat`, `fd`, `gcc`, `git`, `gh` | Base CLI productivity and build tools present in all profiles. |
| **Language Servers** (`development/lsp.nix`) | *None* | `nil`, `nixd`, `ruff`, `jsonnet-language-server`, `yaml-language-server`, `marksman`, `taplo`, `bash-language-server`, `dockerfile-language-server-nodejs` | Gated to `full` via `lib.mkIf`. |
| **Language Runtimes & Loader** (`development/programming-languages.nix`) | *None* | `nix-ld`, `nodejs_20`, `bun`, `uv` | Gated to `full` via `lib.mkIf`. |
| **Info Fetchers & Monitors** (`development/info-fetchers.nix`) | *None* | `fastfetch`, `btop`, `nvtopPackages.full` | Gated to `full` via `lib.mkIf`. |
| **Gaming Stack** (`programs/gaming.nix`) | *None* | `programs.steam` (Steam client & runtime), `hardware.graphics.enable32Bit`, `programs.gamemode` | Gated to `full` via `lib.mkIf`. |

---

### 2. Per-User Layer (`users.users.<user>.packages`)

| Application | Minimal (`minimal`) | Full (`full`) | Notes |
| :--- | :---: | :---: | :--- |
| **VS Code** (`pkgs.vscode`) | ❌ | ✅ | Gated in `nixos/modules/users/users.nix`. |
| **Google Chrome** (`pkgs.google-chrome`) | ❌ | ✅ | Gated in `nixos/modules/users/users.nix`. |
| **User Shell & Groups** | `zsh`, `input`, `wheel`, `video`, `audio`, `tss` | `zsh`, `input`, `wheel`, `video`, `audio`, `tss` | Always configured. |
| **Authorized SSH Keys** | Managed keys | Managed keys | Always configured. |

---

### 3. Home-Manager Layer (`home-manager/`)

| Package / Module | Minimal (`minimal`) | Full (`full`) | Notes |
| :--- | :---: | :---: | :--- |
| **Caelestia Desktop Shell** (`modules/caelestia.nix`) | ✅ | ✅ | Full Quickshell bar, notifications, launcher, lockscreen, and systemd service. |
| **Hyprland Lua Symlinks** (`modules/dotfiles-symlinks.nix`) | ✅ | ✅ | Out-of-store symlinks for `config/.config/*`. |
| **Shell & Core Tools** (`modules/zsh.nix`, `git.nix`, etc.) | ✅ | ✅ | `zsh`, `fzf`, `zoxide`, `bat`, `lazygit`, `yazi`, `try`, `py-file-opener`, `vim`, `git`. |
| **Core Home Packages** (`home-packages.nix`) | `nixfmt`, `eza`, `nautilus`, `localsend` | `nixfmt`, `eza`, `nautilus`, `localsend` | Lightweight user tools present in all profiles. |
| **Playwright Browsers** (`playwright-driver.browsers`) | ❌ | ✅ | Gated in `home-packages.nix`. |
| **Obsidian** (`pkgs.obsidian`) | ❌ | ✅ | Gated in `home-packages.nix`. |
| **Herdr** (`inputs.herdr.packages`) | ❌ | ✅ | Gated in `home-packages.nix`. |
| **Antigravity Base App** (`inputs.antigravity-nix`) | ❌ | ✅ | Gated in `home-packages.nix`. |
| **Antigravity IDE** (`inputs.antigravity-nix`) | ❌ | ✅ | Gated in `home-packages.nix`. |
| **Antigravity CLI (`agy`)** (`inputs.antigravity-nix`) | ❌ | ✅ | Gated in `home-packages.nix`. |

---

## ⚙️ Configuration & Host Overrides

### Configuring `profile` in `flake.nix`

In `flake.nix`, each host entry in the `hosts` list accepts an optional `profile` attribute (`"minimal"` or `"full"`). If omitted, `profile` defaults to `"full"`:

```nix
# flake.nix
hosts = [
  {
    name = "nixos";
    hostname = "linux-machine";
    profile = "full";      # "full" (default) or "minimal"
    ipv4Address = "192.168.1.192";
    defaultGateway = "192.168.1.1";
    inherit stateVersion;
  }
];
```

To switch a host to the minimal profile, set `profile = "minimal"`:

```nix
# flake.nix
hosts = [
  {
    name = "nixos";
    hostname = "linux-machine";
    profile = "minimal";
    ipv4Address = "192.168.1.192";
    defaultGateway = "192.168.1.1";
    inherit stateVersion;
  }
];
```

---

### Overriding in Host `configuration.nix`

Because `manoj.profile` uses `lib.mkDefault`, you can also set or override the profile directly inside a host's `hosts/<name>/configuration.nix`:

```nix
# hosts/nixos/configuration.nix
{
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ../../nixos/modules
  ];

  # Explicitly override the profile tier for this host
  manoj.profile = "minimal";

  networking.hostName = "linux-machine";
  system.stateVersion = "26.05";
}
```

---

### Adding a Second Host with a Different Profile

To add a lightweight host (e.g. `laptop` running `minimal`) alongside a full workstation:

```nix
# flake.nix
hosts = [
  {
    name = "nixos";
    hostname = "workstation";
    profile = "full";
    ipv4Address = "192.168.1.192";
    defaultGateway = "192.168.1.1";
    inherit stateVersion;
  }
  {
    name = "laptop";
    hostname = "thinkpad";
    profile = "minimal";
    ipv4Address = "192.168.1.193";
    defaultGateway = "192.168.1.1";
    inherit stateVersion;
  }
];
```

Then create `hosts/laptop/configuration.nix` and `hosts/laptop/hardware-configuration.nix`, and rebuild using:

```sh
sudo nixos-rebuild switch --flake .#laptop
```

---

### Developer Guide: Gating New Modules and Packages

When adding new packages or modules to the repository, adhere to these standard gating patterns:

1. **Entire Module is Heavy / Full-Only** (e.g. Language Servers, Compilers, Game Suites):
   Wrap the module body with `lib.mkIf`:
   ```nix
   { config, lib, pkgs, ... }:

   lib.mkIf (config.manoj.profile == "full") {
     environment.systemPackages = with pkgs; [
       heavyPackage1
       heavyPackage2
     ];
   }
   ```

2. **Module Contains Both Base and Heavy Packages** (e.g. `services.nix`):
   Keep the module unconditional and split `environment.systemPackages`:
   ```nix
   { config, lib, pkgs, ... }:

   {
     environment.systemPackages = with pkgs; [
       coreUtility1
       coreUtility2
     ] ++ lib.optionals (config.manoj.profile == "full") [
       heavyMediaApp1
       heavyMediaApp2
     ];
   }
   ```

3. **Home-Manager Packages** (`home-manager/home-packages.nix`):
   Use `lib.optionals` against `config.manoj.profile`:
   ```nix
   { config, inputs, lib, pkgs, ... }:
   {
     home.packages = with pkgs; [
       baseTool
     ] ++ lib.optionals (config.manoj.profile == "full") [
       heavyGuiApp
       inputs.heavyFlakeInput.packages.${pkgs.stdenv.hostPlatform.system}.default
     ];
   }
   ```

---

## 🧪 Evaluation Checks & CI

The profile implementation is protected by automated evaluation assertions and CI checks in `flake.nix`:

### Automated Checks (`checks.${system}`)

Running `nix flake check` automatically executes:

1. **`check-<host>-builds`**: WF-9 build-seam check asserting that each host toplevel evaluates and builds from the flake.
2. **`check-profile-evaluations`**: Concurrently evaluates both `minimal` and `full` configurations and programmatically asserts:
   - Option values (`minCfg.manoj.profile == "minimal"` and `fullCfg.manoj.profile == "full"`).
   - Gaming options (Steam, GameMode, 32-bit graphics disabled in `minimal`, enabled in `full`).
   - Sentinel packages absent in `minimal` and present in `full` (`steam`, `google-chrome`, `vscode`, `obsidian`, `fastfetch`, `btop`, `nvtop`, LSPs, media tools, Antigravity suite).
   - Core packages present in **both** `minimal` and `full` (`zsh`, `vim`, `grim`, `slurp`, `wl-clipboard`, `wl-screenrec`, `cliphist`, `libnotify`, `xdg-utils`, `nautilus`, `localsend`, `eza`, `nixfmt`).

### Commands

```sh
# Run all flake checks and evaluation assertions
nix flake check

# Build the system toplevel for the minimal evaluation test config
nix build .#profileConfigs.minimal.system.build.toplevel

# Build the system toplevel for the full evaluation test config
nix build .#profileConfigs.full.system.build.toplevel
```

### GitHub Actions CI

Continuous integration (`.github/workflows/ci.yml`) runs on every pull request and push to `main`:
- **Determinate Systems Flake Checker**: Verifies flake health and input locks.
- **Nix Flake Check**: Executes `nix flake check` ensuring all host builds and profile assertions pass cleanly.
