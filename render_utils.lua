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

  -- Determine the source track from selection (not cursor position)
  local source_track_idx = sel.start_track or song.selected_track_index

  -- Mute all tracks except the selected one
  for i = 1, #song.tracks do
    local track = song.tracks[i]
    -- Skip master track as it cannot be muted
    if track.type == renoise.Track.TRACK_TYPE_MASTER then
      -- Keep master track as is
    elseif i == source_track_idx then
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
    bit_depth = 16,
    channels = 2,
    priority = "high",
    interpolation = "precise",
    sample_rate = 48000
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
    local sample = instr:sample(1)
    sample.sample_buffer:load_from(temp_file)
    
    -- Enable autoseek for the rendered sample
    sample.autoseek = true
    
    -- Apply 6dB boost by setting instrument volume to maximum (approximately 6dB boost)
    instr.volume = 1.99526
    
    os.remove(temp_file)

    -- 2. Create a new track to the right of the source track
    local new_track_idx = source_track_idx + 1
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
      local orig_track = pattern:track(source_track_idx) -- Use source track from selection
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

  -- Determine the source track from selection (not cursor position)
  local source_track_idx = sel.start_track or song.selected_track_index

  -- Mute all tracks except the selected one
  for i = 1, #song.tracks do
    local track = song.tracks[i]
    -- Skip master track as it cannot be muted
    if track.type == renoise.Track.TRACK_TYPE_MASTER then
      -- Keep master track as is
    elseif i == source_track_idx then
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
    priority = "high",
    sample_rate = 48000
  }

  local next_track_idx = source_track_idx + 1
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
    local sample = instr:sample(1)
    sample.sample_buffer:load_from(temp_file)
    
    -- Enable autoseek for the rendered sample
    sample.autoseek = true
    
    -- Apply 6dB boost by setting instrument volume to 2.0 (6dB = 20*log10(2))
    instr.volume = 2.0
    
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
      local orig_track = pattern:track(source_track_idx) -- Use source track from selection
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

