<div align="center">

# ❄️ nixos-dotfiles

**A declarative, Flake-driven NixOS + Home Manager setup — Hyprland on Lua, Catppuccin all the way down.**

<p>
  <img alt="NixOS" src="https://img.shields.io/badge/NixOS-26.05-5277C3?logo=nixos&logoColor=white">
  <img alt="Flakes" src="https://img.shields.io/badge/Flakes-enabled-8AADF4">
  <img alt="Home Manager" src="https://img.shields.io/badge/Home%20Manager-26.05-8bd5ca">
  <img alt="Hyprland" src="https://img.shields.io/badge/Hyprland-Wayland-a6da95">
  <img alt="Catppuccin" src="https://img.shields.io/badge/Theme-Catppuccin%20Macchiato-ed8796">
  <img alt="License" src="https://img.shields.io/badge/License-MIT-eea4ff">
</p>

</div>

---

> [!NOTE]
> This is a personal configuration tuned for an **NVIDIA laptop on x86_64-linux**. It's shared here as a reference and a starting point — not a drop-in distro. Expect to edit hardware, drivers, and packages for your own machine.

## ✨ Highlights

- **Fully declarative** — one Flake rebuilds the entire system and user environment from a single repo.
- **Hyprland, configured in Lua** via [`hyprlua`](https://github.com/hyprwm/hyprlua) — no 1000-line `hyprland.conf`.
- **Catppuccin Macchiato** with a teal accent, applied consistently across Hyprland borders, GTK, cursors, the Linux console, and Plymouth.
- **Aggregated module layout** — `nixos/modules` is grouped into 10 domain subdirectories instead of 50 loose files.
- **Host-identity decoupling** — clone, change one line, rebuild. No folder renaming.
- **Hardened by default** — `sudo-rs`, TPM2, Yubikey PAM/u2f, AppArmor + the full LSM stack, kernel hardening.

## 📑 Table of Contents

- [The Stack](#-the-stack)
- [Repository Structure](#-repository-structure)
- [How It's Wired](#-how-its-wired)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Customization](#-customization)
- [Keybindings](#-keybindings)
- [Shell & CLI Goodies](#-shell--cli-goodies)
- [Theming](#-theming)
- [Notes & Caveats](#-notes--caveats)
- [Acknowledgements](#-acknowledgements)

## 🧱 The Stack

| Domain         | Choice                                                                 |
|----------------|------------------------------------------------------------------------|
| OS             | NixOS 26.05, Flakes                                                    |
| User env       | Home Manager 26.05 (via `home-manager.nixosModules`)                   |
| Compositor     | Hyprland (UWSM-managed), configured in **Lua** with `hyprlua`          |
| Display manager| `greetd` + `tuigreet`                                                  |
| Bar            | Waybar                                                                 |
| Notifications  | SwayNC                                                                 |
| Launcher       | Wofi / Hyprlauncher                                                    |
| Lock / idle    | Hyprlock + Hypridle                                                    |
| Logout menu    | Wlogout                                                                |
| Wallpaper      | Swaybg                                                                 |
| Terminal       | Ghostty                                                                |
| Shell          | Zsh + Oh-My-Zsh (amuse theme), autosuggestions, syntax highlighting    |
| Browser        | Google Chrome (SUPER+B)                                                |
| File manager   | Dolphin                                                                |
| Editor         | Neovim                                                                 |
| Theme          | Catppuccin Macchiato, teal accent                                      |
| Fonts          | JetBrains Mono + Nerd Fonts, Noto Color Emoji                          |
| Graphics       | NVIDIA (modesetting, container toolkit) + Mesa / VA-API                |
| Audio          | PipeWire + WirePlumber                                                 |
| Power          | TLP + Thermald                                                         |
| VPN            | Tailscale                                                              |
| Security       | `sudo-rs`, TPM2, Yubikey PAM/u2f, AppArmor, kernel LSM hardening       |

## 🗂 Repository Structure

```
nixos-dotfiles/
├── flake.nix                 # Flake entry — inputs, host list, nixosSystem wiring
│
├── hosts/
│   └── nixos/                # Per-host machine config
│       ├── configuration.nix # imports the module tree, sets hostName + stateVersion
│       ├── hardware-configuration.nix   # generated — disks, kernel modules
│       └── local-packages.nix           # host-specific system packages
│
├── nixos/
│   └── modules/              # System-level modules (10 domain subdirectories)
│       ├── default.nix       #   aggregator: imports all 10 subdirs
│       ├── boot/             #   bootloader (systemd-boot + Plymouth), kernel, swap
│       ├── hardware/         #   Bluetooth, NVIDIA, screen brightness
│       ├── networking/       #   interfaces, DNS, firewall, Tailscale
│       ├── desktop/          #   greetd, Hyprland, theme, fonts
│       ├── i18n/             #   locale, timezone, keyboard layout
│       ├── nix/              #   nix settings, overlays, GC, env vars, Home Manager
│       ├── security/         #   sudo-rs, TPM2, Yubikey
│       ├── services/         #   dbus, power, PipeWire, USB, radicle, virtualisation
│       ├── development/      #   direnv, LSPs, languages, terminals, fetchers
│       └── users/            #   the user account, work packages
│
├── home-manager/
│   ├── home.nix              # Home Manager entry
│   ├── home-packages.nix     # user-level packages
│   └── modules/              # git, zsh, fzf, py-file-opener, dotfile symlinks
│
└── home/
    ├── .config/              # raw dotfiles (symlinked into ~/.config by Home Manager)
    │   ├── hypr/             #   Hyprland Lua config (monitors, input, bindings, …)
    │   ├── waybar/           #   bar config + style + sysinfo script
    │   ├── swaync/           #   notification daemon config + style
    │   ├── wofi/             #   launcher + exit-prompt styles
    │   ├── wlogout/          #   logout screen
    │   ├── ghostty/          #   terminal config
    │   ├── eza/              #   eza theme.yml (colors + icons)
    │   └── zsh/              #   zshrc_addon.zsh (custom functions)
    └── wallpaper/            # the wallpaper
```

## 🔌 How It's Wired

```
flake.nix
   │  hosts = [{ name = "nixos"; hostname = "nixos"; ... }]
   │  makeSystem → nixpkgs.lib.nixosSystem
   ▼
hosts/nixos/configuration.nix
   │  imports = [ ./hardware-configuration.nix ./local-packages.nix ../../nixos/modules ]
   ▼
nixos/modules/default.nix  ──►  boot/ hardware/ networking/ … users/
   │
   └─ nix/home-manager.nix  ──►  home-manager/home.nix ──► home-manager/modules/*
```

- **`flake.nix`** defines a `hosts` list and folds it into `nixosConfigurations`.
- **`hosts/<name>/configuration.nix`** is the only host-specific entrypoint; it pulls in the shared module tree and sets `networking.hostName` from the `hostname` special arg.
- **`nixos/modules/default.nix`** aggregates the 10 category subdirectories — each of which is itself a `default.nix` that imports its own sub-files. Move a file, not ten imports.
- **`home-manager/modules/dotfiles-symlinks.nix`** symlinks the raw `home/.config/*` directories into `~/.config` with `mkOutOfStoreSymlink`, so edits to Hyprland/Waybar/etc. take effect without a rebuild.

## ✅ Prerequisites

- An **x86_64** machine (the Flake pins `systems.url = "github:nix-systems/x86_64-linux"`).
- Nix with **flakes** enabled. On a non-NixOS host:
  ```sh
  sh <(curl -L https://nixos.org/nix/install) --daemon
  mkdir -p ~/.config/nix && echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
  ```
- For a fresh NixOS install, you'll need a generated `hardware-configuration.nix` for your disks — the one in this repo is machine-specific.

## 🚀 Installation

> [!IMPORTANT]
> Fresh install or not, these steps overwrite your system config — read them before running.

### From a live USB (fresh install)

For partitioning, formatting, and mounting the disk (and generating the initial NixOS config), follow [tony's NixOS-from-scratch guide](https://www.tonybtw.com/tutorial/nixos-from-scratch/) up to the `nixos-generate-config --root /mnt` step. Then, to install **this** repo:

1. **Clone it** onto the target (the flake can live anywhere — `nixos-install` points at it explicitly):
   ```sh
   git clone https://github.com/manojmanivannan/nixos-dotfiles.git /mnt/etc/nixos-dotfiles
   ```

2. **Point the flake at your machine** — edit `flake.nix`:
   ```nix
   user = "your-username";          # flows to the user account, docker group, Home Manager, env vars
   hosts = [
     { name = "nixos"; hostname = "your-hostname"; inherit stateVersion; }
   ];
   ```
   `name` is the stable identity (the flake attr `.nixos` and the `hosts/<name>/` folder) — leave it as `nixos`. `hostname` is the machine's network name, `user` is your login name. These two lines are the only edits most cloners need.

3. **Drop in the generated hardware config:**
   ```sh
   cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos-dotfiles/hosts/nixos/
   ```

4. **Install, set the user password, then reboot:**
   ```sh
   nixos-install --flake /mnt/etc/nixos-dotfiles#nixos
   nixos-enter --root /mnt -c 'passwd your-username'
   reboot
   ```
   The `#nixos` is the flake attr (the `name` field), **not** your machine's hostname.

The copy under `/mnt/etc/nixos-dotfiles` was only needed for the install — after first boot, re-clone to `~/nixos-dotfiles` (see below) for ongoing rebuilds.

### On an already-installed system

Skip partitioning, mounting, and `nixos-install`. Clone to `~/nixos-dotfiles`, run steps 2-3 against that clone, then:

```sh
sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos   # alias: nrs
```

> [!NOTE]
> The user account is declared with **no password** in the config — deliberately, so no plaintext ever lands in the repo or the Nix store. It's created locked, which is why step 4 sets one via `nixos-enter` before rebooting (essential here: `greetd`/`tuigreet` offer no `root` login, so without it there's no way in on first boot). On an already-running system instead, use `sudo passwd <your-username>`.

## 🛠 Customization

### Add a second host

```nix
hosts = [
  { name = "nixos";  hostname = "nixos";  inherit stateVersion; }
  { name = "laptop"; hostname = "thinky"; inherit stateVersion; }
];
```
Then create `hosts/laptop/configuration.nix` (copy from `nixos/`), give it its own `hardware-configuration.nix`, and rebuild with `--flake .#laptop`. The `name`/`hostname` split lets the folder + attr stay clean while the network name is whatever you want.

### Toggle a module

Most feature modules are plain files — comment out a line in the relevant `default.nix` to disable it. For example, to drop Tailscale, remove `./vpn.nix` from `nixos/modules/networking/default.nix`.

### Add a system package

- **System-wide:** `hosts/nixos/local-packages.nix` (host-specific) or the appropriate `nixos/modules/*/` file.
- **User-only:** `home-manager/home-packages.nix`.

### Edit the desktop

Hyprland, Waybar, SwayNC, Wofi, Wlogout, Ghostty, and eza configs live as raw files under `home/.config/` and are symlinked into place — just edit them and reload (e.g. `hyprctl reload`); no rebuild needed for most changes. Hyprland itself is configured in **Lua**, split across `home/.config/hypr/`:

| File            | Responsibility                                   |
|-----------------|---------------------------------------------------|
| `hyprland.lua`  | Entry point, autostart, window rules, env vars    |
| `monitors.lua`  | Monitor layout                                    |
| `input.lua`     | Keyboard, touchpad, accel                         |
| `bindings.lua`  | Keybindings                                       |
| `looknfeel.lua` | Gaps, borders, blur, rounding                     |
| `autostart.lua` | Extra `exec-once` processes                       |

## ⌨️ Keybindings

`SUPER` = the Windows key.

| Binding                  | Action                          |
|--------------------------|---------------------------------|
| `SUPER + Return`         | Open terminal (Ghostty)         |
| `SUPER + B`              | Open browser (Chrome)           |
| `SUPER + ESC`            | Logout menu (Wlogout)           |
| `SUPER + Arrows`         | Move focus                      |
| `SUPER + [1-0]`          | Switch to workspace             |
| `SUPER + Shift + [1-0]`  | Move window to workspace        |
| `SUPER + C / V`          | **Universal copy/paste**        |

> [!TIP]
> `SUPER+C`/`SUPER+V` forward to `Ctrl+Insert`/`Shift+Insert` rather than `Ctrl+C`/`Ctrl+V` — the Insert-based combos work in **terminals** too, where `Ctrl+C` is SIGINT, not copy.

See `home/.config/hypr/bindings.lua` for the full set.

## 🐚 Shell & CLI Goodies

The Zsh setup (in `home-manager/modules/zsh.nix` + `home/.config/zsh/zshrc_addon.zsh`) packs a few custom conveniences:

- **`nrs`** — rebuild & switch the system.
- **`gcommit`** — a JIRA-aware commit helper.
- **`fo()`** — fuzzy-open files via [`py-file-opener`](https://github.com/manojmanivannan/py-file-opener), built here as a **pure Nix derivation** (no venv, no `uv` drift).
- **`btw`** — `echo i use nixos-btw`. Because of course.
- **Oh-My-Zsh** with the `amuse` theme, plus `git`, `eza`, `virtualenv`, `z`, `fzf`, and more.
- **`gh`** configured for SSH, wired as Git's GitHub credential helper.

The prompt is a custom one: `<path> <git> <venv> [exit-on-fail]` on the left, `[HH:MM:SS]` on the right.

## 🎨 Theming

A single accent runs through the whole system:

- **Hyprland** — teal (`#8bd5ca`) active borders, `surface2` inactive.
- **GTK / cursors** — `catppuccin-macchiato-teal-standard`, `Catppuccin-Macchiato-Teal` (xcursor + hyprcursor).
- **Console** — the Catppuccin Macchiato 16-color palette applied to the Linux console.
- **Plymouth** — `catppuccin-macchiato` boot splash.
- **eza** — theme YAML for colored, iconified `ls`.

All theme variables are declared in `nixos/modules/desktop/theme.nix`.

## 📝 Notes & Caveats

- **Username** — change the `user = "manoj";` let-binding in `flake.nix`. It flows everywhere via a `specialArg`: the user account, docker group, Home Manager, and env vars. No other file hardcodes the username.
- **Clone path** — the repo assumes it's cloned at `~/nixos-dotfiles`. Nix modules reference it via `${config.home.homeDirectory}/nixos-dotfiles` and the Hyprland Lua configs via `$HOME/nixos-dotfiles` (both expand dynamically). If you clone elsewhere, update those references or just clone at `~/nixos-dotfiles`.
- **`hardware-configuration.nix`** is machine-specific and must be regenerated per box.
- **NVIDIA** is assumed; the `nixos/modules/hardware/nvidia.nix` driver config will need adjustment (or replacement with the AMD/Intel equivalents) on other GPUs.
- **Radicle, virtualisation, Ollama** are defined but disabled — flip them on in `nixos/modules/services/` if you want them.
- **Git identity** (`manojm18@live.in`) is set in `home-manager/modules/git.nix` — change it to yours.

## 🙏 Acknowledgements

- [NixOS](https://nixos.org/) & [Home Manager](https://github.com/nix-community/home-manager) — the declarative foundation.
- [Hyprland](https://hyprland.org/) & [`hyprlua`](https://github.com/hyprwm/hyprlua) — the compositor and its Lua bindings.
- [Catppuccin](https://github.com/catppuccin/catppuccin) — the theme.
- Everyone whose modules, overlays, and dotfiles I read while putting this together.

---

<div align="center">

<sub>Built and maintained by **Manoj Manivannan**. MIT-licensed — see [LICENSE](LICENSE).</sub>
<br>
<sub><i>I use NixOS btw.</i></sub>

</div>