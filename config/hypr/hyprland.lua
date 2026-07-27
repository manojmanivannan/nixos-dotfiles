-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    -- swaync notification daemon (config + style in ~/.config/swaync).
    -- Toggle the control center with Super+N (see binds below).
    hl.exec_cmd("swaync")
    -- swaybg sets the wallpaper (-m fill scales to cover the screen, cropping if needed).
    hl.exec_cmd("swaybg -i /home/manoj/nixos-dotfiles/wallpaper/samurai-sunset.jpg -m fill")
end)
