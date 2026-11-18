-- Hyprland config for this Quickshell session.
-- Same Lua API Omarchy uses (hl.config, hl.bind, hl.window_rule, hl.layer_rule),
-- without Omarchy's menus, shell, or helper scripts.
--
-- Hyprland only reads ~/.config/hypr/hyprland.lua. Point it here with:
--   ln -sfn ~/.config/quickshell/hyprland/hyprland.lua ~/.config/hypr/hyprland.lua
-- Then start a session with `uwsm start hyprland-uwsm.desktop` (or `Hyprland`).
-- After edits: `hyprctl reload` and `hyprctl configerrors`.
--
-- https://wiki.hypr.land/configuring/

local home = os.getenv("HOME") or ""
local shots = home .. "/Pictures/Screenshots"

local function bind(keys, description, dispatcher, options)
    local opts = options or {}
    if description then
        opts.description = description
    end
    hl.bind(keys, dispatcher, opts)
end

local function cmd(command)
    return hl.dsp.exec_cmd(command)
end

-- Same wrapper niri used, so launched apps join the systemd session.
local function launch(command)
    return cmd("uwsm-app -- " .. command)
end

-----------------
---- MONITOR ----
-----------------

-- Fallback for any output, then the laptop panel from the niri config.
-- eDP-1 sits to the right of a 1280-wide display.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
hl.monitor({ output = "eDP-1", mode = "1920x1080", position = "1280x0", scale = 1 })

--------------
---- ENV -----
--------------

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

hl.env("GDK_BACKEND", "wayland,x11")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("MOZ_DBUS_REMOTE", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

hl.env("GTK_THEME", "Adwaita:dark")
hl.env("GTK_APPLICATION_PREFER_DARK_THEME", "1")

hl.env("XCURSOR_THEME", "Qogir-cursors")
hl.env("XCURSOR_SIZE", "28")
hl.env("HYPRCURSOR_THEME", "Qogir-cursors")
hl.env("HYPRCURSOR_SIZE", "28")

hl.env("EDITOR", "nvim")
hl.env("TERMINAL", "alacritty")
hl.env("BROWSER", "firefox")

-- From the niri environment block. Harmless when the display is not NVIDIA.
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },
})

-----------------
---- AUTOSTART --
-----------------

-- Quickshell draws the bar, wallpaper, launcher, notifications, and idle.
-- hypridle and mako stay off; those jobs already live in the shell.
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("uwsm-app -- quickshell")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("uwsm-app -- cliphist store")
    hl.exec_cmd("uwsm-app -- udiskie")
end)

----------------------
---- LOOK AND FEEL ---
----------------------

-- Flat borders in the shell palette. Gaps match the niri layout.
-- Animations are the ones shipped with Hyprland 0.57.
local active_border = "rgba(7B8394ff)"
local inactive_border = "rgba(45475aff)"

