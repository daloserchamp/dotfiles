# pylint: disable=C0111
c = c  # noqa: F821 pylint: disable=E0602,C0103
config = config  # noqa: F821 pylint: disable=E0602,C0103
# pylint settings included to disable linting errors
import subprocess
import os
import json


colorsjsonpath = os.path.expanduser('~/.cache/wal/colors.json')
colordict = json.load(open(colorsjsonpath))

colors = [
    (colordict['colors']['color0']), #bland1
    (colordict['colors']['color1']),
    (colordict['colors']['color2']),
    (colordict['colors']['color3']),
    (colordict['colors']['color4']),
    (colordict['colors']['color5']),
    (colordict['colors']['color6']),
    (colordict['colors']['color7']), # bland2
    (colordict['colors']['color8']), # bland3
    (colordict['colors']['color9']),
]

transcolors = [
    "#99"+colors[7].replace("#",""),
    "#99"+colors[0].replace("#",""),
]

foreground=colors[7]
background=colors[0]

color1="#ff1100" # statusbar.command.fg, statusbar.passthrough.fg
color2="#ff1100" # statusbar.url.fg, statusbar.url.success.https.fg
color3="#ff1100" # statusbar.url.hover.fg, 
color4="#ff1100" # tabs.odd.fg, tabs.even.fg
color5="#ff1100" # completion.item.selected.match.fg, completion.match.fg
color6="#ff1100" # tabs.indicator.start, downloads.start.bg
color7="#ff1100" # tabs.indicator.stop, downloads.stop.bg


c.colors.statusbar.normal.bg = "#00000000"
c.colors.statusbar.command.bg = "#00000000"
# c.colors.statusbar.normal.bg = background
# c.colors.statusbar.command.bg = background
c.colors.statusbar.command.fg = foreground
c.colors.statusbar.normal.fg = color1
c.colors.statusbar.passthrough.fg = color1
c.colors.statusbar.url.fg = color2
c.colors.statusbar.url.success.https.fg = color2
c.colors.statusbar.url.hover.fg = color3
# c.statusbar.show = "always"
c.colors.tabs.even.bg = "#00000025" # last two numbers dictate transparency!!
c.colors.tabs.odd.bg = "#00000025"
c.colors.tabs.bar.bg = "#00000025"
# c.colors.tabs.even.bg = background
# c.colors.tabs.odd.bg = background
c.colors.tabs.even.fg = color4
c.colors.tabs.odd.fg = color4
c.colors.tabs.selected.even.bg = foreground
c.colors.tabs.selected.odd.bg = foreground
c.colors.tabs.selected.even.fg = background
c.colors.tabs.selected.odd.fg = background
c.colors.hints.bg = transcolors[1]
c.colors.hints.fg = colors[7]
c.tabs.show = "multiple"

c.colors.completion.item.selected.match.fg = color5
c.colors.completion.match.fg = color5

c.colors.tabs.indicator.start = color6
c.colors.tabs.indicator.stop = color7
c.colors.completion.odd.bg = background
c.colors.completion.even.bg = background
c.colors.completion.fg = foreground
c.colors.completion.category.bg = background
c.colors.completion.category.fg = foreground
c.colors.completion.item.selected.bg = background
c.colors.completion.item.selected.fg = foreground

c.colors.messages.info.bg = background
c.colors.messages.info.fg = foreground
c.colors.messages.error.bg = background
c.colors.messages.error.fg = foreground
c.colors.downloads.error.bg = background
c.colors.downloads.error.fg = foreground

c.colors.downloads.bar.bg = background
c.colors.downloads.start.bg = color6
c.colors.downloads.start.fg = foreground
c.colors.downloads.stop.bg = color7
c.colors.downloads.stop.fg = foreground

c.colors.tooltip.bg = background
c.colors.webpage.bg = background
c.hints.border = foreground
c.colors.statusbar.insert.bg = background
c.colors.statusbar.insert.fg = background

c.tabs.title.format = "{audio}{current_title}"
c.fonts.web.size.default = 16

