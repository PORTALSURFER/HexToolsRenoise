local M = {}

M.DEBUG = true

function M.debug_messagebox(msg)
  if M.DEBUG then
    renoise.app():show_message(msg)
  end
end

-- Return a table of selected notes {pattern, track, line, column, note_column}
function M.get_selected_notes()
  local song = renoise.song()
  local sel  = song.selection_in_pattern
  if not sel then return {} end

  local notes       = {}
  local patt_idx    = song.selected_pattern_index
  local start_track = sel.start_track or song.selected_track_index
  local end_track   = sel.end_track   or song.selected_track_index

  for track_idx = start_track, end_track do
    local patt  = song:pattern(patt_idx)
    local track = patt:track(track_idx)
    for line_idx = sel.start_line, sel.end_line do
      local line = track:line(line_idx)
      for nc = 1, #line.note_columns do
        local col = line.note_columns[nc]
        if col.instrument_value ~= 255 and col.note_value ~= 121 then
          table.insert(notes, {
            pattern     = patt_idx,
            track       = track_idx,
            line        = line_idx,
            column      = nc,
            note_column = col
          })
        end
      end
    end
  end
  return notes
end

-- Export key‑bindings from manifest.xml → keybindings.md
local function export_keybindings_md()
  local xml = io.open("manifest.xml", "r")
  if not xml then
    renoise.app():show_error("Could not open manifest.xml")
    return
  end
  local content = xml:read("*a"); xml:close()

  local bindings = {}
  for path, invoke in content:gmatch(
        "<Binding>%s*<Path>(.-)</Path>%s*<Invoke>(.-)</Invoke>%s*</Binding>") do
    table.insert(bindings, {path = path, invoke = invoke})
  end

  local md = {
    "# HexTools Keybindings",
    "| Path | Invoke |",
    "|------|--------|"
  }
  for _, b in ipairs(bindings) do
    table.insert(md, ("| %s | `%s` |"):format(b.path, b.invoke))
  end

  local f = io.open("keybindings.md", "w")
  if not f then
    renoise.app():show_error("Could not write keybindings.md")
    return
  end
  f:write(table.concat(md, "\n")); f:close()
  renoise.app():show_status("Exported keybindings to keybindings.md")
end
M.export_keybindings_md = export_keybindings_md

----------------------------------------------------------------------
-- state
----------------------------------------------------------------------
local last_collapsed_pattern_idx   = nil
local reorder_null_tracks          = false
local auto_collapse_before_jump    = true
local pattern_collapsed_state      = {}
local last_jumped_track            = nil
local last_jumped_track_was_null   = nil
local auto_collapse_on_focus_loss  = true

-- track colors and states
local active_track_color     = {85, 128, 170}  -- blue for active tracks
local null_track_color       = {100, 100, 100} -- gray for null/empty tracks
local focused_track_color    = {174, 70, 90}   -- red tint for focused tracks
local previous_colors        = {}

----------------------------------------------------------------------
-- track state helpers
----------------------------------------------------------------------
local function is_track_active(track_idx)
  local song = renoise.song()
  return not song:pattern(song.selected_pattern_index):track(track_idx).is_empty
end

local function is_track_null(track_idx)
  return not is_track_active(track_idx)
end

local function is_track_collapsed(track_idx)
  local song = renoise.song()
  return song.tracks[track_idx].collapsed
end

local function set_track_state(track_idx, is_active)
  local song = renoise.song()
  local track = song.tracks[track_idx]
  
  if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
    track.collapsed = not is_active
    track.color = is_active and active_track_color or null_track_color
  end
end

local function set_track_focused(track_idx)
  local song = renoise.song()
  local track = song.tracks[track_idx]
  
  if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
    track.collapsed = false
    if not previous_colors[track_idx] then
      previous_colors[track_idx] = {track.color[1], track.color[2], track.color[3]}
    end
    track.color = focused_track_color
  end
end

----------------------------------------------------------------------
-- collapse / expand helpers
----------------------------------------------------------------------
local function collapse_null_tracks_in_pattern()
  local song      = renoise.song()
  local patt_idx  = song.selected_pattern_index
  local pattern   = song:pattern(patt_idx)

  -- (1) first time on this pattern  → collapse null tracks
  -- (2) subsequent call             → toggle
  local initial_call = (last_collapsed_pattern_idx ~= patt_idx)

  local function apply_state(expand)
    local null_track_indices, active_track_indices = {}, {}
    for t = 1, #song.tracks do
      local track = song.tracks[t]
      if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
        local is_active = is_track_active(t)
        set_track_state(t, expand and true or is_active)
        
        if is_active then
          table.insert(active_track_indices, t)
        else
          table.insert(null_track_indices, t)
        end
      end
    end

    if reorder_null_tracks then
      local last_seq = 0
      for t = #song.tracks, 1, -1 do
        if song.tracks[t].type == renoise.Track.TRACK_TYPE_SEQUENCER then
          last_seq = t; break
        end
      end
      for i = #null_track_indices, 1, -1 do
        local idx = null_track_indices[i]
        if idx < last_seq then
          song:swap_tracks_at(idx, last_seq); last_seq = last_seq - 1
        end
      end
    end
    pattern_collapsed_state[patt_idx] = not expand
  end

  if initial_call then
    apply_state(false)
    renoise.app():show_status("Collapsed null tracks.")
  else
    local currently_collapsed = pattern_collapsed_state[patt_idx]
    apply_state(currently_collapsed) -- toggle
    renoise.app():show_status(currently_collapsed and "Expanded all tracks."
                                              or  "Collapsed null tracks.")
  end
  last_collapsed_pattern_idx = patt_idx
