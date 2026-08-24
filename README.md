<div align="center">

# ❄️ nixos-dotfiles

**A declarative, Flake-driven NixOS + Home Manager setup — Hyprland on Lua, Caelestia shell, warm-metal all the way down.**

<p>
  <img alt="NixOS" src="https://img.shields.io/badge/NixOS-26.05-5277C3?logo=nixos&logoColor=white">
  <img alt="Flakes" src="https://img.shields.io/badge/Flakes-enabled-8AADF4">
  <img alt="Home Manager" src="https://img.shields.io/badge/Home%20Manager-26.05-8bd5ca">
  <img alt="Hyprland" src="https://img.shields.io/badge/Hyprland-Wayland-a6da95">
  <img alt="Shell" src="https://img.shields.io/badge/Shell-Caelestia%20(Quickshell)-d99a9a">
  <img alt="Theme" src="https://img.shields.io/badge/Theme-Warm%20Metal-e8c272">
  <img alt="License" src="https://img.shields.io/badge/License-MIT-eea4ff">
</p>

</div>

---

> [!NOTE]
> This is a personal configuration tuned for an **NVIDIA laptop on x86_64-linux**. It's shared here as a reference and a starting point — not a drop-in distro. Expect to edit hardware, drivers, and packages for your own machine.

## ✨ Highlights

