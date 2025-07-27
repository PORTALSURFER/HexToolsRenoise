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

  -- Store original mute states
  local original_mute_states = {}
  for i = 1, #song.tracks do
    original_mute_states[i] = song.tracks[i].mute_state
  end

  -- Mute all tracks except the selected one
  for i = 1, #song.tracks do
    local track = song.tracks[i]
    -- Skip master track as it cannot be muted
    if track.type == renoise.Track.TRACK_TYPE_MASTER then
      -- Keep master track as is
    elseif i == song.selected_track_index then
      track.mute_state = renoise.Track.MUTE_STATE_ACTIVE
    else
      track.mute_state = renoise.Track.MUTE_STATE_MUTED
    end
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
    -- Restore original mute states
    for i = 1, #song.tracks do
      song.tracks[i].mute_state = original_mute_states[i]
    end

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

    -- 4. Ensure the new track is unmuted and focus it
    song.tracks[new_track_idx].mute_state = renoise.Track.MUTE_STATE_ACTIVE
    song.selected_track_index = new_track_idx

    -- 5. Optionally cut (clear) all note/effect data in the original selection
    if destructive then
      local orig_track = pattern:track(song.selected_track_index - 1) -- Use original track index
      for l = sel.start_line, sel.end_line do
        local orig_line = orig_track:line(l)
        for nc = 1, #orig_line.note_columns do
          orig_line:note_column(nc):clear()
        end
        for ec = 1, #orig_line.effect_columns do
          orig_line:effect_column(ec):clear()
        end
      end
      -- Add an 'off' note at the top of the original selection
      local orig_line = orig_track:line(sel.start_line)
      orig_line:note_column(1).note_value = 121 -- OFF note
      orig_line:note_column(1).instrument_value = 255 -- No instrument
      orig_line:note_column(1).volume_value = 255 -- No volume
      renoise.app():show_status("Rendered selection, added new note, cut original selection, and added OFF note")
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

  -- Store original mute states
  local original_mute_states = {}
  for i = 1, #song.tracks do
    original_mute_states[i] = song.tracks[i].mute_state
  end

  -- Mute all tracks except the selected one
  for i = 1, #song.tracks do
    local track = song.tracks[i]
    -- Skip master track as it cannot be muted
    if track.type == renoise.Track.TRACK_TYPE_MASTER then
      -- Keep master track as is
    elseif i == song.selected_track_index then
      track.mute_state = renoise.Track.MUTE_STATE_ACTIVE
    else
      track.mute_state = renoise.Track.MUTE_STATE_MUTED
    end
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
    -- Restore original mute states before returning
    for i = 1, #song.tracks do
      song.tracks[i].mute_state = original_mute_states[i]
    end
    renoise.app():show_status("No next track available to render into")
    return
  end

  song:render(options, temp_file, function()
    -- Restore original mute states
    for i = 1, #song.tracks do
      song.tracks[i].mute_state = original_mute_states[i]
    end

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

    -- 3. Ensure the next track is unmuted and focus it
    song.tracks[next_track_idx].mute_state = renoise.Track.MUTE_STATE_ACTIVE
    song.selected_track_index = next_track_idx

    -- 4. Optionally cut (clear) all note/effect data in the original selection
    if destructive then
      local orig_track = pattern:track(song.selected_track_index - 1) -- Use original track index
      for l = sel.start_line, sel.end_line do
        local orig_line = orig_track:line(l)
        for nc = 1, #orig_line.note_columns do
          orig_line:note_column(nc):clear()
        end
        for ec = 1, #orig_line.effect_columns do
          orig_line:effect_column(ec):clear()
        end
      end
      -- Add an 'off' note at the top of the original selection
      local orig_line = orig_track:line(sel.start_line)
      orig_line:note_column(1).note_value = 121 -- OFF note
      orig_line:note_column(1).instrument_value = 255 -- No instrument
      orig_line:note_column(1).volume_value = 255 -- No volume
      renoise.app():show_status("Rendered selection, added new note to next track, cut original selection, and added OFF note")
    else
      renoise.app():show_status("Rendered selection to new instrument and added C-4 note in next track")
    end
  end)
end

return M 