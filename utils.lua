local M = {}

M.DEBUG = false

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
local reorder_collapsed_tracks     = false
local auto_collapse_before_jump    = true
local pattern_collapsed_state      = {}
local last_jumped_track            = nil
local last_jumped_track_was_empty  = nil
local auto_collapse_on_focus_loss  = true  -- new setting

-- colours
local active_track_color    = {255, 100, 0}
local collapsed_track_color = {100, 100, 100}
local previous_colors       = {}

----------------------------------------------------------------------
-- collapse / expand helpers
----------------------------------------------------------------------
local function collapse_unused_tracks_in_pattern()
  local song      = renoise.song()
  local patt_idx  = song.selected_pattern_index
  local pattern   = song:pattern(patt_idx)

  -- (1) first time on this pattern  → collapse unused
  -- (2) subsequent call             → toggle
  local initial_call = (last_collapsed_pattern_idx ~= patt_idx)

  local function apply_state(expand)
    local collapsed_indices, expanded_indices = {}, {}
    for t = 1, #song.tracks do
      local track = song.tracks[t]
      if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
        local has_notes = not pattern:track(t).is_empty
        track.collapsed = expand and false or not has_notes
        if has_notes then
          table.insert(expanded_indices, t)
        else
          table.insert(collapsed_indices, t)
        end
        -- save original colour once
        if not previous_colors[t] then
          previous_colors[t] = {track.color[1], track.color[2], track.color[3]}
        end
        track.color = track.collapsed and collapsed_track_color or active_track_color
      end
    end

    if reorder_collapsed_tracks then
      local last_seq = 0
      for t = #song.tracks, 1, -1 do
        if song.tracks[t].type == renoise.Track.TRACK_TYPE_SEQUENCER then
          last_seq = t; break
        end
      end
      for i = #collapsed_indices, 1, -1 do
        local idx = collapsed_indices[i]
        if idx < last_seq then
          song:swap_tracks_at(idx, last_seq); last_seq = last_seq - 1
        end
      end
    end
    pattern_collapsed_state[patt_idx] = not expand
  end

  if initial_call then
    apply_state(false)
    renoise.app():show_status("Collapsed unused tracks.")
  else
    local currently_collapsed = pattern_collapsed_state[patt_idx]
    apply_state(currently_collapsed) -- toggle
    renoise.app():show_status(currently_collapsed and "Expanded all tracks."
                                              or  "Collapsed unused tracks.")
  end
  last_collapsed_pattern_idx = patt_idx
end
M.collapse_unused_tracks_in_pattern = collapse_unused_tracks_in_pattern

local function is_pattern_collapsed()
  return pattern_collapsed_state[renoise.song().selected_pattern_index] == true
end

local function track_has_notes(idx)
  local s   = renoise.song()
  return not s:pattern(s.selected_pattern_index):track(idx).is_empty
end

----------------------------------------------------------------------
-- leave‑track housekeeping
----------------------------------------------------------------------
local function handle_leaving_jumped_track()
  if not last_jumped_track then return end

  local song  = renoise.song()
  local track = song.tracks[last_jumped_track]
  if track and track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
    if track_has_notes(last_jumped_track) then
      track.color = active_track_color
    else
      track.collapsed = true
      track.color     = collapsed_track_color
    end
  end
  last_jumped_track, last_jumped_track_was_empty = nil, nil
end
M.handle_leaving_jumped_track = handle_leaving_jumped_track

----------------------------------------------------------------------
-- non‑collapsed navigation
----------------------------------------------------------------------
local function jump_to_next_track()
  local song = renoise.song()
  if auto_collapse_before_jump and not is_pattern_collapsed() then
    collapse_unused_tracks_in_pattern()
  end

  local cur  = song.selected_track_index
  local tot  = #song.tracks

  if last_jumped_track and last_jumped_track == cur then
    handle_leaving_jumped_track()
  end

  for i = cur + 1, tot do
    local tr = song.tracks[i]
    if tr.type == renoise.Track.TRACK_TYPE_SEQUENCER and not tr.collapsed then
      song.selected_track_index = i
      pattern_collapsed_state[song.selected_pattern_index] = false
      return
    end
  end
  for i = 1, cur - 1 do
    local tr = song.tracks[i]
    if tr.type == renoise.Track.TRACK_TYPE_SEQUENCER and not tr.collapsed then
      song.selected_track_index = i
      pattern_collapsed_state[song.selected_pattern_index] = false
      return
    end
  end
