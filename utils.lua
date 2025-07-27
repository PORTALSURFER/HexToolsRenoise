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
    renoise.app():show_status("Collapsed unused tracks in current pattern and moved them to the right.")
  end
  last_collapsed_pattern_idx = patt_idx
end

M.collapse_unused_tracks_in_pattern = collapse_unused_tracks_in_pattern

return M 