local M = {}

-- Render the current pattern selection to a WAV file. See
-- https://renoise.github.io/xrnx/API/renoise.song.API.html#render
function M.render_selection_to_new_track(destructive)
  local song = renoise.song()
  local sel = song.selection_in_pattern

  if not sel then
    renoise.app():show_status("Nothing selected to render")
    return
  end

  local start_pos = renoise.SongPos(song.selected_sequence_index, sel.start_line)
  local end_pos = renoise.SongPos(song.selected_sequence_index, sel.end_line)
  local temp_file = os.tmpname() .. ".wav"

  local options = {
    start_pos = start_pos,
    end_pos = end_pos,
    priority = "high"
  }

  song:render(options, temp_file, function()
    -- 1. Create new instrument and load sample
    local new_instr_idx = song.selected_instrument_index + 1
    local instr = song:insert_instrument_at(new_instr_idx)
    instr:insert_sample_at(1)
    instr:sample(1).sample_buffer:load_from(temp_file)
    os.remove(temp_file)

    -- 2. Create a new track to the right of the current track
    local new_track_idx = song.selected_track_index + 1
    song:insert_track_at(new_track_idx)

    -- 3. Add a C-4 note with full velocity at the top of the selection
    local pattern = song:pattern(song.selected_pattern_index)
    local track = pattern:track(new_track_idx)
    local line = track:line(sel.start_line)
    line:note_column(1).note_value = 48 -- C-4
    line:note_column(1).instrument_value = new_instr_idx - 1 -- 0-based
    line:note_column(1).volume_value = 0xFF -- full velocity (255 in hex)

    -- 4. Optionally cut (clear) all note/effect data in the original selection
    if destructive then
      local orig_track = pattern:track(song.selected_track_index)
      for l = sel.start_line, sel.end_line do
        local orig_line = orig_track:line(l)
        for nc = 1, #orig_line.note_columns do
          orig_line:note_column(nc):clear()
        end
        for ec = 1, #orig_line.effect_columns do
          orig_line:effect_column(ec):clear()
        end
      end
      renoise.app():show_status("Rendered selection, added new note, and cut original selection")
    else
      renoise.app():show_status("Rendered selection to new instrument and added C-4 note in new track")
    end
  end)
end

-- Render the current pattern selection to the next existing track (does not create a new track)
function M.render_selection_to_next_track(destructive)
  local song = renoise.song()
  local sel = song.selection_in_pattern

  if not sel then
    renoise.app():show_status("Nothing selected to render")
    return
  end

  local start_pos = renoise.SongPos(song.selected_sequence_index, sel.start_line)
  local end_pos = renoise.SongPos(song.selected_sequence_index, sel.end_line)
  local temp_file = os.tmpname() .. ".wav"

  local options = {
    start_pos = start_pos,
    end_pos = end_pos,
    priority = "high"
  }

  local next_track_idx = song.selected_track_index + 1
  if next_track_idx > #song.tracks then
    renoise.app():show_status("No next track available to render into")
    return
  end

  song:render(options, temp_file, function()
    -- 1. Create new instrument and load sample
    local new_instr_idx = song.selected_instrument_index + 1
    local instr = song:insert_instrument_at(new_instr_idx)
    instr:insert_sample_at(1)
    instr:sample(1).sample_buffer:load_from(temp_file)
    os.remove(temp_file)

    -- 2. Use the next existing track (do not create a new one)
    local pattern = song:pattern(song.selected_pattern_index)
    local track = pattern:track(next_track_idx)
    local line = track:line(sel.start_line)
    line:note_column(1).note_value = 48 -- C-4
    line:note_column(1).instrument_value = new_instr_idx - 1 -- 0-based
    line:note_column(1).volume_value = 0xFF -- full velocity (255 in hex)

    -- 3. Optionally cut (clear) all note/effect data in the original selection
    if destructive then
      local orig_track = pattern:track(song.selected_track_index)
      for l = sel.start_line, sel.end_line do
        local orig_line = orig_track:line(l)
        for nc = 1, #orig_line.note_columns do
          orig_line:note_column(nc):clear()
        end
        for ec = 1, #orig_line.effect_columns do
          orig_line:effect_column(ec):clear()
        end
      end
      renoise.app():show_status("Rendered selection, added new note to next track, and cut original selection")
    else
      renoise.app():show_status("Rendered selection to new instrument and added C-4 note in next track")
    end
  end)
end

return M 