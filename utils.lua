local M = {}

M.DEBUG = false

function M.debug_messagebox(msg)
  if M.DEBUG then
    renoise.app():show_message(msg)
  end
end

-- Returns a table of {pattern, track, line, column, note_column} for all selected notes (excluding instrument FF)
function M.get_selected_notes()
  local song = renoise.song()
  local sel = song.selection_in_pattern
  if not sel then return {} end
  local notes = {}
  local patt_idx = song.selected_pattern_index
  local start_track = sel.start_track or song.selected_track_index
  local end_track = sel.end_track or song.selected_track_index
  for track_idx = start_track, end_track do
    local patt = song:pattern(patt_idx)
    local track = patt:track(track_idx)
    for line_idx = sel.start_line, sel.end_line do
      local line = track:line(line_idx)
      for nc = 1, #line.note_columns do
        local col = line.note_columns[nc]
        if col.instrument_value ~= 255 and col.note_value ~= 121 then
          table.insert(notes, {
            pattern = patt_idx,
            track = track_idx,
            line = line_idx,
            column = nc,
            note_column = col
          })
        end
      end
    end
  end
  return notes
end

local function export_keybindings_md()
  local manifest_path = 'manifest.xml'
  local md_path = 'keybindings.md'
  local xml = io.open(manifest_path, 'r')
  if not xml then
    renoise.app():show_error('Could not open manifest.xml')
    return
  end
  local content = xml:read('*a')
  xml:close()

  local bindings = {}
  for path, invoke in content:gmatch('<Binding>%s*<Path>(.-)</Path>%s*<Invoke>(.-)</Invoke>%s*</Binding>') do
    table.insert(bindings, {path = path, invoke = invoke})
  end

  local md = {'# HexTools Keybindings\n'}
  table.insert(md, '| Path | Invoke |')
  table.insert(md, '|------|--------|')
  for _, b in ipairs(bindings) do
    table.insert(md, string.format('| %s | `%s` |', b.path, b.invoke))
  end

  local f = io.open(md_path, 'w')
  if not f then
    renoise.app():show_error('Could not write keybindings.md')
    return
  end
  f:write(table.concat(md, '\n'))
  f:close()
  renoise.app():show_status('Exported keybindings to keybindings.md')
end

M.export_keybindings_md = export_keybindings_md

local last_collapsed_pattern_idx = nil
local reorder_collapsed_tracks = false -- Reordering disabled (too slow); set to true to enable
local auto_collapse_before_jump = true -- Auto-collapse before jumping (default: true)
local pattern_collapsed_state = {} -- Track collapsed state per pattern
local last_jumped_track = nil -- Track the last track we jumped to via collapsed navigation
local last_jumped_track_was_empty = nil -- Track if the jumped track was empty when we jumped to it


-- Track colors (RGB 0-255)
local active_track_color = { 255, 100, 0 }  -- Orange for active/used tracks
local collapsed_track_color = { 100, 100, 100 }  -- Dark grey for collapsed tracks

-- Cache to restore original track colors when tint is removed
local previous_colors = {}