-- Sample all notes from a track in the current pattern and merge them into the focused track
function M.sample_and_merge_track_notes()
  local song = renoise.song()
  local sel = song.selection_in_pattern

  if not sel then
    renoise.app():show_status("Nothing selected to sample from")
    return
  end

  -- Determine source track from selection
  local source_track_idx = sel.start_track or song.selected_track_index
  local target_track_idx = song.selected_track_index

  -- Don't allow sampling from the same track
  if source_track_idx == target_track_idx then
    renoise.app():show_status("Cannot sample from the same track")
    return
  end

  local pattern = song:pattern(song.selected_pattern_index)
  local source_track = pattern:track(source_track_idx)
  local target_track = pattern:track(target_track_idx)

  -- Collect all notes from source track
  local notes_to_merge = {}
  local effects_to_merge = {}
  for line_idx = 1, pattern.number_of_lines do
    local line = source_track:line(line_idx)
    for nc = 1, #line.note_columns do
      local note_col = line:note_column(nc)
      if note_col.note_value ~= 121 and note_col.instrument_value ~= 255 then -- Not empty
        table.insert(notes_to_merge, {
          line = line_idx,
          column = nc,
          note_value = note_col.note_value,
          instrument_value = note_col.instrument_value,
          volume_value = note_col.volume_value,
          panning_value = note_col.panning_value,
          delay_value = note_col.delay_value
        })
      end
    end
    -- Collect effect columns
    for ec = 1, #line.effect_columns do
      local effect_col = line:effect_column(ec)
      if not effect_col.is_empty then
        table.insert(effects_to_merge, {
          line = line_idx,
          column = ec,
          number_value = effect_col.number_value,
          amount_value = effect_col.amount_value
        })
      end
    end
  end

  if #notes_to_merge == 0 and #effects_to_merge == 0 then
    renoise.app():show_status("No notes or effects found in source track to merge")
    return
  end

  -- Find the first empty note column in target track
  local first_empty_column = 1
  for line_idx = 1, pattern.number_of_lines do
    local line = target_track:line(line_idx)
    for nc = 1, #line.note_columns do
      local note_col = line:note_column(nc)
      if note_col.note_value == 121 and note_col.instrument_value == 255 then -- Empty
        first_empty_column = nc
        break
      end
    end
    if first_empty_column > 1 then break end
  end

  -- Find the first empty effect column in target track
  local first_empty_effect_column = 1
  for line_idx = 1, pattern.number_of_lines do
    local line = target_track:line(line_idx)
    for ec = 1, #line.effect_columns do
      local effect_col = line:effect_column(ec)
      if effect_col.is_empty then
        first_empty_effect_column = ec
        break
      end
    end
    if first_empty_effect_column > 1 then break end
  end

  -- Check if we have enough columns in target track
  local target_line = target_track:line(1)
  if first_empty_column > #target_line.note_columns then
    renoise.app():show_status("Target track doesn't have enough note columns")
    return
  end
  if first_empty_effect_column > #target_line.effect_columns then
    renoise.app():show_status("Target track doesn't have enough effect columns")
    return
  end

  -- Merge notes into target track
  local merged_count = 0
  for _, note_data in ipairs(notes_to_merge) do
    local line = target_track:line(note_data.line)
    local note_col = line:note_column(first_empty_column)
    
    note_col.note_value = note_data.note_value
    note_col.instrument_value = note_data.instrument_value
    note_col.volume_value = note_data.volume_value
    note_col.panning_value = note_data.panning_value
    note_col.delay_value = note_data.delay_value
    
    merged_count = merged_count + 1
  end

  -- Merge effects into target track
  local merged_effects_count = 0
  for _, effect_data in ipairs(effects_to_merge) do
    local line = target_track:line(effect_data.line)
    local effect_col = line:effect_column(first_empty_effect_column)
    
    effect_col.number_value = effect_data.number_value
    effect_col.amount_value = effect_data.amount_value
    
    merged_effects_count = merged_effects_count + 1
  end

  -- Clear the source track
  for line_idx = 1, pattern.number_of_lines do
    local line = source_track:line(line_idx)
    for nc = 1, #line.note_columns do
      line:note_column(nc):clear()
    end
    for ec = 1, #line.effect_columns do
      line:effect_column(ec):clear()
    end
  end

  local status_msg = string.format("Merged %d notes and %d effects from track %d to track %d", 
    merged_count, merged_effects_count, source_track_idx, target_track_idx)
  renoise.app():show_status(status_msg)
end

-- Custom clipboard for storing rendered samples
local sample_clipboard = {
  file_path = nil,
  instrument_index = nil,
  sample_index = nil
}

