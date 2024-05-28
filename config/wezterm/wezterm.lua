local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action
local launch_menu = {}

config.color_scheme = "iceberg-dark"
config.window_background_opacity = 0.87
config.default_cursor_style = "BlinkingBar"
config.font = wezterm.font_with_fallback({
  { family = "PlemolJP Console NF", harfbuzz_features = { "zero" } },
  "源ノ角ゴシック Code JP",
  "Noto Color Emoji",
  "Cascadia Code",
})
config.adjust_window_size_when_changing_font_size = nil

-- target_triple candidates
-- https://doc.rust-lang.org/nightly/rustc/platform-support.html
if string.find(wezterm.target_triple, "pc-windows", 1, true) then
  config.default_prog = { "pwsh", "-NoLogo" }
  table.insert(launch_menu, {
    label = "PowerShell",
    args = { "pwsh", "-NoLogo" },
  })
end

config.keys = {
  -- TODO: Consider to move into windows only combination
  { key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
}

config.launch_menu = launch_menu

return config
