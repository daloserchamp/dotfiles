-- this is my hyprland config. The keybinds are set to the dvorak layout, so you may need to translate it to qwerty.
-- This highly functional config functions very similar to dwm with but with some good looks.

local colors = require("HyprlandColors")

package.path = package.path .. ";./?.lua;./?/init.lua"
local smw = require("plugins.split-monitor-workspaces")

smw.setup({
	workspace_count = 9,
})
------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
	output = "DP-1",
	mode = "1920x1080@100",
	position = "1920x0",
	scale = "auto",
})

hl.monitor({
	output = "DP-3",
	mode = "1920x1080@100",
	position = "0x0",
	scale = "auto",
})

-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function()
	hl.exec_cmd("swaybg -i .config/hypr/Wallpapers/ColoradoMountains.jpg")
	hl.exec_cmd("waybar")
	--hl.exec_cmd("nm-applet")
	--hl.exec_cmd("waybar & hyprpaper & firefox")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
	general = {
		gaps_in = 1,
		gaps_out = 0,

		border_size = 2,

		col = {
			active_border = { colors = { colors.color4, colors.color5 }, angle = 45 },
			inactive_border = colors.color3,
		},
		layout = "master",
		snap = {
			enabled = true,
			window_gap = 10,
			monitor_gap = 20,
			respect_gaps = true,
		},
	},

	decoration = {
		rounding = 0,
		rounding_power = 2,

		-- Change transparency of focused and unfocused windows
		active_opacity = 1.0,
		inactive_opacity = 0.9,
		fullscreen_opacity = 1,
		dim_inactive = false,

		--screenshader = "pathtoshader",

		shadow = {
			enabled = false,
			range = 4,
			render_power = 3,
			color = 0xee1a1a1a,
		},

		blur = {
			enabled = true,
			size = 10,
			passes = 3,
			vibrancy = 1,
			noise = 0.08,
			contrast = 1.5,

			new_optimizations = true,
			ignore_opacity = true,
		},

		glow = {
			enabled = false,
			range = 10,
			render_power = 3,
		},

		motion_blur = {},
	},

	animations = {
		enabled = true,
		workspace_wraparound = true,
	},
	input = {
		repeat_rate = 25,
		repeat_delay = 200,
	},
	misc = {
		--font_family = ""
	},
	cursor = {
		persistent_warps = true,
		enable_hyprcursor = false,
		hide_on_tablet = true,
		use_cpu_buffer = 0,
		--zoom_rigid = true,
		zoom_disable_aa = true,
		--zoom_detached_camera = false,
	},
	ecosystem = {
		no_donation_nag = true,
	},
	debug = {
		suppress_errors = true,
	},
})

-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
-- Default springs
hl.curve("easy", { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.curve("WorkspaceSpring", { type = "spring", mass = 1, stiffness = 71, dampening = 15 })

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
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.5, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.5, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.5, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 2, bezier = "quick" })

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
	master = {
		new_status = "slave",
		new_on_top = true,
	},
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
	scrolling = {
		fullscreen_on_one_column = true,
	},
})

---------------
---- INPUT ----
---------------

hl.config({
	input = {
		kb_layout = "us, us",
		kb_variant = "dvorak",
		kb_model = "",
		kb_options = "",
		kb_rules = "",

		kb_options = "caps:swapescape",

		follow_mouse = 1,

		sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

		touchpad = {
			natural_scroll = false,
		},
	},
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})

---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER" -- Sets "Windows" key as main modifier

local function focus_other_monitor()
	local monitors = hl.get_monitors()
	local current = hl.get_active_monitor()

	for _, m in ipairs(monitors) do
		if m.id ~= current.id then
			hl.dispatch(hl.dsp.focus({ monitor = m.name }))
			break
		end
	end
end

local function send_to_other_monitor()
	local current = hl.get_active_monitor()

	for _, m in ipairs(hl.get_monitors()) do
		if m.id ~= current.id then
			local ws = hl.get_active_workspace(m)

			if ws then
				hl.dispatch(hl.dsp.window.move({
					workspace = ws.id,
				}))
			end

			return
		end
	end
end

hl.bind(mainMod .. "+ O", focus_other_monitor)
hl.bind(mainMod .. "+ SHIFT + O", send_to_other_monitor)

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("alacritty"))
local closeWindowBind = hl.bind(mainMod .. " + COMMA", hl.dsp.window.close())
-- closeWindowBind:set_enabled(false)
hl.bind(
	mainMod .. " + SHIFT + L",
	hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
)