c.url.searchengines = {
# note - if you use duckduckgo, you can make use of its built in bangs, of which there are many! https://duckduckgo.com/bangs
        'DEFAULT': 'https://www.google.com//search?udm=14&q={}',
        '!w': 'https://wiki.archlinux.org/?search={}',
        '!pak': 'https://archlinux.org/packages/?sort=&q={}&maintainer=&flagged=',
        '!g': 'https://github.com/search?o=desc&q={}&s=stars',
        '!aur': 'https://aur.archlinux.org/packages?K={}',
        '!yt': 'https://www.youtube.com/results?search_query={}',
        }

c.url.start_pages = "https://archlinux.org/"
c.url.default_page = "https://archlinux.org/"

c.completion.open_categories = ['searchengines', 'quickmarks', 'bookmarks', 'history', 'filesystem']

config.load_autoconfig() # load settings done via the gui

c.auto_save.session = True # save tabs on quit/restart

c.zoom.default = 80
c.zoom.levels = ["25%", "80%", "100%", "120%", "200%", "500%"]

# keybinding changes
config.bind('=', 'cmd-set-text -s :open')
config.bind('h', 'history')
config.bind('cs', 'cmd-set-text -s :config-source')
config.bind('tH', 'config-cycle tabs.show multiple never')
config.bind('sH', 'config-cycle statusbar.show always never')
config.bind('T', 'hint links tab')
config.bind('pP', 'open -- {primary}')
config.bind('pp', 'open -- {clipboard}')
config.bind('pt', 'open -t -- {clipboard}')
config.bind('qm', 'macro-record')
config.bind('<ctrl-y>', 'spawn --userscript ytdl.sh')
config.bind('tT', 'config-cycle tabs.position top left')
config.bind('gJ', 'tab-move +')
config.bind('gK', 'tab-move -')
config.bind('gm', 'tab-move')

# dark mode setup
c.colors.webpage.darkmode.enabled = False
#c.colors.webpage.darkmode.threshold.background = 127
#c.colors.webpage.darkmode.threshold.foreground = 127
c.colors.webpage.preferred_color_scheme = "dark"
c.colors.webpage.darkmode.algorithm = 'lightness-cielab'
c.colors.webpage.darkmode.policy.images = 'never'
c.colors.webpage.darkmode.contrast = 0.0
config.set('colors.webpage.darkmode.enabled', False, 'file://*')

# styles, cosmetics
#c.content.user_stylesheets = ["~/.config/qutebrowser/styles/youtube-tweaks.css"]
c.tabs.padding = {'top': 3, 'bottom': 3, 'left': 3, 'right': 3}
c.tabs.indicator.width = 0 # no tab indicators
c.window.transparent = True # apparently not needed
c.tabs.width = '4%'

# fonts
c.fonts.default_family = []
c.fonts.default_size = '13pt'
c.fonts.web.family.fixed = 'monospace'
c.fonts.web.family.sans_serif = 'monospace'
c.fonts.web.family.serif = 'monospace'
c.fonts.web.family.standard = 'monospace'

# privacy - adjust these settings based on your preference
config.set("completion.cmd_history_max_items", 20)
config.set("content.private_browsing", False)
config.set("content.webgl", True, "*")
config.set("content.canvas_reading", False)
config.set("content.geolocation", False)
config.set("content.webrtc_ip_handling_policy", "default-public-interface-only")
config.set("content.cookies.accept", "all")
config.set("content.cookies.store", True)
# config.set("content.javascript.enabled", False) # tsh keybind to toggle

# Adblocking info -->
# For yt ads: place the greasemonkey script yt-ads.js in your greasemonkey folder (~/.config/qutebrowser/greasemonkey).
# The script skips through the entire ad, so all you have to do is click the skip button.
# Yeah it's not ublock origin, but if you want a minimal browser, this is a solution for the tradeoff.
# You can also watch yt vids directly in mpv, see qutebrowser FAQ for how to do that.
# If you want additional blocklists, you can get the python-adblock package, or you can uncomment the ublock lists here.
c.content.blocking.enabled = True
c.content.blocking.method = 'adblock'

c.content.fullscreen.window = True
c.statusbar.position = "top"
