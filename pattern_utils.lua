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

-- Change LPB (Lines Per Beat) while adjusting all notes to maintain timing
function M.change_lpb()
  local song = renoise.song()
  local current_lpb = song.transport.lpb
  
  -- Create dialog for LPB input
  local vb = renoise.ViewBuilder()
  local input_field = vb:textfield { id = "lpb_input", value = tostring(current_lpb) }
  local dialog
  
  local function on_change_lpb()
    local input = input_field.value
    if not input or input == "" then
      renoise.app():show_message("No LPB value entered.")
      return
    end
    
    local new_lpb = tonumber(input)
    if not new_lpb or new_lpb < 1 or new_lpb > 32 then
      renoise.app():show_error("Invalid LPB value. Must be between 1 and 32.")
      return
    end
    
    if new_lpb == current_lpb then
      renoise.app():show_status("LPB unchanged: " .. current_lpb)
      if dialog then dialog:close() end
      return
    end
    
    -- Calculate the scaling factor
    local scale_factor = new_lpb / current_lpb
    
    -- Process all patterns in the song
    local total_patterns = #song.sequencer.pattern_sequence
    local processed_patterns = 0
    
    for seq_idx = 1, total_patterns do
      local patt_idx = song.sequencer:pattern(seq_idx)
      local pattern = song:pattern(patt_idx)
      local original_length = pattern.number_of_lines
      
      -- Calculate new pattern length
      local new_length = math.floor(original_length * scale_factor + 0.5)
      if new_length < 1 then new_length = 1 end
      
      -- Store original pattern data before resizing
      local original_data = {}
      for track_idx = 1, #song.tracks do
        local track = pattern:track(track_idx)
        original_data[track_idx] = {}
        
        for line_idx = 1, original_length do
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
      
      -- Process each track efficiently
      for track_idx = 1, #song.tracks do
        local track = pattern:track(track_idx)
        
        -- Clear all lines first (batch operation)
        for line_idx = 1, new_length do
          local line = track:line(line_idx)
          line:clear()
        end
        
        -- Copy data from stored original data to new positions
        for orig_line_idx = 1, original_length do
          local new_line_idx = math.floor((orig_line_idx - 1) * scale_factor + 0.5) + 1
          
          -- Ensure we don't exceed the new pattern length
          if new_line_idx <= new_length then
            local new_line = track:line(new_line_idx)
            local orig_data = original_data[track_idx][orig_line_idx]
            
            -- Copy note columns efficiently
            for nc = 1, #new_line.note_columns do
              local note_col = new_line:note_column(nc)
              local note_data = orig_data.notes[nc]
              
              if note_data then
                note_col.note_value = note_data.note_value
                note_col.instrument_value = note_data.instrument_value
                note_col.volume_value = note_data.volume_value
                note_col.panning_value = note_data.panning_value
                note_col.delay_value = note_data.delay_value
              end
            end
            
            -- Copy effect columns efficiently
            for ec = 1, #new_line.effect_columns do
              local effect_col = new_line:effect_column(ec)
              local effect_data = orig_data.effects[ec]
              
              if effect_data then
                effect_col.number_value = effect_data.number_value
                effect_col.amount_value = effect_data.amount_value
              end
            end
          end
        end
      end
      
      processed_patterns = processed_patterns + 1
    end
    
    -- Set the new LPB
    song.transport.lpb = new_lpb
    
    renoise.app():show_status(
      "LPB changed from " .. current_lpb .. " to " .. new_lpb .. 
      " (scale: " .. string.format("%.2f", scale_factor) .. "x). " ..
      "Processed " .. processed_patterns .. " patterns."
    )
    
    if dialog then dialog:close() end
  end
  
  -- Create the dialog
  local dialog_content = vb:column {
    vb:text { text = "Enter new LPB value (current: " .. current_lpb .. "):" },
    input_field,
    vb:row {
      vb:button {
        text = "Change LPB",
        notifier = on_change_lpb
      },
      vb:button {
        text = "Cancel",
        notifier = function()
          if dialog then dialog:close() end
        end
      }
    }
  }
  
  dialog = renoise.app():show_custom_dialog("Change LPB", dialog_content)
end

return M 