local function collapse_unused_tracks_in_pattern()
  local song = renoise.song()
  local patt_idx = song.selected_pattern_index
  local pattern = song:pattern(patt_idx)
  -- If pattern changed, always collapse unused tracks
  if last_collapsed_pattern_idx ~= patt_idx then
    -- Collapse unused tracks as before
    local expanded_indices = {}
    local collapsed_indices = {}
    for t = 1, #song.tracks do
      local track = song.tracks[t]
      if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
        local pattern_track = pattern:track(t)
        -- Fast O(1) test – Renoise caches this value
        local has_notes = not pattern_track.is_empty
        track.collapsed = not has_notes
        if has_notes then
          table.insert(expanded_indices, t)
        else
          table.insert(collapsed_indices, t)
        end
      end
    end
    -- Track that this pattern is now in collapsed state
    pattern_collapsed_state[patt_idx] = true
    -- Reorder: move all collapsed tracks to the right, preserving order, but only within sequencer tracks
    if reorder_collapsed_tracks then
      local last_seq_idx = 0
      for t = #song.tracks, 1, -1 do
        if song.tracks[t].type == renoise.Track.TRACK_TYPE_SEQUENCER then
          last_seq_idx = t
          break
        end
      end
      for i = #collapsed_indices, 1, -1 do
        local idx = collapsed_indices[i]
        if idx < last_seq_idx then
          song:swap_tracks_at(idx, last_seq_idx)
          last_seq_idx = last_seq_idx - 1
        end
      end
    end
    -- Apply colors to tracks based on their state
    for t = 1, #song.tracks do
      local track = song.tracks[t]
      if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
        if track.collapsed then
          -- Store original color if not already stored, then apply dark grey
          if not previous_colors[t] then
            previous_colors[t] = { track.color[1], track.color[2], track.color[3] }
          end
          track.color = collapsed_track_color
        else
          -- Store original color if not already stored, then apply orange
          if not previous_colors[t] then
            previous_colors[t] = { track.color[1], track.color[2], track.color[3] }
          end
          track.color = active_track_color
        end
      end
    end
    last_collapsed_pattern_idx = patt_idx
    renoise.app():show_status("Collapsed unused tracks in current pattern and moved them to the right.")
    return
  end
  -- Otherwise, toggle as before
  local any_collapsed = false
  for t = 1, #song.tracks do
    local track = song.tracks[t]
    if track.type == renoise.Track.TRACK_TYPE_SEQUENCER and track.collapsed then
      any_collapsed = true
      break
    end
  end
  if any_collapsed then
    -- Collapse unused tracks as before
    local expanded_indices = {}
    local collapsed_indices = {}
    for t = 1, #song.tracks do
      local track = song.tracks[t]
      if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
        local pattern_track = pattern:track(t)
        -- Fast O(1) test – Renoise caches this value
        local has_notes = not pattern_track.is_empty
        track.collapsed = false
        if has_notes then
          table.insert(expanded_indices, t)
        else
          table.insert(collapsed_indices, t)
        end
      end
    end
    -- Reorder: move all collapsed tracks to the right, preserving order, but only within sequencer tracks
    if reorder_collapsed_tracks then
      local last_seq_idx = 0
      for t = #song.tracks, 1, -1 do
        if song.tracks[t].type == renoise.Track.TRACK_TYPE_SEQUENCER then
          last_seq_idx = t
          break
        end
      end
      for i = #collapsed_indices, 1, -1 do
        local idx = collapsed_indices[i]
        if idx < last_seq_idx then
          song:swap_tracks_at(idx, last_seq_idx)
          last_seq_idx = last_seq_idx - 1
        end
      end
    end
    -- Apply colors to tracks based on their state when expanding
    for t = 1, #song.tracks do
      local track = song.tracks[t]
      if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
        local pattern_track = pattern:track(t)
        local has_notes = not pattern_track.is_empty
        if has_notes then
          -- Store original color if not already stored, then apply orange
          if not previous_colors[t] then
            previous_colors[t] = { track.color[1], track.color[2], track.color[3] }
          end
          track.color = active_track_color
        else
          -- Store original color if not already stored, then apply dark grey
          if not previous_colors[t] then
            previous_colors[t] = { track.color[1], track.color[2], track.color[3] }
          end
          track.color = collapsed_track_color
        end
      end
    end
    -- Track that this pattern is now in expanded state
    pattern_collapsed_state[patt_idx] = false
    renoise.app():show_status("Expanded all tracks.")
  else
    -- Collapse unused tracks as before
    local expanded_indices = {}
    local collapsed_indices = {}
    for t = 1, #song.tracks do
      local track = song.tracks[t]
      if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
        local pattern_track = pattern:track(t)
        -- Fast O(1) test – Renoise caches this value
        local has_notes = not pattern_track.is_empty
        track.collapsed = not has_notes
        if has_notes then
          table.insert(expanded_indices, t)
        else
          table.insert(collapsed_indices, t)
        end
      end
    end
    -- Reorder: move all collapsed tracks to the right, preserving order, but only within sequencer tracks
    if reorder_collapsed_tracks then
      local last_seq_idx = 0
      for t = #song.tracks, 1, -1 do
        if song.tracks[t].type == renoise.Track.TRACK_TYPE_SEQUENCER then
          last_seq_idx = t
          break
        end
      end
      for i = #collapsed_indices, 1, -1 do
        local idx = collapsed_indices[i]
        if idx < last_seq_idx then
          song:swap_tracks_at(idx, last_seq_idx)
          last_seq_idx = last_seq_idx - 1
        end
      end
    end
    -- Apply colors to tracks based on their state
    for t = 1, #song.tracks do
      local track = song.tracks[t]
      if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
        if track.collapsed then
          -- Store original color if not already stored, then apply dark grey
          if not previous_colors[t] then
            previous_colors[t] = { track.color[1], track.color[2], track.color[3] }
          end
          track.color = collapsed_track_color
        else
          -- Store original color if not already stored, then apply orange
          if not previous_colors[t] then
            previous_colors[t] = { track.color[1], track.color[2], track.color[3] }
          end
          track.color = active_track_color
        end
      end
    end
    -- Track that this pattern is now in collapsed state
    pattern_collapsed_state[patt_idx] = true
    renoise.app():show_status("Collapsed unused tracks in current pattern and moved them to the right.")
  end
  last_collapsed_pattern_idx = patt_idx