hl.config({
    general = {
        gaps_in = 8,
        gaps_out = 8,
        border_size = 2,
        col = {
            active_border = active_border,
            inactive_border = inactive_border,
        },
        resize_on_border = true,
        extend_border_grab_area = 8,
        hover_icon_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 0,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = { enabled = false },
        blur = { enabled = false },
    },

    group = {
        col = {
            border_active = active_border,
            border_inactive = inactive_border,
        },
    },

    animations = { enabled = true },

    dwindle = {
        preserve_split = true,
        force_split = 2,
    },

    master = {
        new_status = "master",
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        background_color = "rgb(1e2030)",
        disable_scale_notification = true,
        focus_on_activate = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        bell_sound = "none",
    },

    cursor = {
        hide_on_key_press = true,
        inactive_timeout = 2.5,
        warp_on_change_workspace = 2,
    },

    binds = {
        hide_special_on_workspace_change = true,
    },

    layers = {
        allow_new_top_layers_over_existing_fullscreen = true,
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("easy", { type = "spring", mass = 1, stiffness = 238.1191, damping = 24.21279333 })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, spring = "easy", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })

---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        accel_profile = "flat",
        sensitivity = 0.1,
        repeat_rate = 40,
        repeat_delay = 200,
        scroll_factor = 1.4,

        touchpad = {
            natural_scroll = true,
            ["tap-to-click"] = true,
            scroll_factor = 1,
        },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

----------------
---- LAYERS ----
----------------

-- The shell animates its own panels. A compositor fade on top of that
-- would play a second animation. Wallpaper stays put on the background layer.
hl.layer_rule({
    name = "shell-no-anim",
    match = {
        namespace = "^(quickshell|wallpaper|launcher|clipboard|notifications|(brightness|desktop|system|network|volume|monitor|bluetooth|clock)-panel(-dismiss)?)$",
    },
    no_anim = true,
})

hl.layer_rule({
    name = "notifications-private",
    match = { namespace = "^notifications$" },
    no_screen_share = true,
})

----------------------
---- WINDOW RULES ----
----------------------

hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

hl.window_rule({
    name = "pip",
    match = { title = "^(Picture-in-Picture|Picture in picture)$" },
    float = true,
    pin = true,
    no_initial_focus = true,
    keep_aspect_ratio = true,
    size = { 420, 236 },
    move = { "monitor_w-window_w-20", "monitor_h-window_h-20" },
})

hl.window_rule({
    name = "kdeconnect-float",
    match = { class = "^org\\.kde\\.kdeconnect\\.daemon$" },
    float = true,
    no_initial_focus = true,
})

hl.window_rule({
    name = "float-dialogs",
    match = {
        class = "^(Pinentry-gtk|Tk|mpv|xarchiver|wev|com\\.gabm\\.satty)$",
    },
    float = true,
})

hl.window_rule({
    name = "float-tui",
    match = {
        class = "^(bluetui|pulsemixer|nmtui|dashboard|ncdu|battery|sensors|wlctl)$",
    },
    float = true,
    size = { 960, 600 },
    move = { "monitor_w-window_w-20", "monitor_h-window_h-20" },
})

hl.window_rule({
    name = "float-titled-dialogs",
    match = { title = "^(save to|Library|File Upload|Waynotes|Rename|Text Import|Preferences)$" },
    float = true,
    center = true,
})

hl.window_rule({
    name = "satty-min",
    match = { class = "^com\\.gabm\\.satty$" },
    min_size = { 730, 300 },
})

hl.window_rule({
    name = "private-windows",
    match = { class = "^(org\\.keepassxc\\.KeePassXC|org\\.gnome\\.World\\.Secrets)$" },
    no_screen_share = true,
})

-------------------
---- KEYBINDS -----
-------------------

-- Apps. These match the niri binds.
bind("SUPER + Return", "Terminal", launch("alacritty"))
bind("SUPER + SHIFT + Return", "Kitty", launch("kitty"))
bind("SUPER + B", "Browser", launch("firefox"))
bind("SUPER + SHIFT + B", "Browser private", launch("firefox --private-window"))
bind("SUPER + E", "Files", launch("alacritty -e yazi"))
bind("SUPER + Space", "Launcher", cmd("qs ipc call launcher toggle"))
bind("SUPER + Backspace", "Power menu", cmd("uwsm-app power-menu"))
bind("SUPER + backslash", "System menu", cmd("uwsm-app system-menu"))
bind("SUPER + ALT + L", "Lock", cmd("qs ipc call lock lock"))

bind("SUPER + Q", "Close window", hl.dsp.window.close())
bind("SUPER + SHIFT + E", "Exit Hyprland", cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
bind("CTRL + ALT + Delete", "Exit Hyprland", cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
bind("SUPER + Escape", "Release input capture", hl.dsp.release_input_capture(), { dont_inhibit = true })

-- Focus and move. Arrows and hjkl do the same thing.
-- Dwindle has no niri columns, so left/right is the neighboring window.
local directions = {
    { key = "left", dir = "left" },
    { key = "right", dir = "right" },
    { key = "up", dir = "up" },
    { key = "down", dir = "down" },
    { key = "H", dir = "left" },
    { key = "L", dir = "right" },
    { key = "K", dir = "up" },
    { key = "J", dir = "down" },
}

for _, entry in ipairs(directions) do
    bind("SUPER + " .. entry.key, "Focus " .. entry.dir, hl.dsp.focus({ direction = entry.dir }))
    bind("SUPER + CTRL + " .. entry.key, "Move window " .. entry.dir, hl.dsp.window.move({ direction = entry.dir }))
    bind("SUPER + SHIFT + " .. entry.key, "Focus monitor " .. entry.dir, hl.dsp.focus({ monitor = entry.dir }))
    bind("SUPER + SHIFT + CTRL + " .. entry.key, "Move window to monitor " .. entry.dir, hl.dsp.window.move({ monitor = entry.dir, follow = true }))
end

-- Workspaces 1-9, plus page up/down and u/i the way niri had them.
for workspace = 1, 9 do
    bind("SUPER + " .. workspace, "Workspace " .. workspace, hl.dsp.focus({ workspace = workspace }))
    bind("SUPER + CTRL + " .. workspace, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = workspace, follow = true }))
end

bind("SUPER + Page_Down", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
bind("SUPER + Page_Up", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
bind("SUPER + U", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
bind("SUPER + I", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
bind("SUPER + CTRL + Page_Down", "Move window to next workspace", hl.dsp.window.move({ workspace = "e+1", follow = true }))
bind("SUPER + CTRL + Page_Up", "Move window to previous workspace", hl.dsp.window.move({ workspace = "e-1", follow = true }))
bind("SUPER + CTRL + U", "Move window to next workspace", hl.dsp.window.move({ workspace = "e+1", follow = true }))
bind("SUPER + CTRL + I", "Move window to previous workspace", hl.dsp.window.move({ workspace = "e-1", follow = true }))

bind("SUPER + mouse_down", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
bind("SUPER + mouse_up", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
bind("SUPER + CTRL + mouse_down", "Move window to next workspace", hl.dsp.window.move({ workspace = "e+1", follow = true }))
bind("SUPER + CTRL + mouse_up", "Move window to previous workspace", hl.dsp.window.move({ workspace = "e-1", follow = true }))

-- Layout. Super+F keeps the bar (maximized). Super+Shift+F covers the screen.
bind("SUPER + F", "Maximize", hl.dsp.window.fullscreen({ mode = "maximized" }))
bind("SUPER + SHIFT + F", "Fullscreen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
bind("SUPER + M", "Maximize to edges", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
bind("SUPER + V", "Float", hl.dsp.window.float({ action = "toggle" }))
bind("SUPER + R", "Toggle split", hl.dsp.layout("togglesplit"))
bind("SUPER + G", "Toggle group", hl.dsp.group.toggle())

bind("SUPER + minus", "Shrink width", hl.dsp.window.resize({ x = -80, y = 0, relative = true }))
bind("SUPER + equal", "Grow width", hl.dsp.window.resize({ x = 80, y = 0, relative = true }))
bind("SUPER + SHIFT + minus", "Shrink height", hl.dsp.window.resize({ x = 0, y = -80, relative = true }))
bind("SUPER + SHIFT + equal", "Grow height", hl.dsp.window.resize({ x = 0, y = 80, relative = true }))

bind("SUPER + mouse:272", "Drag window", hl.dsp.window.drag(), { mouse = true })
bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })

-- Screenshots land in the same folder niri used. Needs grim, slurp, and jq.
local function shot_file()
    return "'" .. shots .. "/Screenshot-'$(date +%Y-%m-%d_%H-%M-%S).png"
end

bind("Print", "Screenshot region", cmd("mkdir -p '" .. shots .. "' && grim -g \"$(slurp)\" " .. shot_file()))
bind("CTRL + Print", "Screenshot screen", cmd("mkdir -p '" .. shots .. "' && grim " .. shot_file()))
bind("ALT + Print", "Screenshot window", cmd(
    "mkdir -p '" .. shots .. "' && { set -- $(hyprctl activewindow -j | jq -r '.at[0], .at[1], .size[0], .size[1]'); grim -g \"$1,$2 ${3}x$4\" " .. shot_file() .. "; }"
))

-- Volume, brightness, and media. locked so they still work on the lock screen.
local media = { locked = true }
local held = { locked = true, repeating = true }

bind("XF86AudioRaiseVolume", "Volume up", cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0"), held)
bind("XF86AudioLowerVolume", "Volume down", cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"), held)
bind("XF86AudioMute", "Mute", cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), media)
bind("XF86AudioMicMute", "Mute microphone", cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), media)
bind("XF86AudioPlay", "Play/pause", cmd("playerctl play-pause"), media)
bind("XF86AudioPause", "Play/pause", cmd("playerctl play-pause"), media)
bind("XF86AudioStop", "Stop", cmd("playerctl stop"), media)
bind("XF86AudioPrev", "Previous track", cmd("playerctl previous"), media)
bind("XF86AudioNext", "Next track", cmd("playerctl next"), media)
bind("XF86MonBrightnessUp", "Brightness up", cmd("brightnessctl --class=backlight set +5%"), held)
bind("XF86MonBrightnessDown", "Brightness down", cmd("brightnessctl --class=backlight set 5%-"), held)

-- DPMS must not run inside the key handler. A short timer turns the panels off.
bind("SUPER + SHIFT + P", "Power off monitors", function()
    hl.timer(function()
        hl.dispatch(hl.dsp.dpms({ action = "disable" }))
    end, { timeout = 500, type = "oneshot" })
end)