local CurrentLayout = "master" -- for tab overload function

hl.bind(mainMod .. " + APOSTROPHE", function()
	local ws = hl.get_active_workspace()
	if not ws then
		return
	end

	hl.workspace_rule({
		workspace = tostring(ws.id), -- or ws.name
		layout = "monocle",
	})
	CurrentLayout = "monocle" -- for the tabe overload
end)
hl.bind(mainMod .. " + PERIOD", function()
	local ws = hl.get_active_workspace()
	if not ws then
		return
	end
	hl.workspace_rule({
		workspace = tostring(ws.id), -- or ws.name
		layout = "master",
	})
	CurrentLayout = "master" -- for the tabe overload
end)

hl.bind(mainMod .. " + U", hl.dsp.exec_cmd("alacritty --working-directory /home/jackson -e ranger"))
hl.bind("SUPER + SEMICOLON", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

hl.bind(mainMod .. " + P", hl.dsp.window.float({ action = "toggle" }))

hl.bind(mainMod .. " + mouse:274", hl.dsp.window.float({ action = "toggle", mouse = true }))

hl.bind(mainMod .. " + mouse:272", function()
	local drag = hl.dsp.window.drag()
	hl.dispatch(drag)
end, { mouse = true })

hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("rofi -show drun"))
-- hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())

-- hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle only
hl.bind(mainMod .. " + R", hl.dsp.layout("removemaster"))
hl.bind(mainMod .. " + G", hl.dsp.layout("addmaster"))
--hl.bind(mainMod .. " + TAB", hl.dsp.layout("swapwithmaster"))

hl.bind(mainMod .. " + SPACE", hl.dsp.layout("cyclenext"))
local function TabOverload()
	if CurrentLayout == "master" then
		hl.dispatch(hl.dsp.layout("swapwithmaster"))
	elseif CurrentLayout == "monocle" then
		hl.dispatch(hl.dsp.layout("cyclenext"))
	end
end
hl.bind(mainMod .. " + TAB", TabOverload)

hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("hyprctl switchxkblayout current 0"))
hl.bind(mainMod .. " + CONTROL + M", hl.dsp.exec_cmd("hyprctl switchxkblayout current 1"))

hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + n", hl.dsp.focus({ direction = "right" }))

hl.bind(mainMod .. " + c", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + t", hl.dsp.focus({ direction = "down" }))

for i = 1, smw.get_amount_of_workspaces() do
	local n = tostring(i)
	if n == "10" then
		n = "0"
	end
	hl.bind(mainMod .. " +" .. n, smw.workspace(n))
	hl.bind(mainMod .. " + CTRL +" .. n, smw.move_to_workspace_silent(n))
	hl.bind(mainMod .. " + SHIFT +" .. n, smw.move_to_workspace(n))
end

-- Example special workspace (scratchpad)
-- hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
-- hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
--hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
--hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging

-- Laptop multimedia keys for volume and LCD brightness
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
	-- Fix some dragging issues with XWayland
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

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },

	move = "20 monitor_h-120",
	float = true,
})

hl.window_rule({
	match = { class = "Alacritty" },
	opacity = "0.75 override 0.65 override 0.65 override",
})

hl.window_rule({
	match = { class = "steam" },
	opacity = "0.9 override 0.75 override 0.75 override",
})

hl.window_rule({
	match = { class = "UnrealEditor" },
	opacity = "1 override 0.85 override 0.85 override",
})

hl.window_rule({
	match = { class = "jetbrains-rider" },
	opacity = "0.85 override 0.85 override 0.85 override",
})

local MAX_ZOOM = 3
local MIN_ZOOM = 1
local ZOOM_TOGGLE_FACTOR = 1.5

---@param offset number
---@return nil
local function zoom(offset)
	local current = hl.get_config("cursor.zoom_factor")
	if offset ~= nil then
		current = current + offset
	elseif current ~= MIN_ZOOM then
		current = MIN_ZOOM
	else
		current = ZOOM_TOGGLE_FACTOR
	end
	current = math.max(MIN_ZOOM, math.min(MAX_ZOOM, current))
	hl.config({ cursor = { zoom_factor = current } })
end

hl.bind("SUPER + Z", zoom)
hl.bind("SUPER + mouse_up", function()
	zoom(-0.5)
end)
hl.bind("SUPER + mouse_down", function()
	zoom(0.5)
end)
