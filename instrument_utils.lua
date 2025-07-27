local M = {}
local utils = require("utils")

-- List duplicate instruments (all samples match, skipping empty and plugin instruments), indices as HEX, compare by waveform only, display indices -1
function M.list_duplicate_instruments_by_samples()
  local song = renoise.song()
  local instruments = {}
  -- Collect all instruments and their sample buffers, skip empty and plugin instruments
  for i = 1, #song.instruments do
    local instr = song:instrument(i)
    if #instr.samples > 0 and not instr.plugin_properties.plugin_loaded then
      local sample_buffers = {}
      for s = 1, #instr.samples do
        local sample = instr:sample(s)
        local buf = sample.sample_buffer
        if buf.has_sample_data then
          table.insert(sample_buffers, buf)
        else
          table.insert(sample_buffers, nil)
        end
      end
      table.insert(instruments, {
        idx = i,
        name = instr.name,
        sample_buffers = sample_buffers,
        sample_count = #instr.samples
      })
    end
  end

  local duplicates = {}
  -- Compare each pair of instruments by waveform only
  for i = 1, #instruments - 1 do
    local a = instruments[i]
    for j = i + 1, #instruments do
      local b = instruments[j]
      if a.sample_count == b.sample_count then
        local all_match = true
        for s = 1, a.sample_count do
          local buf_a = a.sample_buffers[s]
          local buf_b = b.sample_buffers[s]
          if buf_a and buf_b then
            if buf_a.number_of_frames ~= buf_b.number_of_frames or buf_a.number_of_channels ~= buf_b.number_of_channels or buf_a.sample_rate ~= buf_b.sample_rate then
              all_match = false
              break
            end
            for frame = 1, buf_a.number_of_frames do
              for ch = 1, buf_a.number_of_channels do
                if buf_a:sample_data(ch, frame) ~= buf_b:sample_data(ch, frame) then
                  all_match = false
                  break
                end
              end
              if not all_match then break end
            end
            if not all_match then break end
          elseif buf_a ~= buf_b then -- one is nil, the other is not
            all_match = false
            break
          end
        end
        if all_match then
          table.insert(duplicates, {a = a, b = b})
        end
      end
    end
  end

  if #duplicates > 0 then
    local msg = "Duplicate instruments (all samples match):\n"
    for _, pair in ipairs(duplicates) do
      msg = msg .. ("%02X == %02X\n")
        :format(pair.a.idx - 1, pair.b.idx - 1)
    end
    renoise.app():show_message(msg)
  else
    renoise.app():show_message("No duplicate instruments found.")
  end
end

M.find_duplicate_single_sample_instruments = M.list_duplicate_instruments_by_samples

