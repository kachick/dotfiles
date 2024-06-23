local wezterm <const> = require("wezterm")
local config <const> = wezterm.config_builder()
local act <const> = wezterm.action
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
end

config.keys = {
  -- TODO: Consider to move into windows only combination
  { key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
}

config.launch_menu = launch_menu

return config
