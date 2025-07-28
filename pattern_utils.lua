local M = {}

-- Double the current pattern length by duplicating the first half
function M.double_pattern_length()
  local song = renoise.song()
  local pattern = song:pattern(song.selected_pattern_index)
  local current_length = pattern.number_of_lines
  
  -- Calculate new length (double the current)
  local new_length = current_length * 2
  local half_length = current_length
  
  -- Store original pattern data
  local original_data = {}
  for track_idx = 1, #song.tracks do
    local track = pattern:track(track_idx)
    original_data[track_idx] = {}
    
    for line_idx = 1, current_length do
      local line = track:line(line_idx)
      original_data[track_idx][line_idx] = {
        notes = {},
        effects = {}
      }
      
      -- Store note columns
      for nc = 1, #line.note_columns do
        local note_col = line:note_column(nc)
        original_data[track_idx][line_idx].notes[nc] = {
          note_value = note_col.note_value,
          instrument_value = note_col.instrument_value,
          volume_value = note_col.volume_value,
          panning_value = note_col.panning_value,
          delay_value = note_col.delay_value
        }
      end
      
      -- Store effect columns
      for ec = 1, #line.effect_columns do
        local effect_col = line:effect_column(ec)
        original_data[track_idx][line_idx].effects[ec] = {
          number_value = effect_col.number_value,
          amount_value = effect_col.amount_value
        }
      end
    end
  end
  
  -- Resize pattern to new length
  pattern.number_of_lines = new_length
  
  -- Copy data to second half
  for track_idx = 1, #song.tracks do
    local track = pattern:track(track_idx)
    
    for line_idx = 1, half_length do
      local source_line = track:line(line_idx)
      local target_line = track:line(line_idx + half_length)
      
      -- Copy note columns
      for nc = 1, #source_line.note_columns do
        local source_note = source_line:note_column(nc)
        local target_note = target_line:note_column(nc)
        local data = original_data[track_idx][line_idx].notes[nc]
        
        target_note.note_value = data.note_value
        target_note.instrument_value = data.instrument_value
        target_note.volume_value = data.volume_value
        target_note.panning_value = data.panning_value
        target_note.delay_value = data.delay_value
      end
      
      -- Copy effect columns
      for ec = 1, #source_line.effect_columns do
        local source_effect = source_line:effect_column(ec)
        local target_effect = target_line:effect_column(ec)
        local data = original_data[track_idx][line_idx].effects[ec]
        
        target_effect.number_value = data.number_value
        target_effect.amount_value = data.amount_value
      end
    end
  end
  
  renoise.app():show_status("Pattern length doubled from " .. current_length .. " to " .. new_length .. " lines")
end

-- Halve the current pattern length by keeping only the first half
function M.halve_pattern_length()
  local song = renoise.song()
  local pattern = song:pattern(song.selected_pattern_index)
  local current_length = pattern.number_of_lines
  
  -- Calculate new length (half the current)
  local new_length = math.floor(current_length / 2)
  
  if new_length < 1 then
    renoise.app():show_error("Pattern is too short to halve. Current length: " .. current_length)
    return
  end
  
  -- Store data from first half
  local first_half_data = {}
  for track_idx = 1, #song.tracks do
    local track = pattern:track(track_idx)
    first_half_data[track_idx] = {}
    
    for line_idx = 1, new_length do
      local line = track:line(line_idx)
      first_half_data[track_idx][line_idx] = {
        notes = {},
        effects = {}
      }
      
      -- Store note columns
      for nc = 1, #line.note_columns do
        local note_col = line:note_column(nc)
        first_half_data[track_idx][line_idx].notes[nc] = {
          note_value = note_col.note_value,
          instrument_value = note_col.instrument_value,
          volume_value = note_col.volume_value,
          panning_value = note_col.panning_value,
          delay_value = note_col.delay_value
        }
      end
      
      -- Store effect columns
      for ec = 1, #line.effect_columns do
        local effect_col = line:effect_column(ec)
        first_half_data[track_idx][line_idx].effects[ec] = {
          number_value = effect_col.number_value,
          amount_value = effect_col.amount_value
        }
      end
    end
  end
  
  -- Resize pattern to new length
  pattern.number_of_lines = new_length
  
  -- Restore data from first half
  for track_idx = 1, #song.tracks do
    local track = pattern:track(track_idx)
    
    for line_idx = 1, new_length do
      local line = track:line(line_idx)
      local data = first_half_data[track_idx][line_idx]
      
      -- Restore note columns
      for nc = 1, #line.note_columns do
        local note_col = line:note_column(nc)
        local note_data = data.notes[nc]
        
        note_col.note_value = note_data.note_value
        note_col.instrument_value = note_data.instrument_value
        note_col.volume_value = note_data.volume_value
        note_col.panning_value = note_data.panning_value
        note_col.delay_value = note_data.delay_value
      end
      
      -- Restore effect columns
      for ec = 1, #line.effect_columns do
        local effect_col = line:effect_column(ec)
        local effect_data = data.effects[ec]
        
        effect_col.number_value = effect_data.number_value
        effect_col.amount_value = effect_data.amount_value
      end
    end
  end
  
  renoise.app():show_status("Pattern length halved from " .. current_length .. " to " .. new_length .. " lines")
end

return M 