---@diagnostic disable: undefined-global

-- Colours generated from the wallpaper by matugen (see `rice-wall`)
local ok, colors = pcall(dofile, os.getenv("HOME") .. "/.local/state/rice/hypr-colors.lua")
if not ok then
    colors = { active = "0xffb5c4ff", inactive = "0xff45464f", shadow = "0x55000000" }
end

--------------------------------------------------
-- MONITORS
--------------------------------------------------

hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@144",
    position = "0x0",
    scale    = "1",
})

hl.monitor({
    output   = "",
    mode     = "preffered",
    position = "auto",
    -- position = "1920x0",
    scale    = "1",
    mirror   = "eDP-1",
})

--------------------------------------------------
-- VARIABLES
--------------------------------------------------

local mainMod = "SUPER"
local terminal = "kitty"
local fileManager = "kitty --class yazi -e yazi"   -- Yazi, floating (see window rule below)
local shell = "qs ipc call rice "   -- talk to the Quickshell rice
local discord = "vesktop"

--------------------------------------------------
-- AUTOSTART
--------------------------------------------------

hl.on("hyprland.start", function ()
    hl.exec_cmd("qs -n -d")          -- bar, launcher, notifications, dashboard, lock
    hl.exec_cmd("hypridle")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-clip-persist --clipboard regular --all-mime-type-regex '^(?!x-kde-passwordManagerHint).+'")
end)

--------------------------------------------------
-- ENV
--------------------------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("WLR_DRM_NO_ATOMIC", "1")
hl.env("CLIPHIST_MAX_ITEM", "100")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")   -- Qt apps: wallpaper colours + Papirus (qt6ct)

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,       -- matches the bar islands' margin

        border_size = 2,

        col = {
            active_border   = colors.active,
            inactive_border = colors.inactive,
        },

        resize_on_border = false,
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding = 16,
        rounding_power = 2,

        active_opacity = 0.9,
        inactive_opacity = 0.9,

        shadow = {
            enabled = true,
            range = 18,
            render_power = 3,
            color = colors.shadow,
        },

        blur = {
            enabled = true,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        allow_session_lock_restore = true,   -- lets the lock screen be restarted if it ever crashes
    },

    input = {
        numlock_by_default = true,
        follow_mouse = 1,
        sensitivity = 0.3,

        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
        },
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })

-- File manager window: floating and centred
hl.window_rule({
    name   = "yazi-float",
    match  = { class = "^yazi$" },
    float  = true,
    size   = "1200 760",
    center = true,
})

-- System update terminal: floating and centred
hl.window_rule({
    name   = "update-float",
    match  = { class = "^rice-update$" },
    float  = true,
    size   = "1000 640",
    center = true,
})

-- hl.workspace_rule({ workspace = "1", monitor = "eDP-1" })
-- hl.workspace_rule({ workspace = "9", monitor = "HDMI-A-1", default = true, persistent = true })

---------------
---- INPUT ----
---------------

hl.config({
    input = {
        numlock_by_default = true,
        follow_mouse = 1,

        sensitivity = 0.3, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
        },
    },
})

hl.gesture({ fingers = 3,
    direction = "horizontal",
    action = "workspace"
})



---------------------
---- KEYBINDINGS ----
---------------------

hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({"fullscreen", toggle}))
hl.bind(mainMod .. " + F", hl.dsp.window.float({toggle}))
hl.bind(mainMod .. " + Z",hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit"))

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(fileManager .. " ~/.local/share/Trash/files"))   -- Trash
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(shell .. "launcher apps"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("xdg-open \"https://\""))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(shell .. "launcher wallpapers"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(shell .. "toggle dashboard"))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd(discord))
hl.bind(mainMod .. " + code:51", hl.dsp.exec_cmd("kitty --class floating -e btop")) -- KEY: Back slash
hl.bind(mainMod .. " + code:34", hl.dsp.exec_cmd("keepassxc -platform xcb"))    -- KEY: Opening square bracket
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("/home/ibexe/godot/Godot_v4.4.1-stable_linux.x86_64"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("wayscriber --active"))
hl.bind(mainMod .. " + code:49", hl.dsp.exec_cmd(shell .. "toggle notifications"))   --KEY: `
hl.bind(mainMod .. " + SHIFT + code:49", hl.dsp.exec_cmd(shell .. "dnd"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(shell .. "lock"))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd(shell .. "toggle session"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(shell .. "launcher clipboard"))   -- Shift+Del inside removes an entry
hl.bind("PRINT", hl.dsp.exec_cmd("flameshot gui"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("~/.local/bin/tgbot"))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.move({ direction = "down" }))


for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- The shell shows a slider popup for these
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(shell .. "volume up"),       { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(shell .. "volume down"),     { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd(shell .. "volume mute"),     { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd(shell .. "volume mic"),      { locked = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd(shell .. "brightness up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd(shell .. "brightness down"), { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

