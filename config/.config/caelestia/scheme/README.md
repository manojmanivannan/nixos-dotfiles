# The vendored warm-metal colour scheme (WF-12).

`scheme.json` is the static warm-metal Material-3 scheme the caelestia shell
renders in — brushed gold / copper / patina on warm espresso, encoding the
warm-metal → M3 role mapping from the build spec
(`docs/wayfinder/tickets/build-spec.md`, traced to
[WF-3](../research/theming-mechanism.md)). Hexes are stored **without** a
`#` prefix; the shell re-adds it on load (`services/Colours.qml:77`).

## Delivery path — state, not config

The shell reads **`~/.local/state/caelestia/scheme.json`** — `${Paths.state}/scheme.json`
(`services/Colours.qml:117`), NOT `~/.config/caelestia/scheme/`. This repo
holds the source here; `home-manager/modules/caelestia.nix` symlinks it into
place at activation:

```
~/.local/state/caelestia/scheme.json -> <repo>/config/.config/caelestia/scheme/scheme.json
```

This corrects the WF-10 placeholder (which symlinked `scheme/` into
`~/.config/caelestia/scheme/` — a path the shell never reads; the research
marked that location as unconfirmed, and `Colours.qml` resolves it to
state). The repo path `config/.config/caelestia/scheme/` is just where the
source lives; the `.config` segment is vestigial from WF-10 and does not
reflect the runtime location.

## Stability — the CLI regen path is severed

`scheme.json` is the **sole** colour source. Nothing in the running shell
can overwrite it:

- `services.smartScheme = false` in `shell.json` (hygiene — stops the shell
  passing smart-mode/variant guesses to the CLI; per WF-3 this does NOT by
  itself freeze the palette, which is why the bypass below is also needed).
- `~/.local/state/caelestia/wallpaper/path.txt` is pre-populated (also via
  the activation script) so `Wallpapers.qml`'s empty/missing-path fallback
  never fires `caelestia wallpaper -f` (which would regenerate).
- The Nexus "Wallpaper & style" page is removed from the page registry and
  the `>scheme` / `>variant` / `>wallpaper` / `Random` / `Light` / `Dark`
  launcher actions are dropped from `shell.json` — no UI trigger left.

## The role mapping (gist)

| M3 / scheme role | warm-metal source | hex |
|---|---|---|
| background / surface | base | `322a21` |
| onSurface | text | `f0e6d2` |
| primary | gold | `e8c272` |
| secondary | copper | `d99069` |
| tertiary | patina | `84baa7` |
| error | terracotta | `e5805f` |
| errorContainer | rust | `c96b4a` |
| success | olive | `b3bf80` |
| outline | overlay0 | `937c63` |

Full table (surface tiers, fixed roles, terminal `term0`–`term15`, and the
catppuccin-style names kept for Hyprland/GTK/terminal templates) is in the
research: `docs/wayfinder/research/theming-mechanism.md` §3. The shell QML
reads only the `m3*` + `term*` keys; the `base`/`mantle`/`overlay*`/`text`/
`subtext*` names are skipped by `Colours.qml` but kept here so the CLI's
`apply_colours` templates (should the CLI ever run) stay on the same
warm-metal vocabulary the existing waybar `style.css` and Hyprland config
already use.

### `overlay1` / `overlay2` / `subtext0`

These use the `mix()` approximations from the research (§3) rather than a
real `caelestia wallpaper -p` run. Running the CLI to capture exact values is
exactly the regeneration path this slice severs, and `materialyoucolor`'s 9
variants would not emit the exact warm-metal hexes anyway (WF-3, path (a)
rejected). The approximations are close enough for the catppuccin-style
template names the shell itself does not read.