end
M.collapse_unused_tracks_in_pattern = collapse_null_tracks_in_pattern

local function is_pattern_collapsed()
  return pattern_collapsed_state[renoise.song().selected_pattern_index] == true
end

----------------------------------------------------------------------
-- track focus management
----------------------------------------------------------------------
local function handle_leaving_focused_track()
  if not last_jumped_track then return end

  local song  = renoise.song()
  local track = song.tracks[last_jumped_track]
  if track and track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
    if is_track_active(last_jumped_track) then
      track.color = active_track_color
    else
      set_track_state(last_jumped_track, false) -- collapse as null track
    end
  end
  last_jumped_track, last_jumped_track_was_null = nil, nil
end
M.handle_leaving_jumped_track = handle_leaving_focused_track

----------------------------------------------------------------------
-- active track navigation
----------------------------------------------------------------------
local function jump_to_next_active_track()
  local song = renoise.song()
  if auto_collapse_before_jump and not is_pattern_collapsed() then
    collapse_null_tracks_in_pattern()
  end

  local cur  = song.selected_track_index
  local tot  = #song.tracks

  if last_jumped_track and last_jumped_track == cur then
    handle_leaving_focused_track()
  end

  for i = cur + 1, tot do
    local tr = song.tracks[i]
    if tr.type == renoise.Track.TRACK_TYPE_SEQUENCER and not is_track_collapsed(i) then
      song.selected_track_index = i
      pattern_collapsed_state[song.selected_pattern_index] = false
      return
    end
  end
  for i = 1, cur - 1 do
    local tr = song.tracks[i]
    if tr.type == renoise.Track.TRACK_TYPE_SEQUENCER and not is_track_collapsed(i) then
      song.selected_track_index = i
      pattern_collapsed_state[song.selected_pattern_index] = false
      return
    end
  end
end

local function jump_to_previous_active_track()
  local song = renoise.song()
  if auto_collapse_before_jump and not is_pattern_collapsed() then
    collapse_null_tracks_in_pattern()
  end

  local cur = song.selected_track_index
  local tot = #song.tracks

  if last_jumped_track and last_jumped_track == cur then
    handle_leaving_focused_track()
  end

  for i = cur - 1, 1, -1 do
    local tr = song.tracks[i]
    if tr.type == renoise.Track.TRACK_TYPE_SEQUENCER and not is_track_collapsed(i) then
      song.selected_track_index = i
      pattern_collapsed_state[song.selected_pattern_index] = false
      return
    end
  end
  for i = tot, cur + 1, -1 do
    local tr = song.tracks[i]
    if tr.type == renoise.Track.TRACK_TYPE_SEQUENCER and not is_track_collapsed(i) then
      song.selected_track_index = i
      pattern_collapsed_state[song.selected_pattern_index] = false
      return
    end
  end
end
M.jump_to_next_track     = jump_to_next_active_track
M.jump_to_previous_track = jump_to_previous_active_track

----------------------------------------------------------------------
-- null track navigation
----------------------------------------------------------------------
local function focus_and_select_track(track_idx)
  local song  = renoise.song()
  local track = song.tracks[track_idx]

  set_track_focused(track_idx)
  song.selected_track_index = track_idx

  last_jumped_track         = track_idx
  last_jumped_track_was_null = is_track_null(track_idx)
  pattern_collapsed_state[song.selected_pattern_index] = false
end

local function jump_to_next_null_track()
  local song = renoise.song()
  if auto_collapse_before_jump and not is_pattern_collapsed() then
    collapse_null_tracks_in_pattern()
  end

  local cur  = song.selected_track_index
  local tot  = #song.tracks

  if last_jumped_track and last_jumped_track == cur then
    handle_leaving_focused_track()
  end

  for i = cur + 1, tot do
    local tr = song.tracks[i]
    if tr.type == renoise.Track.TRACK_TYPE_SEQUENCER and is_track_collapsed(i) then
      focus_and_select_track(i); return
    end
  end
  for i = 1, cur - 1 do
    local tr = song.tracks[i]
    if tr.type == renoise.Track.TRACK_TYPE_SEQUENCER and is_track_collapsed(i) then
      focus_and_select_track(i); return
    end
  end
  renoise.app():show_status("No other null tracks found")
end