end

local function jump_to_previous_track()
  local song = renoise.song()
  if auto_collapse_before_jump and not is_pattern_collapsed() then
    collapse_unused_tracks_in_pattern()
  end

  local cur = song.selected_track_index
  local tot = #song.tracks

  if last_jumped_track and last_jumped_track == cur then
    handle_leaving_jumped_track()
  end

  for i = cur - 1, 1, -1 do
    local tr = song.tracks[i]
    if tr.type == renoise.Track.TRACK_TYPE_SEQUENCER and not tr.collapsed then
      song.selected_track_index = i
      pattern_collapsed_state[song.selected_pattern_index] = false
      return
    end
  end
  for i = tot, cur + 1, -1 do
    local tr = song.tracks[i]
    if tr.type == renoise.Track.TRACK_TYPE_SEQUENCER and not tr.collapsed then
      song.selected_track_index = i
      pattern_collapsed_state[song.selected_pattern_index] = false
      return
    end
  end
end
M.jump_to_next_track     = jump_to_next_track
M.jump_to_previous_track = jump_to_previous_track

----------------------------------------------------------------------
-- collapsed navigation  (*** fixed ***)
----------------------------------------------------------------------
local function uncollapse_and_select(i)
  local song  = renoise.song()
  local track = song.tracks[i]

  track.collapsed = false
  if not previous_colors[i] then
    previous_colors[i] = {track.color[1], track.color[2], track.color[3]}
  end
  track.color           = {255, 255, 255} -- highlight
  song.selected_track_index = i

  last_jumped_track         = i
  last_jumped_track_was_empty = not track_has_notes(i)
  pattern_collapsed_state[song.selected_pattern_index] = false
end

local function jump_to_next_collapsed_track()
  local song = renoise.song()
  local cur  = song.selected_track_index
  local tot  = #song.tracks

  if last_jumped_track and last_jumped_track == cur then
    handle_leaving_jumped_track()
  end

  for i = cur + 1, tot do
    local tr = song.tracks[i]
    if tr.type == renoise.Track.TRACK_TYPE_SEQUENCER and tr.collapsed then
      uncollapse_and_select(i); return
    end
  end
  for i = 1, cur - 1 do
    local tr = song.tracks[i]
    if tr.type == renoise.Track.TRACK_TYPE_SEQUENCER and tr.collapsed then
      uncollapse_and_select(i); return
    end
  end
  renoise.app():show_status("No other collapsed tracks found")
end

local function jump_to_previous_collapsed_track()
  local song = renoise.song()
  local cur  = song.selected_track_index
  local tot  = #song.tracks

  if last_jumped_track and last_jumped_track == cur then
    handle_leaving_jumped_track()
  end

  for i = cur - 1, 1, -1 do
    local tr = song.tracks[i]
    if tr.type == renoise.Track.TRACK_TYPE_SEQUENCER and tr.collapsed then
      uncollapse_and_select(i); return
    end
  end
  for i = tot, cur + 1, -1 do
    local tr = song.tracks[i]
    if tr.type == renoise.Track.TRACK_TYPE_SEQUENCER and tr.collapsed then
      uncollapse_and_select(i); return
    end
  end
  renoise.app():show_status("No other collapsed tracks found")
end
M.jump_to_next_collapsed_track     = jump_to_next_collapsed_track
M.jump_to_previous_collapsed_track = jump_to_previous_collapsed_track

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
      -- Check if the track still has no notes (was empty when we jumped to it)
      if last_jumped_track_was_empty and not track_has_notes(last_jumped_track) then
        track.collapsed = true
        track.color = collapsed_track_color
      elseif track_has_notes(last_jumped_track) then
        track.color = active_track_color
      end
    end
    last_jumped_track, last_jumped_track_was_empty = nil, nil
  end
end

-- Function to be called when track selection changes
local function handle_track_focus_change()
  check_and_auto_collapse_focused_track()
end
M.handle_track_focus_change = handle_track_focus_change

----------------------------------------------------------------------
-- misc
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

return M

