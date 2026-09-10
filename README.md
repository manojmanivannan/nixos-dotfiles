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
- **Aggregated module layout** — `nixos/modules` is grouped into 10 domain subdirectories instead of 50 loose files.
- **Host-identity decoupling** — clone, change one line, rebuild. No folder renaming.
- **Hardened by default** — `sudo-rs`, TPM2, Yubikey PAM/u2f, AppArmor + the full LSM stack, kernel hardening.

## 📑 Table of Contents

- [The Stack](#-the-stack)
- [Repository Structure](#-repository-structure)
- [How It's Wired](#-how-its-wired)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Checklist: Hardcoded Values & Machine Settings](#-checklist-hardcoded-values--machine-settings)
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
- **`home-manager/modules/dotfiles-symlinks.nix`** symlinks the raw `config/.config/*` files/directories into `~/.config` with `mkOutOfStoreSymlink`, so edits to Hyprland/Caelestia/etc. take effect without a rebuild. Caelestia itself is launched as a systemd `caelestia.service` (wired in `home-manager/modules/caelestia.nix`), not a Hyprland `exec-once`.

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
user = "your-username";            # flows to user account, docker group, Home Manager, env vars
weatherLocation = "51.338,-0.748"; # lat,long or "City, Country" for Caelestia weather widget
hosts = [
  {
    name = "nixos";
    hostname = "your-hostname";
    ipv4Address = "192.168.1.192"; # set to your static IP (or see checklist for DHCP)
    defaultGateway = "192.168.1.1";
    inherit stateVersion;
  }
];
```

`name` is the stable identity (the flake attr `.nixos` and the `hosts/<name>/` folder) — leave it as `nixos`. `hostname` is the machine's network name, and `user` is your login name.

### 4. Drop in your generated hardware config

The installer already generated one for your disks — copy it into the repo, overwriting the machine-specific copy that ships here:

```sh
cp /etc/nixos/hardware-configuration.nix ~/nixos-dotfiles/hosts/nixos/
```

### 5. Rebuild and switch

> [!WARNING]
> **Check before rebuilding!** This repository contains several hardware- and personal-specific defaults — most notably a **hardcoded network interface (`eno1`) with DHCP disabled** in `nixos/modules/networking/networking.nix`, **strictly key-based SSH** with the author's public keys in `nixos/modules/users/users.nix`, and **Lenovo battery charging thresholds**.
>
> Please review the **[Checklist: Hardcoded Values & Machine Settings](#-checklist-hardcoded-values--machine-settings)** below before running `nixos-rebuild switch` so you do not lose network connectivity or lock yourself out.

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

## ⚙️ Checklist: Hardcoded Values & Machine Settings

This repository was created for a specific personal workstation (an AMD laptop with an NVIDIA RTX GPU, static IP on an Intel I226-V Ethernet interface, Lenovo battery management, and private homelab services). If you are cloning or adapting this setup, review and update the following settings:

### Quick Reference

| Category | File | Hardcoded Item / Setting | Default in Repo | What to Change / Why |
|:---|:---|:---|:---|:---|
| **Network Interface** | [`nixos/modules/networking/networking.nix`](nixos/modules/networking/networking.nix) | `networking.interfaces.eno1` | `eno1` | Change to your NIC name (e.g. `eth0`, `enp3s0`), or remove for DHCP. |
| **DHCP / IP Mode** | [`nixos/modules/networking/networking.nix`](nixos/modules/networking/networking.nix) | `networking.useDHCP = false;` | `false` | Set to `true` (or enable NetworkManager) if you do not use a static IP. |
| **Wake-on-LAN** | [`nixos/modules/networking/networking.nix`](nixos/modules/networking/networking.nix) | `systemd.services.eno1-wol`, `powerManagement` | `eno1` (Intel I226-V) | Change `eno1` or comment out if not using Wake-on-LAN. |
| **Static IP & Gateway** | [`flake.nix`](flake.nix) | `ipv4Address`, `defaultGateway` | `192.168.1.192`, `192.168.1.1` | Set to your local subnet IP/gateway, or omit if using DHCP. |
| **DNS Servers** | [`nixos/modules/networking/dns.nix`](nixos/modules/networking/dns.nix) | `networking.nameservers` | `[ "192.168.1.1" "8.8.8.8" ]` | Change `192.168.1.1` to your router/local DNS or upstream provider. |
| **SSH Authorized Keys** | [`nixos/modules/users/users.nix`](nixos/modules/users/users.nix) | `openssh.authorizedKeys.keys` | Author's SSH public keys | **Critical**: Replace with your own `~/.ssh/id_ed25519.pub`. |
| **SSH Password Auth** | [`nixos/modules/services/openssh.nix`](nixos/modules/services/openssh.nix) | `PasswordAuthentication = false;` | `false` (key-only) | Enforces SSH key logins only; will lock you out if keys are not updated. |
| **User Account** | [`flake.nix`](flake.nix) | `user = "manoj";` | `"manoj"` | Set your username; cascades to user account, HM, and permissions. |
| **User Avatar** | [`home-manager/modules/caelestia.nix`](home-manager/modules/caelestia.nix) | `home.file.".face".source` | `./caelestia-overrides/profile_picture.jpg` | Replace image or link to your own profile picture. |
| **Git Identity** | [`home-manager/modules/git.nix`](home-manager/modules/git.nix) | `user.name`, `user.email` | `Manoj Manivannan`, `manojm18@live.in` | Set your Git committer name and email. |
| **Weather Location** | [`flake.nix`](flake.nix) | `weatherLocation` | `"51.338,-0.748"` (Fleet, UK) | Change to your coordinates or `"City, Country"` for Caelestia weather. |
| **Hardware Config** | [`hosts/nixos/hardware-configuration.nix`](hosts/nixos/hardware-configuration.nix) | Disks, UUIDs, CPU microcode | NVMe UUIDs, AMD CPU microcode | Overwrite with your generated `/etc/nixos/hardware-configuration.nix`. |
| **GPU Drivers** | [`nixos/modules/hardware/nvidia.nix`](nixos/modules/hardware/nvidia.nix) | `videoDrivers = ["nvidia"]` | NVIDIA proprietary | Adjust or disable if using AMD or Intel graphics. |
| **GPU Loader Libs** | [`nixos/modules/development/programming-languages.nix`](nixos/modules/development/programming-languages.nix) | `programs.nix-ld.libraries` | `nvidia_x11` | Remove `nvidia_x11` if not using NVIDIA. |
| **Battery Threshold** | [`nixos/modules/services/power.nix`](nixos/modules/services/power.nix) | `STOP_CHARGE_THRESH_BAT0 = 1;` | `1` (Lenovo mode) | Caps battery charging (~60–80%) on Lenovo. Remove or change for 100% charge. |
| **Kernel Parameters** | [`nixos/modules/boot/linux-kernel.nix`](nixos/modules/boot/linux-kernel.nix) | `boot.kernelParams` | `acpi_rev_override=5`, etc. | Laptop ACPI quirk workarounds; adjust or remove if unneeded. |
| **Timezone & RTC** | [`nixos/modules/i18n/time.nix`](nixos/modules/i18n/time.nix) | `timeZone`, `hardwareClockInLocalTime` | `"Europe/London"`, `true` | Change timezone. Set `hardwareClockInLocalTime = false` if not dual-booting Windows. |
| **Display Scaling** | [`config/.config/hypr/monitors.lua`](config/.config/hypr/monitors.lua) | `hl.env("GDK_SCALE", 1.9)` | `1.9` | Fractional scale factor for 4K. Change to `1` (1080p/1440p) or `2` (HiDPI). |
| **Tailscale Profiles** | [`config/.config/caelestia/scripts/tailscale.sh`](config/.config/caelestia/scripts/tailscale.sh) | `PROFILES=( ... )` | Author's Gmail accounts | Change to your Tailscale login emails for the right-click profile switcher. |
| **Homelab SSH Host** | [`home-manager/modules/ssh.nix`](home-manager/modules/ssh.nix) | `settings.homelab` | `192.168.1.120` | Remote homelab server alias; edit or delete. |
| **Claude Local URL** | [`config/.claude/settings.json`](config/.claude/settings.json) | `ANTHROPIC_BASE_URL` | `http://192.168.1.120:11434` | Local LLM proxy endpoint; edit or delete. |
| **NAS Rsync Backup** | [`config/.config/rsync/archive_to_nas.sh`](config/.config/rsync/archive_to_nas.sh) | `rsync://manoj@dxp2800-nas-mm.local:...` | Private NAS host | Backs up `~/Apps` to private NAS. Edit or disable timer in `nas-backup.nix`. |
| **NAS Timer Schedule**| [`home-manager/modules/nas-backup.nix`](home-manager/modules/nas-backup.nix) | `OnCalendar = "Sat *-*-* 03:00:00"` | Every Saturday 3 AM | Systemd timer for the NAS backup. |
| **GitHub CLI Defaults**| [`config/.config/gh/config.yml`](config/.config/gh/config.yml) | `browser: brave`, `editor: hx` | `brave`, `hx` | Default web browser and editor for `gh`. |
| **Zsh Work Aliases** | [`config/.config/zsh/zshrc.d/20-git.zsh`](config/.config/zsh/zshrc.d/20-git.zsh) | `gcommit`, `gcbi` JIRA prefixes | `IN-`, `NLA-`, `AP-` | Custom JIRA project key matching for Git branch/commit scripts. |
| **Experiments Dir** | [`home-manager/modules/try.nix`](home-manager/modules/try.nix) | `path = "~/Experiments"` | `~/Experiments` | Directory where `try` generates scratch experiment projects. |

---

### Detailed Breakdown & How to Modify

#### 1. Networking (`eno1` vs DHCP)
In [`nixos/modules/networking/networking.nix`](nixos/modules/networking/networking.nix):
- **Interface name**: `networking.interfaces.eno1` is tied to the author's physical Ethernet card. If your machine's interface is named differently (run `ip link` to find yours, e.g. `enp3s0`, `eth0`, `wlan0`), rename all occurrences of `eno1` in `networking.nix`.
- **Using DHCP**: If your network uses DHCP rather than a static IP address:
  ```nix
  networking.useDHCP = true;
  # Or uncomment:
  # networking.networkmanager.enable = true;
  ```
  Then comment out or remove the static `networking.interfaces.eno1` configuration block and `systemd.services.eno1-wol`.
- **WOL service & power hooks**: The `eno1-wol` systemd service and power management commands force Wake-on-LAN persistence for Intel I226-V chips using `ethtool`. If you don't need Wake-on-LAN, remove or comment out `systemd.services.eno1-wol` and the `powerManagement` block.
- **DNS**: [`nixos/modules/networking/dns.nix`](nixos/modules/networking/dns.nix) hardcodes `192.168.1.1` as a primary nameserver. Change this to your local router address or public resolvers (`1.1.1.1`, `8.8.8.8`).

#### 2. SSH Access & Authentication
- **Authorized keys**: In [`nixos/modules/users/users.nix`](nixos/modules/users/users.nix), replace the strings in `openssh.authorizedKeys.keys` with the contents of your own `~/.ssh/id_ed25519.pub`.
- **Key-only enforcement**: [`nixos/modules/services/openssh.nix`](nixos/modules/services/openssh.nix) sets `PasswordAuthentication = false`. If you attempt to connect over SSH without configuring your public key in `users.nix`, SSH connections will be rejected.
- **Yubikey / PAM U2F**: [`nixos/modules/security/yubikey.nix`](nixos/modules/security/yubikey.nix) enables `security.pam.u2f` with `control = "sufficient"`. It will not block password login if a Yubikey is missing, but if you do not use U2F hardware keys, you can disable this module in [`nixos/modules/security/default.nix`](nixos/modules/security/default.nix).

#### 3. Hardware, Power & Graphics
- **Disks & CPU**: Replace [`hosts/nixos/hardware-configuration.nix`](hosts/nixos/hardware-configuration.nix) with the file generated on your machine by `nixos-generate-config` (or from `/etc/nixos/hardware-configuration.nix`). Ensure CPU microcode matches your processor (`hardware.cpu.amd.updateMicrocode` vs `intel`) and virtualization kernel module (`kvm-amd` vs `kvm-intel`).
- **NVIDIA GPU**: [`nixos/modules/hardware/nvidia.nix`](nixos/modules/hardware/nvidia.nix) loads proprietary NVIDIA drivers. For Intel or AMD graphics, remove or comment out `./nvidia.nix` from [`nixos/modules/hardware/default.nix`](nixos/modules/hardware/default.nix), and remove `config.boot.kernelPackages.nvidia_x11` from `programs.nix-ld.libraries` in [`nixos/modules/development/programming-languages.nix`](nixos/modules/development/programming-languages.nix).
- **Battery conservation**: In [`nixos/modules/services/power.nix`](nixos/modules/services/power.nix), `STOP_CHARGE_THRESH_BAT0 = 1;` activates Lenovo battery conservation mode (holding charge at ~60–80%). On other brands, this will have no effect or fail; if you want 100% full charge, comment this line out.
- **Kernel parameters**: In [`nixos/modules/boot/linux-kernel.nix`](nixos/modules/boot/linux-kernel.nix), `acpi_rev_override=5` is an ACPI override specifically for the author's laptop. Remove it if your hardware does not need it.

#### 4. User Profile, Avatar & Theming
- **Avatar (`~/.face`)**: In [`home-manager/modules/caelestia.nix`](home-manager/modules/caelestia.nix), `home.file.".face".source = ./caelestia-overrides/profile_picture.jpg;` links the author's avatar picture for the Caelestia lock screen and user dashboard. Replace `home-manager/modules/caelestia-overrides/profile_picture.jpg` with your own photo or point the attribute elsewhere.
- **Weather coordinates**: In [`flake.nix`](flake.nix), update `weatherLocation = "51.338,-0.748";` to your latitude/longitude or city string (e.g. `"New York, USA"`).
- **Display scaling**: In [`config/.config/hypr/monitors.lua`](config/.config/hypr/monitors.lua), `hl.env("GDK_SCALE", 1.9)` sets fractional scaling for 4K displays. Set to `1` for 1080p/1440p displays or adjust as preferred.
- **Timezone**: In [`nixos/modules/i18n/time.nix`](nixos/modules/i18n/time.nix), update `time.timeZone = "Europe/London";`. If you do not dual-boot Windows, set `time.hardwareClockInLocalTime = false;`.

#### 5. Personal Services & Scripts
- **Tailscale switcher**: [`config/.config/caelestia/scripts/tailscale.sh`](config/.config/caelestia/scripts/tailscale.sh) contains `PROFILES` with author's Gmail accounts. Replace them with your Tailscale login emails to use the right-click profile toggling feature in the Caelestia bar.
- **NAS backup**: [`home-manager/modules/nas-backup.nix`](home-manager/modules/nas-backup.nix) and [`config/.config/rsync/archive_to_nas.sh`](config/.config/rsync/archive_to_nas.sh) configure a scheduled weekly rsync of `~/Apps` to a private NAS (`rsync://manoj@dxp2800-nas-mm.local:/home/Backup/linux-backup`). If you don't need this, remove `./nas-backup.nix` from `home-manager/modules/default.nix`.
- **Homelab SSH & Claude**: [`home-manager/modules/ssh.nix`](home-manager/modules/ssh.nix) defines a `homelab` host at `192.168.1.120`, and [`config/.claude/settings.json`](config/.claude/settings.json) sets `ANTHROPIC_BASE_URL` to `http://192.168.1.120:11434`. Update or remove if you don't run a local LLM server at that address.
- **Default editor & browser in GH CLI**: In [`config/.config/gh/config.yml`](config/.config/gh/config.yml), `editor: hx` and `browser: brave` are set.
- **Work Git helpers**: [`config/.config/zsh/zshrc.d/20-git.zsh`](config/.config/zsh/zshrc.d/20-git.zsh) contains `gcommit` and `gcbi` functions tailored to Jira issue key prefixes (`IN-`, `NLA-`, `AP-`). Edit these functions for your own team's issue ticketing conventions.

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