local function jump_to_previous_null_track()
  local song = renoise.song()
  if auto_collapse_before_jump and not is_pattern_collapsed() then
    collapse_null_tracks_in_pattern()
  end

  local cur  = song.selected_track_index
  local tot  = #song.tracks

  if last_jumped_track and last_jumped_track == cur then
    handle_leaving_focused_track()
  end

  for i = cur - 1, 1, -1 do
    local tr = song.tracks[i]
    if tr.type == renoise.Track.TRACK_TYPE_SEQUENCER and is_track_collapsed(i) then
      focus_and_select_track(i); return
    end
  end
  for i = tot, cur + 1, -1 do
    local tr = song.tracks[i]
    if tr.type == renoise.Track.TRACK_TYPE_SEQUENCER and is_track_collapsed(i) then
      focus_and_select_track(i); return
    end
  end
  renoise.app():show_status("No other null tracks found")
end
M.jump_to_next_collapsed_track     = jump_to_next_null_track
M.jump_to_previous_collapsed_track = jump_to_previous_null_track

----------------------------------------------------------------------
-- focus loss detection and auto-collapse
----------------------------------------------------------------------
local function check_and_auto_collapse_focused_track()
  if not auto_collapse_on_focus_loss or not last_jumped_track then 
    return 
  end

  local song = renoise.song()
  local current_track = song.selected_track_index
  
  -- If we're no longer on the jumped track, handle the focus loss
  if current_track ~= last_jumped_track then
    local track = song.tracks[last_jumped_track]
    if track and track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
      -- Check if the track still has no notes (was null when we jumped to it)
      if last_jumped_track_was_null and is_track_null(last_jumped_track) then
        set_track_state(last_jumped_track, false) -- collapse as null track
      elseif is_track_active(last_jumped_track) then
        track.color = active_track_color
      end
    end
    last_jumped_track, last_jumped_track_was_null = nil, nil
  end
end

-- Function to be called when track selection changes
local function handle_track_focus_change()
  -- First, handle auto-collapse of previously focused track
  check_and_auto_collapse_focused_track()
  
  -- Then, check if we clicked on a null track
  local song = renoise.song()
  local current_track = song.selected_track_index
  local track = song.tracks[current_track]
  
  -- If the newly selected track is collapsed, focus it and set focus mode
  if track and track.type == renoise.Track.TRACK_TYPE_SEQUENCER and is_track_collapsed(current_track) then
    focus_and_select_track(current_track)
  end
end
M.handle_track_focus_change = handle_track_focus_change

----------------------------------------------------------------------
-- settings
----------------------------------------------------------------------
local function toggle_auto_collapse_before_jump()
  auto_collapse_before_jump = not auto_collapse_before_jump
  renoise.app():show_status(
    "Auto‑collapse before jump: " .. (auto_collapse_before_jump and "enabled" or "disabled"))
end

local function toggle_auto_collapse_on_focus_loss()
  auto_collapse_on_focus_loss = not auto_collapse_on_focus_loss
  renoise.app():show_status(
    "Auto‑collapse on focus loss: " .. (auto_collapse_on_focus_loss and "enabled" or "disabled"))
end

M.toggle_auto_collapse_before_jump = toggle_auto_collapse_before_jump
M.toggle_auto_collapse_on_focus_loss = toggle_auto_collapse_on_focus_loss
M.is_pattern_collapsed             = is_pattern_collapsed

-- Function to check if a track has any note information
local function track_has_notes(track_idx)
  local song = renoise.song()
  local sequencer = song.sequencer
  
  -- Check all patterns in the sequence
  for seq_idx = 1, #sequencer.pattern_sequence do
    local pattern_index = sequencer:pattern(seq_idx)
    local pattern = song:pattern(pattern_index)
    if pattern then
      local track = pattern:track(track_idx)
      if track then
        -- Check if track is not empty
        if not track.is_empty then
          return true
        end
      end
    end
  end
  return false
end

-- Function to find and remove tracks with no note information
local function remove_empty_tracks()
  local song = renoise.song()
  local tracks_to_remove = {}
  
  -- Find tracks with no notes
  for track_idx = #song.tracks, 1, -1 do
    local track = song.tracks[track_idx]
    if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
      if not track_has_notes(track_idx) then
        table.insert(tracks_to_remove, track_idx)
      end
    end
  end
  
  if #tracks_to_remove == 0 then
    renoise.app():show_status("No empty tracks found to remove")
    return
  end
  
  -- Confirm with user
  local message = string.format("Found %d empty tracks. Remove them?", #tracks_to_remove)
  local result = renoise.app():show_prompt("Remove Empty Tracks", message, {"Cancel", "Remove"})
  
  if result == "Remove" then
    -- Remove tracks from highest index to lowest to avoid index shifting issues
    for _, track_idx in ipairs(tracks_to_remove) do
      song:delete_track_at(track_idx)
    end
    
    renoise.app():show_status(string.format("Removed %d empty tracks", #tracks_to_remove))
  else
    renoise.app():show_status("Operation cancelled")
  end
end

M.remove_empty_tracks = remove_empty_tracks

return M