-- Render the current pattern selection to a sample and store it in custom clipboard
function M.render_selection_to_copy_buffer()
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

  -- Determine the source track from selection (not cursor position)
  local source_track_idx = sel.start_track or song.selected_track_index

  -- Mute all tracks except the selected one
  for i = 1, #song.tracks do
    local track = song.tracks[i]
    -- Skip master track as it cannot be muted
    if track.type == renoise.Track.TRACK_TYPE_MASTER then
      -- Keep master track as is
    elseif i == source_track_idx then
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
    bit_depth = 16,
    channels = 2,
    priority = "high",
    interpolation = "precise",
    sample_rate = 48000
  }

  song:render(options, temp_file, function()
    -- Restore original mute states
    for i = 1, #song.tracks do
      song.tracks[i].mute_state = original_mute_states[i]
    end

    -- Create a temporary instrument to hold the sample
    local temp_instr_idx = song.selected_instrument_index + 1
    local temp_instr = song:insert_instrument_at(temp_instr_idx)
    temp_instr:insert_sample_at(1)
    local sample = temp_instr:sample(1)
    sample.sample_buffer:load_from(temp_file)
    
    -- Enable autoseek for the rendered sample
    sample.autoseek = true
    
    -- Apply 6dB boost by setting instrument volume to maximum (approximately 6dB boost)
    temp_instr.volume = 1.99526
    
    -- Store the sample data in our custom clipboard
    local sample = temp_instr:sample(1)
    if sample and sample.sample_buffer then
      -- Copy the temporary file to a persistent clipboard file
      local clipboard_file = os.tmpname() .. "_clipboard_sample.wav"
      
      -- Use a simple file copy approach since save_to doesn't exist
      local input_file = io.open(temp_file, "rb")
      local output_file = io.open(clipboard_file, "wb")
      
      if input_file and output_file then
        local content = input_file:read("*all")
        output_file:write(content)
        input_file:close()
        output_file:close()
        
        -- Store the clipboard data
        sample_clipboard.file_path = clipboard_file
        sample_clipboard.instrument_index = temp_instr_idx
        sample_clipboard.sample_index = 1
        
        -- Select the instrument for the user
        song.selected_instrument_index = temp_instr_idx - 1 -- 0-based index
        
        renoise.app():show_status("Sample copied to clipboard! Use 'Paste Sample from Clipboard' to paste it into any instrument.")
      else
        renoise.app():show_status("Failed to copy sample to clipboard")
      end
      
      -- Clean up the original temporary file
      os.remove(temp_file)
    else
      -- Remove the temporary instrument if we failed to create the sample
      song:delete_instrument_at(temp_instr_idx)
      os.remove(temp_file)
      renoise.app():show_status("Failed to render selection to sample")
    end
  end)
end

-- Paste the stored sample from clipboard into the selected instrument
function M.paste_sample_from_clipboard()
  local song = renoise.song()
  
  if not sample_clipboard.file_path or not sample_clipboard.instrument_index then
    renoise.app():show_status("No sample in clipboard. Use 'Render Selection To Copy Buffer' first.")
    return
  end
  
  -- Check if the clipboard file still exists
  local file = io.open(sample_clipboard.file_path, "r")
  if not file then
    renoise.app():show_status("Clipboard sample file not found. Please render again.")
    return
  end
  file:close()
  
  -- Get the currently selected instrument
  local target_instr_idx = song.selected_instrument_index + 1 -- Convert to 1-based
  local target_instr = song:instrument(target_instr_idx)
  
  if not target_instr then
    renoise.app():show_status("No instrument selected")
    return
  end
  
  -- Get the current number of samples
  local current_sample_count = #target_instr.samples
  
  -- Insert a new sample at the end
  target_instr:insert_sample_at(current_sample_count + 1)
  
  -- Get the new sample count after insertion
  local new_sample_count = #target_instr.samples
  
  -- Check if a new sample was actually created
  if new_sample_count > current_sample_count then
    -- Access the newly created sample (it should be the last one)
    local new_sample = target_instr:sample(new_sample_count)
    
    if new_sample and new_sample.sample_buffer then
      -- Load the clipboard sample into the new sample slot
      new_sample.sample_buffer:load_from(sample_clipboard.file_path)
      
      -- Enable autoseek for the pasted sample
      new_sample.autoseek = true
      
      -- Apply the same volume boost as the original
      target_instr.volume = 1.99526
      
      renoise.app():show_status("Sample pasted into instrument " .. target_instr_idx .. " sample " .. new_sample_count)
    else
      renoise.app():show_status("Failed to access sample slot in instrument")
    end
  else
    renoise.app():show_status("Failed to create sample slot in instrument")
  end
end

-- Clear the clipboard
function M.clear_sample_clipboard()
  if sample_clipboard.file_path then
    -- Try to remove the clipboard file
    os.remove(sample_clipboard.file_path)
  end
  
  -- Clear the clipboard data
  sample_clipboard.file_path = nil
  sample_clipboard.instrument_index = nil
  sample_clipboard.sample_index = nil
  
  renoise.app():show_status("Sample clipboard cleared")
end

return M 