end

M.collapse_unused_tracks_in_pattern = collapse_unused_tracks_in_pattern

-- Check if current pattern is in collapsed state
local function is_pattern_collapsed()
  local song = renoise.song()
  local patt_idx = song.selected_pattern_index
  return pattern_collapsed_state[patt_idx] == true
end

-- Check if a track has notes in the current pattern
local function track_has_notes(track_idx)
  local song = renoise.song()
  local patt_idx = song.selected_pattern_index
  local pattern = song:pattern(patt_idx)
  local track = pattern:track(track_idx)
  return not track.is_empty
end

-- Handle leaving a jumped track (collapse if still empty, color orange if has notes)
local function handle_leaving_jumped_track()
  if last_jumped_track then
    local song = renoise.song()
    local track = song.tracks[last_jumped_track]
    
    renoise.app():show_status("DEBUG: Handling leaving track " .. last_jumped_track)
    
    if track and track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
      local has_notes_now = track_has_notes(last_jumped_track)
      
      renoise.app():show_status("DEBUG: Track " .. last_jumped_track .. " has notes: " .. tostring(has_notes_now))
      
      if has_notes_now then
        -- Track now has notes, color it orange like other active tracks
        track.color = active_track_color
        renoise.app():show_status("Track " .. last_jumped_track .. " has notes, keeping uncollapsed")
      else
        -- Track is still empty, collapse it and color it grey
        track.collapsed = true
        track.color = collapsed_track_color
        renoise.app():show_status("Track " .. last_jumped_track .. " is empty, collapsing")
      end
    else
      renoise.app():show_status("DEBUG: Track " .. last_jumped_track .. " is not a sequencer track or doesn't exist")
    end
    
    -- Clear the tracking
    last_jumped_track = nil
    last_jumped_track_was_empty = nil
  else
    renoise.app():show_status("DEBUG: No last_jumped_track to handle")
  end
end

