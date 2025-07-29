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

-- Helper to check if two DeviceParameter objects refer to the same parameter
local function is_same_parameter(param1, param2)
  if not param1 or not param2 then return false end
  -- Compare parent device and index
  return (param1.device == param2.device) and (param1.index == param2.index)
end

function M.convert_automation_to_pattern()
  -- Debug: Function called
  if utils.DEBUG then
    utils.debug_messagebox("convert_automation_to_pattern() called")
  end
  
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
  local param = nil
  
  -- Debug: Show track and device info
  if utils.DEBUG then
    local debug_msg = string.format("Searching for automation in track %d, pattern %d\n", track_idx, patt_idx)
    debug_msg = debug_msg .. string.format("Track has %d devices\n", #song.tracks[track_idx].devices)
    
    -- Check if track has any automation at all
    local all_automation = track.automation
    debug_msg = debug_msg .. string.format("Track has %d automation envelopes\n", #all_automation)
    for i, auto in ipairs(all_automation) do
      debug_msg = debug_msg .. string.format("Automation %d: %s, points=%d\n", i, auto.dest_parameter.name, #auto.points)
    end
    
    for d = 1, #song.tracks[track_idx].devices do
      local device = song.tracks[track_idx].devices[d]
      debug_msg = debug_msg .. string.format("Device %d: %s (%d parameters)\n", d, device.name, #device.parameters)
      for p = 1, #device.parameters do
        local test_param = device:parameter(p)
        local auto = track:find_automation(test_param)
        debug_msg = debug_msg .. string.format("  Param %d: %s, automation=%s\n", p, test_param.name, auto and "found" or "none")
        if auto then
          debug_msg = debug_msg .. string.format("    Points: %d\n", #auto.points)
        end
      end
    end
    utils.debug_messagebox(debug_msg)
  end
  
  for d = 1, #song.tracks[track_idx].devices do
    local device = song.tracks[track_idx].devices[d]
    for p = 1, #device.parameters do
      local test_param = device:parameter(p)
      local auto = track:find_automation(test_param)
      if auto and #auto.points > 0 then
        automation = auto
        device_idx = d
        param_idx = p
        param = test_param
        break
      end
    end
    if automation then break end
  end
  if not automation then
    renoise.app():show_status("No automation found in this pattern/track.")
    return
  end
  local points = automation.points
  if #points == 0 then
    renoise.app():show_status("No automation points found.")
    return
  end
  
  -- Debug: Show automation info
  if utils.DEBUG then
    local debug_msg = string.format("Found automation: device=%d, param=%d, points=%d\n", device_idx, param_idx, #points)
    for i, pt in ipairs(points) do
      debug_msg = debug_msg .. string.format("Point %d: line=%s, time=%s, value=%.3f\n", 
        i, tostring(pt.line), tostring(pt.time), pt.value)
    end
    utils.debug_messagebox(debug_msg)
  end
  -- Determine if this is track volume automation
  local is_track_volume = false
  -- Find the device and parameter index for prefx_volume by name
  local prefx_device_idx, prefx_param_idx = nil, nil
  local prefx_param_name = song.tracks[track_idx].prefx_volume.name
  for d = 1, #song.tracks[track_idx].devices do
    local device = song.tracks[track_idx].devices[d]
    for p = 1, #device.parameters do
      if device:parameter(p).name == prefx_param_name then
        prefx_device_idx = d
        prefx_param_idx = p
        break
      end
    end
    if prefx_device_idx then break end
  end
  if device_idx and param_idx and prefx_device_idx and prefx_param_idx then
    if device_idx == prefx_device_idx and param_idx == prefx_param_idx then
      is_track_volume = true
    end
  end
  -- Interpolate and write values for each line in the selection
  for line_idx = sel.start_line, sel.end_line do
    local value = 0
    if #points == 1 then
      value = points[1].value
    elseif line_idx <= (points[1].line or points[1].time or 0) then
      value = points[1].value
    elseif line_idx >= (points[#points].line or points[#points].time or 0) then
      value = points[#points].value
    else
      for i = 1, #points - 1 do
        local pt1 = points[i]
        local pt2 = points[i + 1]
        local pt1_line = pt1.line or pt1.time or 0
        local pt2_line = pt2.line or pt2.time or 0
        
        if line_idx == pt1_line then
          value = pt1.value
          break
        elseif line_idx > pt1_line and line_idx < pt2_line then
          local t = (line_idx - pt1_line) / (pt2_line - pt1_line)
          value = pt1.value + (pt2.value - pt1.value) * t
          break
        elseif line_idx == pt2_line then
          value = pt2.value
          break
        end
      end
    end
    
    local line = track:line(line_idx)
    
    if is_track_volume then
      local last_nonzero = false
      for nc = 1, #line.note_columns do
        local col = line.note_columns[nc]
        local v = math.floor(value * 127 + 0.5)
        if v > 0 and v < 127 then
          col.volume_value = v
          last_nonzero = true
        elseif v == 0 and last_nonzero then
          col.volume_value = 0
          last_nonzero = false
        else
          col.volume_value = 255
        end
      end
    else
      -- Write to a free effect column
      local fx_col = nil
      for ec = 1, #line.effect_columns do
        if line:effect_column(ec).is_empty then
          fx_col = line:effect_column(ec)
          break
        end
      end
      if fx_col then
        -- Encode device/parameter and value (0-255)
        local value_255 = math.floor(value * 255 + 0.5)
        -- Encode device and parameter into a single effect number
        local encoded_num = (device_idx - 1) * 16 + (param_idx - 1)
        fx_col.number_string = string.format("%02X", encoded_num)
        fx_col.amount_value = value_255
        
        -- Debug: Show what we're writing
        if utils.DEBUG then
          local debug_msg = string.format("Line %d: value=%.3f, encoded=%02X, amount=%d\n", 
            line_idx, value, encoded_num, value_255)
          utils.debug_messagebox(debug_msg)
        end
      end
    end
  end
  -- Remove the automation curve after conversion
  if automation then
    track:delete_automation(automation.dest_parameter)
  end
  renoise.app():show_status("Interpolated automation to pattern and removed automation curve.")
end

-- Utility: removes perfectly collinear interior points to minimise automation density
local function simplify_points(points, eps)
  eps = eps or 1e-7
  if #points <= 2 then return points end
  local simplified = {points[1]}
  for i = 2, #points - 1 do
    local prev = simplified[#simplified]
    local curr = points[i]
    local nxt  = points[i + 1]
    -- Guard against division-by-zero when two points share the same line
    if nxt.line == prev.line then
      table.insert(simplified, curr)
    else
      local t = (curr.line - prev.line) / (nxt.line - prev.line)
      local interp = prev.value + (nxt.value - prev.value) * t
      if math.abs(curr.value - interp) > eps then
        table.insert(simplified, curr)
      end
    end
  end
  table.insert(simplified, points[#points])
  return simplified
end

function M.convert_pattern_to_automation()
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
  -- Find the first effect column with a device/parameter mapping in the selection
  local device_idx, param_idx = nil, nil
  for line_idx = sel.start_line, sel.end_line do
    local line = track:line(line_idx)
    for ec = 1, #line.effect_columns do
      local fx_col = line:effect_column(ec)
      if not fx_col.is_empty then
        local num = fx_col.number_value
        device_idx = math.floor(num / 16) + 1
        param_idx  = (num % 16) + 1
        break
      end
    end
    if device_idx then break end
  end
  if not device_idx or not param_idx then
    renoise.app():show_status("No effect column parameter found in selection.")
    return
  end

  local device = song.tracks[track_idx].devices[device_idx]
  local param  = device:parameter(param_idx)
  local is_track_volume = (param.name == song.tracks[track_idx].prefx_volume.name)

  -- (Re)create automation envelope
  local auto = track:find_automation(param) or track:create_automation(param)
  auto:clear()

  if is_track_volume then
    ------------------------------------------------------------------
    -- Track-volume branch: derive value from note-column volume (0-127)
    ------------------------------------------------------------------
    local points = {}
    -- Default starting value is full volume (1.0)
    local last_val = nil

    for line_idx = sel.start_line, sel.end_line do
      local line = track:line(line_idx)
      local max_vol, has_zero = nil, false
      for nc = 1, #line.note_columns do
        local v = line:note_column(nc).volume_value
        if v == 0 then
          has_zero = true
        elseif v > 0 and v < 127 then
          max_vol = max_vol and math.max(max_vol, v) or v
        end
      end
      local value
      if max_vol then
        -- Treat near-zero volumes (≤ 02 hex) as silence (0.0)
        if max_vol <= 2 then
          value = 0.0
        else
          value = max_vol / 127
        end
      elseif has_zero then
        value = 0.0
      else
        value = last_val or 1.0 -- treat "empty" as no change; default 1.0 at start
      end

      -- Always emit the very first point so the envelope has a start anchor
      if line_idx == sel.start_line or value ~= last_val then
        table.insert(points, { line = line_idx, value = value })
        last_val = value
      end

      -- Nullify the pattern volume field for this line (set to empty)
      for nc = 1, #line.note_columns do
        line:note_column(nc).volume_value = 255 -- 255 represents "no volume" in Renoise API
      end
    end
    for _, pt in ipairs(simplify_points(points, 0.02)) do
      auto:add_point_at(pt.line, pt.value)
    end
  else
    ------------------------------------------------------------------
    -- Generic parameter branch: gather values from matching FX columns
    ------------------------------------------------------------------
    local points = {}
    for line_idx = sel.start_line, sel.end_line do
      local line = track:line(line_idx)
      for ec = 1, #line.effect_columns do
        local fx_col = line:effect_column(ec)
        if not fx_col.is_empty then
          local num = fx_col.number_value
          local d_idx = math.floor(num / 16) + 1
          local p_idx = (num % 16) + 1
          if d_idx == device_idx and p_idx == param_idx then
            table.insert(points, {
              line  = line_idx,
              value = fx_col.amount_value / 255
            })
            fx_col:clear() -- tidy up pattern after conversion
            break
          end
        end
      end
    end
    for _, pt in ipairs(simplify_points(points)) do
      auto:add_point_at(pt.line, pt.value)
    end
  end

  renoise.app():show_status("Converted pattern effect columns to automation curve and cleared effect columns.")
end

return M 