- **Fully declarative** — one Flake rebuilds the entire system and user environment from a single repo.
- **Hyprland, configured in Lua** via [`hyprlua`](https://github.com/hyprwm/hyprlua) — no 1000-line `hyprland.conf`.
- **Caelestia shell** ([Quickshell](https://quickshell.outfoxxed.nl/) full-shell) — owns the bar, notifications, launcher, power menu, **and the lock screen**, replacing waybar / swaync / wofi / wlogout / hyprlock.
- **Warm-metal theme** — brushed gold / copper / bronze on warm espresso, consistent across Hyprland borders, GTK, Ghostty, and the Linux console (cursors and Plymouth stay Catppuccin-Macchiato-teal until warm variants are adopted).
- **Aggregated module layout** — `nixos/modules` is grouped into domain subdirectories instead of 50 loose files.
- **Host-identity decoupling** — clone, change one line, rebuild. No folder renaming.
- **Install Profile Tiers (`minimal` vs `full`)** — per-host profile gating for lightweight base or full development/gaming setups.
- **Hardened by default** — `sudo-rs`, TPM2, Yubikey PAM/u2f, AppArmor + the full LSM stack, kernel hardening.

## 📑 Table of Contents

- [The Stack](#-the-stack)
- [Repository Structure](#-repository-structure)
- [How It's Wired](#-how-its-wired)
- [Install Profiles (Minimal vs Full)](#-install-profiles-minimal-vs-full)
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
| Desktop shell  | Caelestia (Quickshell full-shell) — bar, notifications, launcher, power menu, lock |
| Launcher       | Caelestia launcher (SUPER+SPACE)                                       |
| Notifications  | Caelestia sidebar (SUPER+N)                                            |
| Lock / idle    | Caelestia `Lock` + Hypridle (auto-lock @600s)                          |
| Power menu     | Caelestia session menu (SUPER+ESC)                                     |
| Wallpaper      | Swaybg                                                                 |
| Terminal       | Ghostty                                                                |
| Shell          | Zsh + Oh-My-Zsh (amuse theme), autosuggestions, syntax highlighting    |
| Browser        | Google Chrome (SUPER+B)                                                |
| File manager   | Nautilus (SUPER+E)                                                     |
| Editor         | Vim                                                                    |
| Theme          | Warm-metal (gold/copper/bronze); Catppuccin-Macchiato-teal cursors/Plymouth |
| Fonts          | JetBrains Mono + Nerd Fonts, Noto Color Emoji                          |
| Graphics       | NVIDIA (modesetting, container toolkit) + Mesa / VA-API                |
| Audio          | PipeWire + WirePlumber                                                 |
| Power          | TLP + Thermald                                                         |
| VPN            | Tailscale                                                              |
| Security       | `sudo-rs`, TPM2, Yubikey PAM/u2f, AppArmor, kernel LSM hardening       |

## 🗂 Repository Structure

```
nixos-dotfiles/
├── flake.nix                 # Flake entry — inputs, host list, profile wiring, nixosSystem
│
├── docs/
│   └── profile-tiers.md      # Detailed profile tiers reference guide & software matrix
│
├── hosts/
│   └── nixos/                # Per-host machine config
│       ├── configuration.nix # imports the module tree, sets hostName + stateVersion + profile
│       ├── hardware-configuration.nix   # generated — disks, kernel modules
│       └── local-packages.nix           # host-specific system packages
│
├── nixos/
│   └── modules/              # System-level modules (domain subdirectories)
│       ├── default.nix       #   aggregator: imports all domain subdirs
│       ├── boot/             #   bootloader (systemd-boot + Plymouth), kernel, swap
│       ├── hardware/         #   Bluetooth, NVIDIA, screen brightness
│       ├── networking/       #   interfaces, DNS, firewall, Tailscale
│       ├── desktop/          #   greetd, Hyprland, theme, fonts
│       ├── i18n/             #   locale, timezone, keyboard layout
│       ├── nix/              #   nix settings, overlays, GC, env vars, Home Manager
│       ├── security/         #   sudo-rs, TPM2, Yubikey
│       ├── services/         #   dbus, power, PipeWire, USB, desktop utilities & media
│       ├── programs/         #   gaming stack (Steam, GameMode)
│       ├── development/      #   direnv, LSPs, languages, terminals, fetchers
│       ├── users/            #   the user account, work packages
│       └── profile/          #   manoj.profile option declaration & defaults
│
├── home-manager/
│   ├── home.nix              # Home Manager entry
│   ├── home-packages.nix     # user-level packages (base & gated heavy packages)
│   └── modules/              # git, zsh, fzf, caelestia, py-file-opener, profile, dotfiles
│
└── config/
    ├── .config/              # raw dotfiles (symlinked into ~/.config by Home Manager)
    │   ├── hypr/             #   Hyprland Lua config (monitors, input, bindings, …)
    │   ├── caelestia/        #   Caelestia shell runtime config (scheme, tokens, scripts)
    │   ├── ghostty/          #   terminal config
    │   ├── gtk-3.0/ gtk-4.0/ #   warm-metal GTK overrides (gtk.css)
    │   ├── eza/              #   eza theme.yml (colors + icons)
    │   └── zsh/              #   zshrc_addon.zsh (custom functions)
    └── wallpaper/            # the wallpaper
```

## 🔌 How It's Wired

```
flake.nix
   │  hosts = [{ name = "nixos"; hostname = "nixos"; profile = "full"; ... }]
   │  makeSystem → nixpkgs.lib.nixosSystem (specialArgs = { profile, ... })
   ▼
hosts/nixos/configuration.nix
   │  imports = [ ./hardware-configuration.nix ./local-packages.nix ../../nixos/modules ]
   ▼
nixos/modules/default.nix  ──►  boot/ hardware/ networking/ … profile/
   │  options.manoj.profile = "full" | "minimal"
   │
   └─ nix/home-manager.nix  ──►  home-manager/home.nix ──► home-manager/modules/*
      (extraSpecialArgs = { profile = config.manoj.profile; })
```

- **`flake.nix`** defines a `hosts` list with optional `profile` settings (`"minimal"` or `"full"`, defaulting to `"full"`), forwarding `specialArgs` into NixOS and Home Manager.
- **`hosts/<name>/configuration.nix`** is the host-specific entrypoint; it pulls in the shared module tree and sets `networking.hostName` and optional `manoj.profile` overrides.
- **`nixos/modules/default.nix`** aggregates the domain subdirectories — each of which is itself a `default.nix` that imports its own sub-files.
- **`nixos/modules/profile/default.nix`** and **`home-manager/modules/profile.nix`** declare `manoj.profile`, allowing heavy modules and packages to be cleanly gated.
- **`home-manager/modules/dotfiles-symlinks.nix`** symlinks the raw `config/.config/*` files/directories into `~/.config` with `mkOutOfStoreSymlink`, so edits to Hyprland/Caelestia/etc. take effect without a rebuild. Caelestia itself is launched as a systemd `caelestia.service` (wired in `home-manager/modules/caelestia.nix`), not a Hyprland `exec-once`.

## 🎚️ Install Profiles (Minimal vs Full)

The configuration supports two install profile tiers configured per-host via `flake.nix`:

- **`full` (Default)** — complete workstation environment with development toolchains, LSPs, language runtimes (`nix-ld`, Node, Bun, UV), gaming stack (Steam, GameMode, 32-bit graphics), media suite (MPV, Qutebrowser, FFmpeg, Swappy), GUI apps (Chrome, VSCode), and desktop suites (Google Antigravity suite, Obsidian, Playwright, Herdr).
- **`minimal`** — lean base desktop and utility profile. Retains the full Hyprland compositor, Caelestia shell, warm-metal theme, audio/video pipeline, hardware acceleration, security stack, core terminal utilities (Zsh, Ghostty, Starship, ripgrep, fzf, bat, git), and base Wayland desktop utilities (`grim`, `slurp`, `wl-clipboard`, `wl-screenrec`, `cliphist`, `libnotify`, `nautilus`, `localsend`, `eza`), while omitting heavy development runtimes, LSPs, media apps, gaming, and large application binaries.

### Tier Breakdown Matrix

| Layer | Subsystem / Package Area | Minimal (`minimal`) | Full (`full`, default) |
| :--- | :--- | :--- | :--- |
| **System** (`nixos/modules/`) | **Boot, Hardware & Security** | systemd-boot, Plymouth, NVIDIA, Bluetooth, `sudo-rs`, TPM2, Yubikey, AppArmor | Same (Always on) |
| | **Networking & VPN** | NetworkManager, Firewall, Tailscale VPN | Same (Always on) |
| | **Desktop Compositor** | Hyprland (UWSM), `greetd`/`tuigreet`, warm-metal GTK themes & fonts | Same (Always on) |
| | **Core Wayland & Desktop Utilities** | `grim`, `slurp`, `wl-clipboard`, `wl-screenrec`, `cliphist`, `libnotify`, `xdg-utils` | Same (Always on) |
| | **Media & Graphics Suite** | *Omitted* | `qutebrowser`, `zathura`, `mpv`, `mpv-handler`, `imv`, `imagemagick`, `swappy`, `ffmpeg` |
| | **Core Dev Tools & Terminal** | `zsh`, `ghostty`, `starship`, `ripgrep`, `jq`, `fzf`, `bat`, `fd`, `gcc`, `git`, `gh` | Same (Always on) |
| | **Language Servers (LSPs)** | *Omitted* | `nil`, `nixd`, `ruff`, `yaml-language-server`, `marksman`, `taplo`, `bash-language-server`, etc. |
| | **Language Runtimes & Loader** | *Omitted* | `nix-ld` (unpatched dynamic loader), `nodejs_20`, `bun`, `uv` |
| | **System Monitors & Fetchers** | *Omitted* | `fastfetch`, `btop`, `nvtop` |
| | **Gaming Stack** | *Omitted* | `steam`, `hardware.graphics.enable32Bit`, `gamemode` |
| **Per-User** (`users.users.<user>`) | **GUI Desktop Applications** | *Omitted* | `vscode`, `google-chrome` |
| **Home-Manager** (`home-manager/`) | **Desktop Shell & Configs** | Caelestia Quickshell suite, Hyprland Lua symlinks, GTK & Ghostty styling | Same (Always on) |
| | **CLI & Productive Tools** | `nixfmt`, `eza`, `nautilus`, `localsend`, `zoxide`, `lazygit`, `yazi`, `try`, `vim` | Same (Always on) |
| | **Heavy Suites & Packages** | *Omitted* | Antigravity suite (Base App, IDE, CLI `agy`), `obsidian`, `herdr`, `playwright-driver.browsers` |

### Setting Host Profile

Set `profile = "minimal"` or `profile = "full"` for any host in `flake.nix`:

```nix
# flake.nix
hosts = [
  {
    name = "nixos";
    hostname = "linux-machine";
    profile = "minimal";  # "minimal" or "full" (default: "full")
    ipv4Address = "192.168.1.192";
    defaultGateway = "192.168.1.1";
    inherit stateVersion;
  }
];
```

Or override within a host's `hosts/<name>/configuration.nix`:

```nix
manoj.profile = "minimal"; # or "full"
```

For complete architectural details, module developer guidelines, and CI test harnesses, see the [Profile Tiers Guide](docs/profile-tiers.md).

## ✅ Prerequisites

- An **x86_64** machine (the Flake pins `systems.url = "github:nix-systems/x86_64-linux"`).
- Nix with **flakes** enabled. On a non-NixOS host:
  ```sh
  sh <(curl -L https://nixos.org/nix/install) --daemon
  mkdir -p ~/.config/nix && echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
  ```

## 🚀 Installation

> [!IMPORTANT]
> These steps overwrite your system config — read them before running.

> [!WARNING]
> Do **not** try to build this repo from a manual/guix-style from-scratch install (partition → format → mount → `nixos-install --flake`). That path does not produce a working boot here. The only verified route is the **NixOS graphical installer** below — install a minimal base first, then layer this flake on top with `nixos-rebuild`.

### 1. Install a minimal NixOS base with the graphical ISO

1. Flash the **NixOS graphical installer ISO** to a USB stick and boot it.
2. Run the installer, but **do not select a desktop environment / display manager** — choose a minimal install (no DE). This gives you a clean, bootable NixOS base with a generated `hardware-configuration.nix` already in place at `/etc/nixos/`.
3. Finish the installer and reboot into the fresh minimal system. Log in and enable flakes if needed:
   ```sh
   mkdir -p ~/.config/nix && echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
   ```

### 2. Clone this repo

```sh
git clone https://github.com/manojmanivannan/nixos-dotfiles.git ~/nixos-dotfiles
```

The repo assumes it's cloned at `~/nixos-dotfiles` (see [Notes & Caveats](#-notes--caveats)).

### 3. Point the flake at your machine

Edit `flake.nix`:

```nix
user = "your-username";          # flows to the user account, docker group, Home Manager, env vars
hosts = [
  { name = "nixos"; hostname = "your-hostname"; inherit stateVersion; }
];
```

`name` is the stable identity (the flake attr `.nixos` and the `hosts/<name>/` folder) — leave it as `nixos`. `hostname` is the machine's network name, `user` is your login name. These two lines are the only edits most cloners need.

### 4. Drop in your generated hardware config

The installer already generated one for your disks — copy it into the repo, overwriting the machine-specific copy that ships here:

```sh
cp /etc/nixos/hardware-configuration.nix ~/nixos-dotfiles/hosts/nixos/
```

### 5. Rebuild and switch

```sh
sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos   # alias: nrs
```

The `#nixos` is the flake attr (the `name` field), **not** your machine's hostname. Reboot after the first switch so `greetd`/`tuigreet` take over as the display manager.

> [!NOTE]
> The user account is declared with **no password** in the config — deliberately, so no plaintext ever lands in the repo or the Nix store. On the minimal base you installed above, your installer-created account already has a password and remains usable; this repo's account is created locked, so set one if you're relying on it:
> ```sh
> sudo passwd <your-username>
> ```
> This matters here because `greetd`/`tuigreet` offer no `root` login, so a locked account with no password means no way in.

## 🛠 Customization

### Add a second host

```nix
hosts = [
  { name = "nixos";  hostname = "nixos";  profile = "full";    inherit stateVersion; }
  { name = "laptop"; hostname = "thinky"; profile = "minimal"; inherit stateVersion; }
];
```
Then create `hosts/laptop/configuration.nix` (copy from `nixos/`), give it its own `hardware-configuration.nix`, and rebuild with `--flake .#laptop`. The `name`/`hostname` split lets the folder + attr stay clean while the network name is whatever you want, and `profile` selects between the `minimal` and `full` tiers.

### Toggle a module

Most feature modules are plain files — comment out a line in the relevant `default.nix` to disable it. For example, to drop Tailscale, remove `./vpn.nix` from `nixos/modules/networking/default.nix`.

### Add a system package

- **System-wide:** `hosts/nixos/local-packages.nix` (host-specific) or the appropriate `nixos/modules/*/` file.
- **User-only:** `home-manager/home-packages.nix`.

### Edit the desktop

Hyprland, Caelestia, Ghostty, GTK, and eza configs live as raw files under `config/.config/` and are symlinked into place — just edit them and reload (e.g. `hyprctl reload`, or restart `caelestia.service`); no rebuild needed for most changes. The Caelestia shell's QML overrides live in `home-manager/modules/caelestia-overrides/` (e.g. the ported Tailscale module). Hyprland itself is configured in **Lua**, split across `config/.config/hypr/`:

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

| Binding                  | Action                                      |
|--------------------------|---------------------------------------------|
| `SUPER + Return`         | Open terminal (Ghostty)                     |
| `SUPER + B`              | Open browser (Chrome)                       |
| `SUPER + E`              | Open file manager (Nautilus)                |
| `SUPER + Space`          | Launcher (Caelestia)                        |
| `SUPER + N`              | Notification center / sidebar (Caelestia)   |
| `SUPER + ESC`            | Power / session menu (Caelestia)            |
| `SUPER + L`              | Lock screen (Caelestia Lock via logind)     |
| `SUPER + Q`              | Close window                                |
| `SUPER + Arrows`         | Move focus                                  |
| `SUPER + [1-0]`          | Switch to workspace                         |
| `SUPER + Shift + [1-0]`  | Move window to workspace                    |
| `SUPER + S`              | Toggle scratchpad (special workspace)       |
| `SUPER + C / V`          | **Universal copy/paste**                    |

> [!TIP]
> `SUPER+C`/`SUPER+V` forward to `Ctrl+Insert`/`Shift+Insert` rather than `Ctrl+C`/`Ctrl+V` — the Insert-based combos work in **terminals** too, where `Ctrl+C` is SIGINT, not copy.

See `config/.config/hypr/bindings.lua` for the full set.

## 🐚 Shell & CLI Goodies

The Zsh setup (in `home-manager/modules/zsh.nix` + `config/.config/zsh/zshrc_addon.zsh`) packs a few custom conveniences:

- **`nrs`** — rebuild & switch the system.
- **`gcommit`** — a JIRA-aware commit helper.
- **`fo()`** — fuzzy-open files via [`py-file-opener`](https://github.com/manojmanivannan/py-file-opener), built here as a **pure Nix derivation** (no venv, no `uv` drift).
- **`btw`** — `echo i use nixos-btw`. Because of course.
- **Oh-My-Zsh** with the `amuse` theme, plus `git`, `eza`, `virtualenv`, `z`, `fzf`, and more.
- **`gh`** configured for SSH, wired as Git's GitHub credential helper.

The prompt is a custom one: `<path> <git> <venv> [exit-on-fail]` on the left, `[HH:MM:SS]` on the right.

## 🎨 Theming

A warm-metal identity runs through the shell and most of the system — brushed
gold / copper / bronze on warm espresso:

- **Caelestia shell** — a vendored static warm-metal `scheme.json` (M3 roles),
  pinned and severed from the CLI regen path so colours stay stable
  (`home-manager/modules/caelestia.nix`, `config/.config/caelestia/scheme/`).
- **Hyprland** — warm-metal active borders (literal rgba in `config/.config/hypr/looknfeel.lua`).
- **GTK** — `adw-gtk3-dark` (GTK3) + libadwaita dark (GTK4), recolored warm-metal
  by `config/.config/gtk-3.0/gtk.css` and `config/.config/gtk-4.0/gtk.css`.
- **Ghostty** — warm-metal 16-color palette + `background = #322a21`
  (`config/.config/ghostty/config`).
- **Console** — the warm-metal 16-color palette applied to the Linux console.
- **Cursors / icons / Plymouth** — still Catppuccin-Macchiato-teal
  (`Catppuccin-Macchiato-Teal` xcursor/hyprcursor, Colloid-teal icons,
  `catppuccin-macchiato` Plymouth) until warm variants are adopted.
- **eza** — theme YAML for colored, iconified `ls`.

Theme variables are declared in `nixos/modules/desktop/theme.nix`; the Caelestia
scheme and tokens are documented in `config/.config/caelestia/README.md`.

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