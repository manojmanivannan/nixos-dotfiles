# Vendored caelestia runtime config (WF-10 → WF-12)

Caelestia reads its user-editable runtime config from `~/.config/caelestia/`.
This directory vendors the pieces Home Manager does NOT generate, symlinked
into place by `home-manager/modules/dotfiles-symlinks.nix` (single-file
entries, so they never collide with the HM-generated `shell.json`).

| File / dir | WF | Owner | Notes |
|---|---|---|---|
| `shell.json` | WF-10/WF-12 | HM-generated from `programs.caelestia.settings` | Not vendored here — `home-manager/modules/caelestia.nix` writes it. WF-12 adds the theming payload (`smartScheme`, `transparency`, `background`, `launcher.actions`). |
| `shell-tokens.json` | WF-10/WF-12 | symlinked | The fancy-lever file (rounding/spacing/padding tiers, font sizes, animation durations, named bezier curves, per-component `sizes.*`). **Intentionally `{}`** for WF-12 — the warm-metal identity comes from the scheme, and the motion levers ship caelestia's curated defaults (the destination's "fancy from quickshell, not a new palette"). Set explicit values here only to diverge from those defaults. |
| `hypr-user.conf` | WF-10 | symlinked | Shell-specific Hyprland tweaks on top of `config/.config/hypr/`. Empty — the live session needed none. |
| `scheme/` | WF-12 | symlinked? **No** | The scheme source lives at `scheme/scheme.json` but the shell reads it from **state** (`~/.local/state/caelestia/scheme.json`), delivered by an activation script in `caelestia.nix`, not from here. See `scheme/README.md`. |

## WF-12 — what's pinned and why

WF-12 pins the warm-metal palette and severs the CLI regeneration path so
colours stay stable. Three layers:

1. **Scheme** — `scheme/scheme.json` (vendored, delivered to state). The
   warm-metal → M3 role mapping from the build spec. The shell reads only
   the `m3*` + `term*` keys; the catppuccin-style names are kept for the
   CLI's Hyprland/GTK/terminal templates (the same vocabulary the existing
   waybar `style.css` uses). See `scheme/README.md`.

2. **Hygiene + fancy levers** — `shell.json` (HM-generated): `services.smartScheme = false`,
   `appearance.transparency.enabled = true` (toggles the `caelestia-drawers`
   blur layer rule at runtime; the static `^caelestia-` blur rule is in
   `config/.config/hypr/looknfeel.lua`), `background.enabled = false` (swaybg
   owns the wallpaper; avoids a double render + severs the background
   wallpaper-picker regen trigger), `launcher.actions` curated to drop every
   scheme-regenerating action.

3. **Severing CLI regen** — the Nexus "Wallpaper & style" page is removed
   from the page registries (a `postPatch` on the caelestia package in
   `caelestia.nix`) AND the `>scheme` / `>variant` / `>wallpaper` / `Random`
   / `Light` / `Dark` launcher actions are dropped. With `path.txt`
   pre-populated, `Wallpapers.qml`'s empty-path fallback never fires either.
   No UI trigger is left that invokes `caelestia wallpaper` / `scheme set`.

The blur `layerrule` on `caelestia-drawers` is "configured" two ways: the
static `^caelestia-` blur rule in `looknfeel.lua` (WF-11) covers the
persistent surfaces, and `appearance.transparency.enabled = true` makes
`Colours.qml:reloadHyprRules` append the dynamic `caelestia-drawers` rule
the spec calls out.