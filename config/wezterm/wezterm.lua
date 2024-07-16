local wezterm <const> = require("wezterm")
local mux <const> = wezterm.mux
local config <const> = wezterm.config_builder()
local action <const> = wezterm.action
local launch_menu <const> = {}
local font_with_fallback <const> = wezterm.font_with_fallback({
  {
    family = "PlemolJP Console NF",
    harfbuzz_features = { "zero" },
    weight = "Medium",
    assume_emoji_presentation = false,
  },
  { family = "Beedii", assume_emoji_presentation = true },
  "源ノ角ゴシック Code JP",
})

config.color_scheme = "iceberg-dark"
config.window_background_opacity = 0.94
config.default_cursor_style = "BlinkingBar"
config.font = font_with_fallback
config.font_size = 13
config.adjust_window_size_when_changing_font_size = nil
config.window_frame = {
  font = font_with_fallback,
  font_size = 12,
}
config.window_close_confirmation = "NeverPrompt"

-- target_triple candidates
-- https://doc.rust-lang.org/nightly/rustc/platform-support.html
if string.find(wezterm.target_triple, "pc-windows", 1, true) then
  config.default_prog = { "wsl.exe", "--distribution", "Ubuntu-24.04", "--cd", "~" }
  table.insert(launch_menu, {
    label = "PowerShell",
    args = { "pwsh", "-NoLogo" },
  })
end

-- Using in wayland requires non released versions
-- https://github.com/wez/wezterm/issues/5340
if string.find(wezterm.target_triple, "-linux", 1, true) then
  config.enable_wayland = true
  config.use_ime = true
end

config.keys = {
  -- TODO: Consider to move into windows only combination
  { key = "v", mods = "CTRL", action = action.PasteFrom("Clipboard") },
  {
    key = "r",
    mods = "CMD|SHIFT",
    action = action.ReloadConfiguration,
  },
}

wezterm.on("gui-startup", function(cmd)
  local tab, pane, window <const> = mux.spawn_window(cmd or {})
  local screen <const> = wezterm.gui.screens().active
  local gui_window <const> = window:gui_window()

  gui_window:set_inner_size(screen.width * 0.8, screen.height * 0.8)
  gui_window:set_position(screen.width * 0.05, screen.height * 0.05)
end)

config.launch_menu = launch_menu

return config
