-- Minimal Hyprland session that only runs the login screen (greetd starts this as the
-- "greeter" user via start-hyprland). When you log in, the greeter quits, this exits, and greetd starts
-- your real session (start-hyprland).
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "1" })

hl.env("XCURSOR_SIZE", "24")

hl.config({
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        background_color = 0xff111318,
    },
    input = {
        numlock_by_default = true,
        touchpad = { natural_scroll = true },
    },
    decoration = { blur = { enabled = false }, shadow = { enabled = false } },
    animations = { enabled = true },
})

hl.on("hyprland.start", function()
    hl.exec_cmd("qs -p /etc/greetd/rice-greeter; hyprctl dispatch 'hl.dsp.exit()'")
end)