-- Jump to next non-collapsed track
local function jump_to_next_track()
  local song = renoise.song()
  
  -- Auto-collapse before jumping if enabled and pattern is not collapsed
  if auto_collapse_before_jump and not is_pattern_collapsed() then
    collapse_unused_tracks_in_pattern()
  end
  
  local current_track = song.selected_track_index
  local total_tracks = #song.tracks
  
  -- Handle leaving previous jumped track BEFORE we change selection
  renoise.app():show_status("DEBUG: last_jumped_track=" .. tostring(last_jumped_track) .. ", current_track=" .. current_track)
  if last_jumped_track and last_jumped_track == current_track then
    renoise.app():show_status("DEBUG: Calling handle_leaving_jumped_track")
    handle_leaving_jumped_track()
  else
    renoise.app():show_status("DEBUG: Not calling handle_leaving_jumped_track")
  end
  
  -- Start from the next track
  for i = current_track + 1, total_tracks do
    local track = song.tracks[i]
    if track.type == renoise.Track.TRACK_TYPE_SEQUENCER and not track.collapsed then
      song.selected_track_index = i
      
      -- Reset pattern collapsed state when jumping to uncollapsed track
      local patt_idx = song.selected_pattern_index
      pattern_collapsed_state[patt_idx] = false
      
      renoise.app():show_status("Jumped to next track: " .. i)
      return
    end
  end
  
  -- If no next track found, wrap around to the beginning
  for i = 1, current_track - 1 do
    local track = song.tracks[i]
    if track.type == renoise.Track.TRACK_TYPE_SEQUENCER and not track.collapsed then
      song.selected_track_index = i
      
      -- Reset pattern collapsed state when jumping to uncollapsed track
      local patt_idx = song.selected_pattern_index
      pattern_collapsed_state[patt_idx] = false
      
      renoise.app():show_status("Jumped to next track (wrapped): " .. i)
      return
    end
  end
  
  renoise.app():show_status("No other non-collapsed tracks found")
end

-- Jump to previous non-collapsed track
local function jump_to_previous_track()
  local song = renoise.song()
  
  -- Auto-collapse before jumping if enabled and pattern is not collapsed
  if auto_collapse_before_jump and not is_pattern_collapsed() then
    collapse_unused_tracks_in_pattern()
  end
  
  local current_track = song.selected_track_index
  local total_tracks = #song.tracks
  
  -- Handle leaving previous jumped track BEFORE we change selection
  renoise.app():show_status("DEBUG: last_jumped_track=" .. tostring(last_jumped_track) .. ", current_track=" .. current_track)
  if last_jumped_track and last_jumped_track == current_track then
    renoise.app():show_status("DEBUG: Calling handle_leaving_jumped_track")
    handle_leaving_jumped_track()
  else
    renoise.app():show_status("DEBUG: Not calling handle_leaving_jumped_track")
  end
  
  -- Start from the previous track
  for i = current_track - 1, 1, -1 do
    local track = song.tracks[i]
    if track.type == renoise.Track.TRACK_TYPE_SEQUENCER and not track.collapsed then
      song.selected_track_index = i
      
      -- Reset pattern collapsed state when jumping to uncollapsed track
      local patt_idx = song.selected_pattern_index
      pattern_collapsed_state[patt_idx] = false
      
      renoise.app():show_status("Jumped to previous track: " .. i)
      return
    end
  end
  
  -- If no previous track found, wrap around to the end
  for i = total_tracks, current_track + 1, -1 do
    local track = song.tracks[i]
    if track.type == renoise.Track.TRACK_TYPE_SEQUENCER and not track.collapsed then
      song.selected_track_index = i
      
      -- Reset pattern collapsed state when jumping to uncollapsed track
      local patt_idx = song.selected_pattern_index
      pattern_collapsed_state[patt_idx] = false
      
      renoise.app():show_status("Jumped to previous track (wrapped): " .. i)
      return
    end
  end
  
  renoise.app():show_status("No other non-collapsed tracks found")
end

M.jump_to_next_track = jump_to_next_track
M.jump_to_previous_track = jump_to_previous_track