-- Prompt user for instrument numbers to merge, then (stub) merge and reassign
function M.prompt_and_merge_instruments()
  local song = renoise.song()
  local function on_input(input)
    if not input or input == "" then
      renoise.app():show_message("No instruments specified.")
      return
    end
    -- Parse comma-separated list, allow hex (e.g., 0A) or decimal
    local indices = {}
    for num in input:gmatch("[^,%s]+") do
      local idx = tonumber(num, 16) or tonumber(num)
      if idx and idx >= 0 and idx < #song.instruments then
        table.insert(indices, idx + 1) -- convert to 1-based
      end
    end
    if #indices < 2 then
      renoise.app():show_message("No valid indices parsed from input: " .. tostring(input))
      return
    end
    -- Confirmation panel before merging
    local hex_indices = {}
    for _, idx in ipairs(indices) do table.insert(hex_indices, string.format("%02X", idx - 1)) end
    local confirm_msg = "Merge the following instruments?\n" .. table.concat(hex_indices, ", ")
    local vb = renoise.ViewBuilder()
    local dialog
    local function do_merge()
      -- Sort and deduplicate indices
      table.sort(indices)
      local unique = {}
      for _, v in ipairs(indices) do if not unique[#unique] or unique[#unique] ~= v then table.insert(unique, v) end end
      indices = unique
      -- Insert new instrument at the lowest index
      local insert_at = indices[1]
      local new_instr = song:insert_instrument_at(insert_at)
      new_instr.name = "Merged Instrument"
      -- Copy samples and settings from all selected instruments
      for _, idx in ipairs(indices) do
        local real_idx = idx >= insert_at and idx + 1 or idx
        local instr = song:instrument(real_idx)
        for s = 1, #instr.samples do
          local sample = instr:sample(s)
          local new_sample = new_instr:insert_sample_at(#new_instr.samples + 1)
          new_sample:copy_from(sample)
        end
      end
      -- Reassign all pattern instrument references to new_instr's index (0-based)
      local new_instr_val = insert_at - 1
      for seq = 1, #song.sequencer.pattern_sequence do
        local patt_idx = song.sequencer:pattern(seq)
        local patt = song:pattern(patt_idx)
        for t = 1, #song.tracks do
          local track = patt:track(t)
          for l = 1, patt.number_of_lines do
            local line = track:line(l)
            for nc = 1, #line.note_columns do
              local col = line:note_column(nc)
              -- Only remap instrument number if it matches a merged instrument and the note is not empty
              if col.note_value ~= 121 then -- 121 = EMPTY
                for _, old_idx in ipairs(indices) do
                  if col.instrument_value == (old_idx - 1) then
                    col.instrument_value = new_instr_val
                  end
                end
              end
            end
          end
        end
      end
      -- Delete old instruments (from highest to lowest, skip the new instrument)
      local to_delete = {}
      for i = #indices, 1, -1 do
        local del_idx = indices[i]
        if del_idx ~= insert_at then
          table.insert(to_delete, del_idx)
        end
      end
      -- Sort descending to avoid shifting issues
      table.sort(to_delete, function(a, b) return a > b end)
      for _, del_idx in ipairs(to_delete) do
        if del_idx > insert_at then
          song:delete_instrument_at(del_idx + 1)
        else
          song:delete_instrument_at(del_idx)
          insert_at = insert_at - 1 -- adjust new instrument index if deleted before it
        end
      end
      song.selected_instrument_index = insert_at
      local details = string.format(
        "Merged instruments into new instrument at index %02X.\nName: %s\nSamples: %d",
        insert_at - 1, new_instr.name, #new_instr.samples)
      renoise.app():show_message(details)
    end
    local dialog_content = vb:column {
      vb:text { text = confirm_msg },
      vb:row {
        vb:button {
          text = "Yes",
          notifier = function()
            if dialog then dialog:close() end
            do_merge()
          end
        },
        vb:button {
          text = "No",
          notifier = function()
            if dialog then dialog:close() end
          end
        }
      }
    }
    dialog = renoise.app():show_custom_dialog("Confirm Merge", dialog_content)
  end
  local vb = renoise.ViewBuilder()
  local input_field = vb:textfield { id = "input", value = "" }
  local dialog_content = vb:column {
    vb:text { text = "Enter instrument numbers to merge (comma-separated, 0-based, HEX or decimal):" },
    input_field,
    vb:button {
      text = "Merge",
      notifier = function()
        local input = input_field.value
        on_input(input)
      end
    }
  }
  renoise.app():show_custom_dialog("Merge Instruments", dialog_content)
end

local function remap_instruments(indices, new_instr_val, destructive)
  local song = renoise.song()
  -- Remap all pattern instrument references to new_instr_val
  for seq = 1, #song.sequencer.pattern_sequence do
    local patt_idx = song.sequencer:pattern(seq)
    local patt = song:pattern(patt_idx)
    for t = 1, #song.tracks do
      local track = patt:track(t)
      for l = 1, patt.number_of_lines do
        local line = track:line(l)
        for nc = 1, #line.note_columns do
          local col = line:note_column(nc)
          if col.note_value ~= 121 then -- 121 = EMPTY
            for _, old_idx in ipairs(indices) do
              if col.instrument_value == (old_idx - 1) then
                col.instrument_value = new_instr_val
              end
            end
          end
        end
      end
    end
  end
  if destructive then
    -- Delete old instruments (from highest to lowest, skip the new instrument)
    local insert_at = new_instr_val + 1
    local to_delete = {}
    for i = #indices, 1, -1 do
      local del_idx = indices[i]
      if del_idx ~= insert_at then
        table.insert(to_delete, del_idx)
      end
    end
    table.sort(to_delete, function(a, b) return a > b end)
    for _, del_idx in ipairs(to_delete) do
      song:delete_instrument_at(del_idx)
    end
    song.selected_instrument_index = insert_at
  end
end

-- Prompt user for instrument numbers to remap, then (stub) remap and delete or just remap
function M.prompt_and_remap_instruments()
  local song = renoise.song()
  local vb = renoise.ViewBuilder()
  local input_field = vb:textfield { id = "input", value = "" }
  local dialog
  local function on_remap_button(destructive)
    local input = input_field.value
    if not input or input == "" then
      renoise.app():show_message("No instruments specified.")
      return
    end
    local indices = {}
    for num in input:gmatch("[^,%s]+") do
      local idx = tonumber(num, 16) or tonumber(num)
      if idx and idx >= 0 and idx < #song.instruments then
        table.insert(indices, idx + 1) -- convert to 1-based
      end
    end
    if #indices < 2 then
      renoise.app():show_message("No valid indices parsed from input: " .. tostring(input))
      return
    end
    local new_instr_val = math.min(table.unpack(indices)) - 1
    remap_instruments(indices, new_instr_val, destructive)
    if dialog then dialog:close() end
  end
  local dialog_content = vb:column {
    vb:text { text = "Enter instrument numbers to remap (comma-separated, 0-based, HEX or decimal):" },
    input_field,
    vb:row {
      vb:button {
        text = "Remap Only",
        notifier = function() on_remap_button(false) end
      },
      vb:button {
        text = "Remap and Delete",
        notifier = function() on_remap_button(true) end
      },
      vb:button {
        text = "Cancel",
        notifier = function() if dialog then dialog:close() end end
      }
    }
  }
  dialog = renoise.app():show_custom_dialog("Remap Instruments", dialog_content)
end

function M.remap_selected_notes_to_this()
  local song = renoise.song()
  local target_instr = song.selected_instrument_index - 1 -- 0-based
  local notes = utils.get_selected_notes()
  if utils.DEBUG then
    local msg = ""
    for _, n in ipairs(notes) do
      msg = msg .. string.format("Pattern %d, Track %d, Line %d, Col %d: note_value=%s, instr=%02X\n", n.pattern, n.track, n.line, n.column, tostring(n.note_column.note_value), n.note_column.instrument_value)
    end
    utils.debug_messagebox(msg)
  else
    for _, n in ipairs(notes) do
      n.note_column.instrument_value = target_instr
    end
    renoise.app():show_status("Remapped selected notes to instrument " .. string.format("%02X", target_instr))
  end
end

function M.increase_velocity()
  local notes = utils.get_selected_notes()
  for _, n in ipairs(notes) do
    local v = n.note_column.volume_value
    if v == 255 then v = 127 end
    v = v + 10
    if v >= 127 then
      n.note_column.volume_value = 255
    else
      n.note_column.volume_value = math.max(0, v)
    end
  end
  renoise.app():show_status("Increased velocity of selected notes by 10")
end

function M.decrease_velocity()
  local notes = utils.get_selected_notes()
  for _, n in ipairs(notes) do
    local v = n.note_column.volume_value
    if v == 255 then v = 127 end
    v = v - 10
    if v >= 127 then
      n.note_column.volume_value = 255
    else
      n.note_column.volume_value = math.max(0, v)
    end
  end
  renoise.app():show_status("Decreased velocity of selected notes by 10")
end

function M.increase_velocity_sensitive()
  local notes = utils.get_selected_notes()
  for _, n in ipairs(notes) do
    local v = n.note_column.volume_value
    if v == 255 then v = 127 end
    v = v + 1
    if v >= 127 then
      n.note_column.volume_value = 255
    else
      n.note_column.volume_value = math.max(0, v)
    end
  end
  renoise.app():show_status("Increased velocity of selected notes by 1")
end

function M.decrease_velocity_sensitive()
  local notes = utils.get_selected_notes()
  for _, n in ipairs(notes) do
    local v = n.note_column.volume_value
    if v == 255 then v = 127 end
    v = v - 1
    if v >= 127 then
      n.note_column.volume_value = 255
    else
      n.note_column.volume_value = math.max(0, v)
    end
  end
  renoise.app():show_status("Decreased velocity of selected notes by 1")
end

function M.focus_automation_editor_for_selection()
  local song = renoise.song()
  local sel = song.selection_in_pattern
  if not sel then
    renoise.app():show_status("No selection in pattern editor.")
    return
  end
  -- Focus the automation editor (lower frame)
  renoise.app().window.active_lower_frame = renoise.ApplicationWindow.LOWER_FRAME_TRACK_AUTOMATION
  -- Set the selected track, pattern, and line to the start of the selection
  song.selected_track_index = sel.start_track or song.selected_track_index
  song.selected_pattern_index = song.selected_pattern_index -- already current pattern
  song.selected_line_index = sel.start_line or song.selected_line_index
  renoise.app():show_status("Focused automation editor for selection.")
end

function M.convert_automation_to_pattern()
  local song = renoise.song()
  local track_idx = song.selected_track_index
  local patt_idx = song.selected_pattern_index
  local pattern = song:pattern(patt_idx)
  local track = pattern:track(track_idx)
  local sel = song.selection_in_pattern
  if not sel then
    renoise.app():show_status("No selection in pattern editor.")
    return
  end
  -- Find the first automation in this pattern/track
  local automation = nil
  local device_idx, param_idx = nil, nil
  for d = 1, #song.tracks[track_idx].devices do
    local device = song.tracks[track_idx].devices[d]
    for p = 1, #device.parameters do
      local param = device:parameter(p)
      local auto = track:find_automation(param)
      if auto and #auto.points > 0 then
        automation = auto
        device_idx = d
        param_idx = p
        break
      end
    end
    if automation then break end
  end
  if not automation then
    renoise.app():show_status("No automation found in selected track/pattern.")
    return
  end
  local points = automation.points
  -- Interpolate automation for every line in the selection
  for line_idx = sel.start_line, sel.end_line do
    local value = 0
    if #points == 1 then
      value = points[1].value
    elseif line_idx <= points[1].time then
      value = points[1].value
    elseif line_idx >= points[#points].time then
      value = points[#points].value
    else
      for i = 1, #points - 1 do
        local pt1 = points[i]
        local pt2 = points[i + 1]
        if line_idx >= pt1.time and line_idx <= pt2.time then
          local t = (line_idx - pt1.time) / (pt2.time - pt1.time)
          value = pt1.value + (pt2.value - pt1.value) * t
          break
        end
      end
    end
    if value > 0 then
      local line = track:line(line_idx)
      -- Find a free effect column
      local fx_col = nil
      for ec = 1, #line.effect_columns do
        if line:effect_column(ec).is_empty then
          fx_col = line:effect_column(ec)
          break
        end
      end
      if fx_col then
        local scaled = math.floor(value * 255 + 0.5)
        fx_col.number_value = (device_idx - 1) * 16 + (param_idx - 1)
        fx_col.amount_value = scaled
      end
    end
  end
  -- Remove the automation curve after conversion
  if automation then
    track:delete_automation(automation.dest_parameter)
  end
  renoise.app():show_status("Interpolated automation to pattern effect columns and removed automation curve.")
end

return M 