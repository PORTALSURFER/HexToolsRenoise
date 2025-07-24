-- Hello World Tool
-- Adds a menu entry that shows 'Hello, world!' in the status bar.
-- See the Renoise API documentation: https://renoise.github.io/xrnx/API/index.htm

local function show_hello()
  renoise.app():show_status("Hello, world!")
end

-- Render the current pattern selection to a WAV file. See
-- https://renoise.github.io/xrnx/API/renoise.song.API.html#render
local function render_selection_to_audio()
  local song = renoise.song()
  local sel = song.selection_in_pattern
  if not sel then
    renoise.app():show_status("Nothing selected to render")
    return
  end

  -- Use the selected pattern range for rendering
  local start_pos = renoise.SongPos(song.selected_sequence_index, sel.start_line)
  local end_pos = renoise.SongPos(song.selected_sequence_index, sel.end_line)

  local file = renoise.app():prompt_for_filename_to_write("wav")
  if not file then return end

  local options = {
    start_pos = start_pos,
    end_pos = end_pos,
    sample_rate = 44100,
    bit_depth = 16,
    interpolation_quality = "HQ",
    priority = "LOW"
  }

  song:render(options, file, function()
    renoise.app():show_status("Rendered selection to " .. file)
  end)
end

renoise.tool():add_menu_entry{
  name = "Main Menu:Tools:Hello World Tool:Show Hello",
  invoke = show_hello
}

renoise.tool():add_menu_entry{
  name = "Main Menu:Tools:Hello World Tool:Render Selection to Audio",
  invoke = render_selection_to_audio
}