-- Jump to next collapsed track (uncollapse target track)
local function jump_to_next_collapsed_track()
  local song = renoise.song()
  local current_track = song.selected_track_index
  local total_tracks = #song.tracks
  
  -- Start from the next track
  for i = current_track + 1, total_tracks do
    local track = song.tracks[i]
    if track.type == renoise.Track.TRACK_TYPE_SEQUENCER and track.collapsed then
      -- Uncollapse the target track
      track.collapsed = false
      -- Store original color if not already stored, then tint white
      if not previous_colors[i] then
        previous_colors[i] = { track.color[1], track.color[2], track.color[3] }
      end
      track.color = { 255, 255, 255 }  -- White
      song.selected_track_index = i
      
      -- Track this jumped track and whether it was empty
      last_jumped_track = i
      last_jumped_track_was_empty = track_has_notes(i)
      
      -- Update pattern collapsed state since we just uncollapsed a track
      local patt_idx = song.selected_pattern_index
      pattern_collapsed_state[patt_idx] = false
      
      renoise.app():show_status("DEBUG: Set last_jumped_track=" .. i .. ", was_empty=" .. tostring(last_jumped_track_was_empty))
      renoise.app():show_status("Jumped to next collapsed track: " .. i)
      return
    end
  end
  
  -- If no next collapsed track found, wrap around to the beginning
  for i = 1, current_track - 1 do
    local track = song.tracks[i]
    if track.type == renoise.Track.TRACK_TYPE_SEQUENCER and track.collapsed then
      -- Uncollapse the target track
      track.collapsed = false
      -- Store original color if not already stored, then tint white
      if not previous_colors[i] then
        previous_colors[i] = { track.color[1], track.color[2], track.color[3] }
      end
      track.color = { 255, 255, 255 }  -- White
      song.selected_track_index = i
      
      -- Track this jumped track and whether it was empty
      last_jumped_track = i
      last_jumped_track_was_empty = track_has_notes(i)
      
      renoise.app():show_status("DEBUG: Set last_jumped_track=" .. i .. ", was_empty=" .. tostring(last_jumped_track_was_empty))
      renoise.app():show_status("Jumped to next collapsed track (wrapped): " .. i)
      return
    end
  end
  
  renoise.app():show_status("No other collapsed tracks found")
end

-- Jump to previous collapsed track (uncollapse target track)
local function jump_to_previous_collapsed_track()
  local song = renoise.song()
  local current_track = song.selected_track_index
  local total_tracks = #song.tracks
  
  -- Start from the previous track
  for i = current_track - 1, 1, -1 do
    local track = song.tracks[i]
    if track.type == renoise.Track.TRACK_TYPE_SEQUENCER and track.collapsed then
      -- Uncollapse the target track
      track.collapsed = false
      -- Store original color if not already stored, then tint white
      if not previous_colors[i] then
        previous_colors[i] = { track.color[1], track.color[2], track.color[3] }
      end
      track.color = { 255, 255, 255 }  -- White
      song.selected_track_index = i
      
      -- Track this jumped track and whether it was empty
      last_jumped_track = i
      last_jumped_track_was_empty = track_has_notes(i)
      
      renoise.app():show_status("DEBUG: Set last_jumped_track=" .. i .. ", was_empty=" .. tostring(last_jumped_track_was_empty))
      renoise.app():show_status("Jumped to previous collapsed track: " .. i)
      return
    end
  end
  
  -- If no previous collapsed track found, wrap around to the end
  for i = total_tracks, current_track + 1, -1 do
    local track = song.tracks[i]
    if track.type == renoise.Track.TRACK_TYPE_SEQUENCER and track.collapsed then
      -- Uncollapse the target track
      track.collapsed = false
      -- Store original color if not already stored, then tint white
      if not previous_colors[i] then
        previous_colors[i] = { track.color[1], track.color[2], track.color[3] }
      end
      track.color = { 255, 255, 255 }  -- White
      song.selected_track_index = i
      
      -- Track this jumped track and whether it was empty
      last_jumped_track = i
      last_jumped_track_was_empty = track_has_notes(i)
      
      renoise.app():show_status("DEBUG: Set last_jumped_track=" .. i .. ", was_empty=" .. tostring(last_jumped_track_was_empty))
      renoise.app():show_status("Jumped to previous collapsed track (wrapped): " .. i)
      return
    end
  end
  
  renoise.app():show_status("No other collapsed tracks found")
end

-- Toggle auto-collapse before jump option
local function toggle_auto_collapse_before_jump()
  auto_collapse_before_jump = not auto_collapse_before_jump
  local status = auto_collapse_before_jump and "enabled" or "disabled"
  renoise.app():show_status("Auto-collapse before jump: " .. status)
end

M.toggle_auto_collapse_before_jump = toggle_auto_collapse_before_jump
M.is_pattern_collapsed = is_pattern_collapsed
M.jump_to_next_collapsed_track = jump_to_next_collapsed_track
M.jump_to_previous_collapsed_track = jump_to_previous_collapsed_track
M.handle_leaving_jumped_track = handle_leaving_jumped_track

return M 