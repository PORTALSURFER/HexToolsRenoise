-- HexTools
-- Adds a menu entry that shows 'Hello, world!' in the status bar.
-- See the Renoise API documentation: https://renoise.github.io/xrnx/API/index.htm

local function show_hello()
  renoise.app():show_status("Hello, world!")
end

local render_utils = require("render_utils")
local navigation_utils = require("navigation_utils")
local instrument_utils = require("instrument_utils")
local pattern_utils = require("pattern_utils")
local utils = require("utils")

-- Buffer for play/return state
local play_return_state = nil

local function render_selection_to_new_track()
  render_utils.render_selection_to_new_track(false)
end

local function render_selection_to_new_track_destructive()
  render_utils.render_selection_to_new_track(true)
end

local function render_selection_to_copy_buffer()
  render_utils.render_selection_to_copy_buffer()
end

local function paste_sample_from_clipboard()
  render_utils.paste_sample_from_clipboard()
end

local function clear_sample_clipboard()
  render_utils.clear_sample_clipboard()
end

local function render_selection_to_next_track()
  render_utils.render_selection_to_next_track(false)
end

local function render_selection_to_next_track_destructive()
  render_utils.render_selection_to_next_track(true)
end

local function sample_and_merge_track_notes()
  render_utils.sample_and_merge_track_notes()
end

local function on_transport_stopped()
  if not pending_return_state then return end
  local song = renoise.song()
  if song.transport.playing then return end -- Only act when playback has stopped

  local seq_count = #song.sequencer.pattern_sequence
  local seq_idx = math.min(pending_return_state.sequence, seq_count)
  song.selected_sequence_index = seq_idx

  local track_count = #song.tracks
  local track_idx = math.min(pending_return_state.track, track_count)
  song.selected_track_index = track_idx

  local patt_idx = song.sequencer:pattern(seq_idx)
  local patt = song:pattern(patt_idx)
  local max_line = patt.number_of_lines
  local line_idx = math.min(pending_return_state.line, max_line)
  song.selected_line_index = line_idx

  renoise.app():show_status(
    ("[DEBUG] Restored: seq=%d, track=%d, line=%d (buffered: seq=%d, track=%d, line=%d)"):
    format(
      song.selected_sequence_index,
      song.selected_track_index,
      song.selected_line_index,
      pending_return_state.sequence,
      pending_return_state.track,
      pending_return_state.line
    )
  )
  pending_return_state = nil
  -- Remove the notifier after use
  song.transport.playing_observable:remove_notifier(on_transport_stopped)
end

local function play_and_return_toggle()
  navigation_utils.play_and_return_toggle()
end

local function set_playhead_buffer()
  navigation_utils.set_playhead_buffer()
end

local function play_from_buffer()
  navigation_utils.play_from_buffer()
end

local function jump_to_buffered_play_line()
  navigation_utils.jump_to_buffered_play_line()
end

local function find_duplicate_single_sample_instruments()
  instrument_utils.find_duplicate_single_sample_instruments()
end

local function prompt_and_merge_instruments()
  instrument_utils.prompt_and_merge_instruments()
end

local function prompt_and_remap_instruments()
  instrument_utils.prompt_and_remap_instruments()
end

local function remap_selected_notes_to_this()
  instrument_utils.remap_selected_notes_to_this()
end

local function render_selection_to_instrument_sample()
  render_utils.render_selection_to_instrument_sample()
end

local function focus_automation_editor_for_selection()
  instrument_utils.focus_automation_editor_for_selection()
end

local function convert_automation_to_pattern()
  instrument_utils.convert_automation_to_pattern()
end

local function convert_pattern_to_automation()
  instrument_utils.convert_pattern_to_automation()
end

local function export_keybindings_md()
  utils.export_keybindings_md()
end

local function collapse_unused_tracks_in_pattern()
  utils.collapse_unused_tracks_in_pattern()
end

local function jump_to_next_track()
  utils.jump_to_next_track()
end

local function jump_to_previous_track()
  utils.jump_to_previous_track()
end

local function toggle_auto_collapse_before_jump()
  utils.toggle_auto_collapse_before_jump()
end

local function jump_to_next_collapsed_track()
  utils.jump_to_next_collapsed_track()
end

local function jump_to_previous_collapsed_track()
  utils.jump_to_previous_collapsed_track()
end

local function move_to_next_track_skip_collapsed()
  utils.move_to_next_track_skip_collapsed()
end

local function jump_to_previous_track_with_solo()
  utils.jump_to_previous_track_with_solo()
end

local function jump_to_next_track_with_solo()
  utils.jump_to_next_track_with_solo()
end

local function jump_quarter_up()
  utils.jump_quarter_up()
end

local function jump_quarter_down()
  utils.jump_quarter_down()
end

local pending_return_state = nil

local registration = require("registration")

local function toggle_auto_collapse_on_focus_loss()
  utils.toggle_auto_collapse_on_focus_loss()
end

local function double_pattern_length()
  pattern_utils.double_pattern_length()
end

local function halve_pattern_length()
  pattern_utils.halve_pattern_length()
end

local function change_lpb()
  pattern_utils.change_lpb()
end

local function nudge_note_up()
  pattern_utils.nudge_note_up()
end

local function nudge_note_down()
  pattern_utils.nudge_note_down()
end

local function expand_selection_to_full_pattern()
  pattern_utils.expand_selection_to_full_pattern()
end

local function color_selected_pattern_slots()
  local song = renoise.song()
  local sequencer = song.sequencer
  
  -- Get the current theme's default colors
  local theme = renoise.app().theme
  local default_colors = {}
  
  -- Extract the default colors from the theme (default_color_01 through default_color_16)
  for i = 1, 16 do
    local color_name = string.format("default_color_%02d", i)
    local color = theme:color(color_name)
    if color then
      table.insert(default_colors, {color[1], color[2], color[3]})
    end
  end
  
  -- Fallback to some basic colors if theme colors aren't available
  if #default_colors == 0 then
    default_colors = {
      {255, 255, 255}, -- white
      {255, 0, 0},     -- red
      {0, 255, 0},     -- green
      {0, 0, 255},     -- blue
      {255, 255, 0},   -- yellow
      {255, 0, 255},   -- magenta
      {0, 255, 255},   -- cyan
      {255, 128, 0},   -- orange
      {128, 0, 255},   -- purple
      {0, 255, 128},   -- light green
      {255, 128, 128}, -- light red
      {128, 255, 128}, -- light green
      {128, 128, 255}, -- light blue
      {255, 200, 0},   -- gold
      {200, 100, 0},   -- brown
      {128, 128, 128}  -- gray
    }
  end
  
  -- Get the pattern matrix grid selection
  local selected_slots = {}
  
  -- Check each sequence and track for selected slots in the pattern matrix
  for seq_idx = 1, #sequencer.pattern_sequence do
    for track_idx = 1, #song.tracks do
      if sequencer:track_sequence_slot_is_selected(track_idx, seq_idx) then
        table.insert(selected_slots, {track = track_idx, sequence = seq_idx})
      end
    end
  end
  
  if #selected_slots == 0 then
    renoise.app():show_status("No pattern matrix grid slots selected")
    return
  end
  
  -- Debug output
  renoise.app():show_status(string.format("Found %d selected pattern matrix grid slots", #selected_slots))
  
  -- Color each selected pattern matrix grid slot
  local colored_slots = 0
  local random_color = default_colors[math.random(#default_colors)]
  
  for _, slot in ipairs(selected_slots) do
    local pattern_index = sequencer:pattern(slot.sequence)
    local pattern = song:pattern(pattern_index)
    if pattern then
      local track = pattern:track(slot.track)
      if track then
        track.color = random_color
        colored_slots = colored_slots + 1
      end
    end
  end
  
  renoise.app():show_status(string.format("Colored %d pattern matrix grid slots with color {%d, %d, %d}", 
    colored_slots, random_color[1], random_color[2], random_color[3]))
end

local function solo_selected_pattern_matrix_tracks()
  local song = renoise.song()
  local sequencer = song.sequencer
  
  -- Get the pattern matrix grid selection
  local selected_slots = {}
  
  -- Check each sequence and track for selected slots in the pattern matrix
  for seq_idx = 1, #sequencer.pattern_sequence do
    for track_idx = 1, #song.tracks do
      if sequencer:track_sequence_slot_is_selected(track_idx, seq_idx) then
        table.insert(selected_slots, {track = track_idx, sequence = seq_idx})
      end
    end
  end
  
  if #selected_slots == 0 then
    renoise.app():show_status("No pattern matrix grid slots selected")
    return
  end
  
  -- First, mute all tracks
  for i = 1, #song.tracks do
    local track = song.tracks[i]
    if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
      track.mute_state = renoise.Track.MUTE_STATE_MUTED
    end
  end
  
  -- Solo the tracks that have selected slots
  local soloed_tracks = {}
  for _, slot in ipairs(selected_slots) do
    local track = song.tracks[slot.track]
    if track and track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
      track.mute_state = renoise.Track.MUTE_STATE_ACTIVE
      if not soloed_tracks[slot.track] then
        soloed_tracks[slot.track] = true
      end
    end
  end
  
  -- Count unique soloed tracks
  local soloed_count = 0
  for _ in pairs(soloed_tracks) do
    soloed_count = soloed_count + 1
  end
  
  renoise.app():show_status(string.format("Soloed %d tracks from %d selected pattern matrix slots", 
    soloed_count, #selected_slots))
end

local function merge_selected_pattern_matrix_tracks()
  local song = renoise.song()
  local sequencer = song.sequencer
  
  -- Get the pattern matrix grid selection
  local selected_slots = {}
  
  -- Check each sequence and track for selected slots in the pattern matrix
  for seq_idx = 1, #sequencer.pattern_sequence do
    for track_idx = 1, #song.tracks do
      if sequencer:track_sequence_slot_is_selected(track_idx, seq_idx) then
        table.insert(selected_slots, {track = track_idx, sequence = seq_idx})
      end
    end
  end
  
  if #selected_slots == 0 then
    renoise.app():show_status("No pattern matrix grid slots selected")
    return
  end
  
  -- Group selected slots by pattern
  local patterns_to_render = {}
  for _, slot in ipairs(selected_slots) do
    local pattern_index = sequencer:pattern(slot.sequence)
    if not patterns_to_render[pattern_index] then
      patterns_to_render[pattern_index] = {}
    end
    table.insert(patterns_to_render[pattern_index], slot)
  end
  
  -- Convert to array for sequential processing
  local patterns_array = {}
  for pattern_index, slots in pairs(patterns_to_render) do
    table.insert(patterns_array, {pattern_index = pattern_index, slots = slots})
  end
  
  -- Find the highest track index to place new track after
  local max_track_idx = 0
  for _, slot in ipairs(selected_slots) do
    max_track_idx = math.max(max_track_idx, slot.track)
  end
  
  -- Create single new track after the highest selected track
  local new_track_idx = max_track_idx + 1
  song:insert_track_at(new_track_idx)
  
  local rendered_count = 0
  local current_pattern_index = 1
  
  local function render_next_pattern()
    if current_pattern_index > #patterns_array then
      -- All patterns rendered
      renoise.app():show_status(string.format("Merged %d patterns to new track", rendered_count))
      return
    end
    
    local pattern_data = patterns_array[current_pattern_index]
    local pattern_index = pattern_data.pattern_index
    local slots = pattern_data.slots
    
    -- Check if any of the selected tracks have notes for this pattern
    local has_notes = false
    local tracks_with_notes = {}
    local tracks_without_notes = {}
    
    for _, slot in ipairs(slots) do
      -- Get the pattern that corresponds to this sequence slot
      local sequence_pattern_index = sequencer:pattern(slot.sequence)
      local pattern = song:pattern(sequence_pattern_index)
      local track = pattern:track(slot.track)
      local track_name = song.tracks[slot.track].name
      
      -- Check all lines in this track
      local track_has_notes = false
      for line_idx = 1, pattern.number_of_lines do
        local line = track:line(line_idx)
        local note_value = line:note_column(1).note_value
        local instrument_value = line:note_column(1).instrument_value
        local volume_value = line:note_column(1).volume_value
        
        -- Filter out special Renoise note values (like 121 for stop notes, etc.)
        -- Only count actual musical notes (1-120 for MIDI notes)
        if note_value ~= 0 and note_value >= 1 and note_value <= 120 then
          track_has_notes = true
          has_notes = true
          table.insert(tracks_with_notes, slot.track)
          break
        end
      end
      
      if not track_has_notes then
        table.insert(tracks_without_notes, slot.track)
      end
      
      if has_notes then break end
    end
    
    if not has_notes then
      -- Skip this pattern and move to next
      current_pattern_index = current_pattern_index + 1
      render_next_pattern()
      return
    end
    
    -- Mute all tracks except the selected ones for this pattern
    local original_mute_states = {}
    for i = 1, #song.tracks do
      local track = song.tracks[i]
      if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
        original_mute_states[i] = track.mute_state
        track.mute_state = renoise.Track.MUTE_STATE_MUTED
      end
    end
    
    -- Unmute the selected tracks for this pattern
    for _, slot in ipairs(slots) do
      local track = song.tracks[slot.track]
      if track and track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
        track.mute_state = renoise.Track.MUTE_STATE_ACTIVE
      end
    end
    
    -- Double-check that selected tracks are unmuted before rendering
    for _, slot in ipairs(slots) do
      local track = song.tracks[slot.track]
      if track and track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
        if track.mute_state ~= renoise.Track.MUTE_STATE_ACTIVE then
          track.mute_state = renoise.Track.MUTE_STATE_ACTIVE
        end
      end
    end
    
    -- Render the pattern
    local pattern = song:pattern(pattern_index)
    local start_pos = renoise.SongPos(slots[1].sequence, 1)
    local end_pos = renoise.SongPos(slots[1].sequence, pattern.number_of_lines)
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
        local track = song.tracks[i]
        if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
          track.mute_state = original_mute_states[i]
        end
      end
      
      -- Create new instrument and load sample
      local new_instr_idx = song.selected_instrument_index + 1
      local instr = song:insert_instrument_at(new_instr_idx)
      instr:insert_sample_at(1)
      local sample = instr:sample(1)
      sample.sample_buffer:load_from(temp_file)
      
      -- Enable autoseek for the rendered sample
      sample.autoseek = true
      
      -- Apply 6dB boost by setting instrument volume to maximum
      instr.volume = 1.99526
      
      os.remove(temp_file)
      
      -- Add a C-4 note at the start of the new track
      local new_pattern = song:pattern(pattern_index)
      local new_track = new_pattern:track(new_track_idx)
      local line = new_track:line(1)
      line:note_column(1).note_value = 48 -- C-4
      line:note_column(1).instrument_value = new_instr_idx - 1 -- 0-based
      line:note_column(1).volume_value = 0xFF -- full velocity (255 in hex)
      
      rendered_count = rendered_count + 1
      current_pattern_index = current_pattern_index + 1
      
      -- Render next pattern
      render_next_pattern()
    end)
  end
  
  -- Start rendering the first pattern
  render_next_pattern()
end

local function merge_selected_pattern_matrix_tracks_destructive()
  local song = renoise.song()
  local sequencer = song.sequencer
  
  -- Get the pattern matrix grid selection
  local selected_slots = {}
  
  -- Check each sequence and track for selected slots in the pattern matrix
  for seq_idx = 1, #sequencer.pattern_sequence do
    for track_idx = 1, #song.tracks do
      if sequencer:track_sequence_slot_is_selected(track_idx, seq_idx) then
        table.insert(selected_slots, {track = track_idx, sequence = seq_idx})
      end
    end
  end
  
  if #selected_slots == 0 then
    renoise.app():show_status("No pattern matrix grid slots selected")
    return
  end
  
  -- Group selected slots by pattern
  local patterns_to_render = {}
  for _, slot in ipairs(selected_slots) do
    local pattern_index = sequencer:pattern(slot.sequence)
    if not patterns_to_render[pattern_index] then
      patterns_to_render[pattern_index] = {}
    end
    table.insert(patterns_to_render[pattern_index], slot)
  end
  
  -- Convert to array for sequential processing
  local patterns_array = {}
  for pattern_index, slots in pairs(patterns_to_render) do
    table.insert(patterns_array, {pattern_index = pattern_index, slots = slots})
  end
  
  -- Find the highest track index to place new track after
  local max_track_idx = 0
  for _, slot in ipairs(selected_slots) do
    max_track_idx = math.max(max_track_idx, slot.track)
  end
  
  -- Create single new track after the highest selected track
  local new_track_idx = max_track_idx + 1
  song:insert_track_at(new_track_idx)
  
  local rendered_count = 0
  local tracks_to_remove = {}
  local current_pattern_index = 1
  
  local function render_next_pattern()
    if current_pattern_index > #patterns_array then
      -- All patterns rendered, now remove source tracks
      local tracks_to_remove_list = {}
      for track_idx in pairs(tracks_to_remove) do
        table.insert(tracks_to_remove_list, track_idx)
      end
      table.sort(tracks_to_remove_list, function(a, b) return a > b end)
      
      for _, track_idx in ipairs(tracks_to_remove_list) do
        song:delete_track_at(track_idx)
      end
      
      renoise.app():show_status(string.format("Merged %d patterns to new track and removed %d source tracks", 
        rendered_count, #tracks_to_remove_list))
      return
    end
    
    local pattern_data = patterns_array[current_pattern_index]
    local pattern_index = pattern_data.pattern_index
    local slots = pattern_data.slots
    
    -- Check if any of the selected tracks have notes for this pattern
    local has_notes = false
    local tracks_with_notes = {}
    local tracks_without_notes = {}
    
    for _, slot in ipairs(slots) do
      -- Get the pattern that corresponds to this sequence slot
      local sequence_pattern_index = sequencer:pattern(slot.sequence)
      local pattern = song:pattern(sequence_pattern_index)
      local track = pattern:track(slot.track)
      local track_name = song.tracks[slot.track].name
      
      -- Check all lines in this track
      local track_has_notes = false
      for line_idx = 1, pattern.number_of_lines do
        local line = track:line(line_idx)
        local note_value = line:note_column(1).note_value
        local instrument_value = line:note_column(1).instrument_value
        local volume_value = line:note_column(1).volume_value
        
        -- Filter out special Renoise note values (like 121 for stop notes, etc.)
        -- Only count actual musical notes (1-120 for MIDI notes)
        if note_value ~= 0 and note_value >= 1 and note_value <= 120 then
          track_has_notes = true
          has_notes = true
          table.insert(tracks_with_notes, slot.track)
          break
        end
      end
      
      if not track_has_notes then
        table.insert(tracks_without_notes, slot.track)
      end
      
      if has_notes then break end
    end
    
    if not has_notes then
      -- Skip this pattern and move to next
      current_pattern_index = current_pattern_index + 1
      render_next_pattern()
      return
    end
    
    -- Mute all tracks except the selected ones for this pattern
    local original_mute_states = {}
    for i = 1, #song.tracks do
      local track = song.tracks[i]
      if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
        original_mute_states[i] = track.mute_state
        track.mute_state = renoise.Track.MUTE_STATE_MUTED
      end
    end
    
    -- Unmute the selected tracks for this pattern
    for _, slot in ipairs(slots) do
      local track = song.tracks[slot.track]
      if track and track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
        track.mute_state = renoise.Track.MUTE_STATE_ACTIVE
        -- Mark track for removal
        tracks_to_remove[slot.track] = true
      end
    end
    
    -- Double-check that selected tracks are unmuted before rendering
    for _, slot in ipairs(slots) do
      local track = song.tracks[slot.track]
      if track and track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
        if track.mute_state ~= renoise.Track.MUTE_STATE_ACTIVE then
          track.mute_state = renoise.Track.MUTE_STATE_ACTIVE
        end
      end
    end
    
    -- Render the pattern
    local pattern = song:pattern(pattern_index)
    local start_pos = renoise.SongPos(slots[1].sequence, 1)
    local end_pos = renoise.SongPos(slots[1].sequence, pattern.number_of_lines)
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
        local track = song.tracks[i]
        if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
          track.mute_state = original_mute_states[i]
        end
      end
      
      -- Create new instrument and load sample
      local new_instr_idx = song.selected_instrument_index + 1
      local instr = song:insert_instrument_at(new_instr_idx)
      instr:insert_sample_at(1)
      local sample = instr:sample(1)
      sample.sample_buffer:load_from(temp_file)
      
      -- Enable autoseek for the rendered sample
      sample.autoseek = true
      
      -- Apply 6dB boost by setting instrument volume to maximum
      instr.volume = 1.99526
      
      os.remove(temp_file)
      
      -- Add a C-4 note at the start of the new track
      local new_pattern = song:pattern(pattern_index)
      local new_track = new_pattern:track(new_track_idx)
      local line = new_track:line(1)
      line:note_column(1).note_value = 48 -- C-4
      line:note_column(1).instrument_value = new_instr_idx - 1 -- 0-based
      line:note_column(1).volume_value = 0xFF -- full velocity (255 in hex)
      
      rendered_count = rendered_count + 1
      current_pattern_index = current_pattern_index + 1
      
      -- Render next pattern
      render_next_pattern()
    end)
  end
  
  -- Start rendering the first pattern
  render_next_pattern()
end

local function remove_empty_tracks()
  utils.remove_empty_tracks()
end

registration.register_menu_and_keybindings({
  show_hello = show_hello,
  render_selection_to_new_track = render_selection_to_new_track,
  render_selection_to_new_track_destructive = render_selection_to_new_track_destructive,
  render_selection_to_next_track = render_selection_to_next_track,
  render_selection_to_next_track_destructive = render_selection_to_next_track_destructive,
  render_selection_to_copy_buffer = render_selection_to_copy_buffer,
  paste_sample_from_clipboard = paste_sample_from_clipboard,
  clear_sample_clipboard = clear_sample_clipboard,
  sample_and_merge_track_notes = sample_and_merge_track_notes,
  set_playhead_buffer = set_playhead_buffer,
  play_from_buffer = play_from_buffer,
  jump_to_buffered_play_line = jump_to_buffered_play_line,
  find_duplicate_single_sample_instruments = find_duplicate_single_sample_instruments,
  prompt_and_merge_instruments = prompt_and_merge_instruments,
  prompt_and_remap_instruments = prompt_and_remap_instruments,
  remap_selected_notes_to_this = remap_selected_notes_to_this,
  render_selection_to_instrument_sample = render_selection_to_instrument_sample,
  increase_velocity = instrument_utils.increase_velocity,
  decrease_velocity = instrument_utils.decrease_velocity,
  increase_velocity_sensitive = instrument_utils.increase_velocity_sensitive,
  decrease_velocity_sensitive = instrument_utils.decrease_velocity_sensitive,
  focus_automation_editor_for_selection = focus_automation_editor_for_selection,
  convert_automation_to_pattern = convert_automation_to_pattern,
  convert_pattern_to_automation = convert_pattern_to_automation,
  export_keybindings_md = export_keybindings_md,
  collapse_unused_tracks_in_pattern = collapse_unused_tracks_in_pattern,
  jump_to_next_track = jump_to_next_track,
  jump_to_previous_track = jump_to_previous_track,
  jump_to_next_collapsed_track = jump_to_next_collapsed_track,
  jump_to_previous_collapsed_track = jump_to_previous_collapsed_track,
  move_to_next_track_skip_collapsed = move_to_next_track_skip_collapsed,
  jump_to_previous_track_with_solo = jump_to_previous_track_with_solo,
  jump_to_next_track_with_solo = jump_to_next_track_with_solo,
  jump_quarter_up = jump_quarter_up,
  jump_quarter_down = jump_quarter_down,
  toggle_auto_collapse_before_jump = toggle_auto_collapse_before_jump,
  toggle_auto_collapse_on_focus_loss = toggle_auto_collapse_on_focus_loss,
  double_pattern_length = double_pattern_length,
  halve_pattern_length = halve_pattern_length,
  change_lpb = change_lpb,
  nudge_note_up = nudge_note_up,
  nudge_note_down = nudge_note_down,
  expand_selection_to_full_pattern = expand_selection_to_full_pattern,
  color_selected_pattern_slots = color_selected_pattern_slots,
  solo_selected_pattern_matrix_tracks = solo_selected_pattern_matrix_tracks,
  merge_selected_pattern_matrix_tracks = merge_selected_pattern_matrix_tracks,
  merge_selected_pattern_matrix_tracks_destructive = merge_selected_pattern_matrix_tracks_destructive,
  remove_empty_tracks = remove_empty_tracks
})

-- Initialize track selection notifier after script is loaded
local function initialize_track_notifier()
  local song = renoise.song()
  if song then
    song.selected_track_index_observable:add_notifier(utils.handle_track_focus_change)
  end
end

-- Use a timer to delay initialization until API is ready
local function setup_delayed_initialization()
  local tool = renoise.tool()
  if tool then
    local notifier_function
    notifier_function = function()
      initialize_track_notifier()
      tool.app_idle_observable:remove_notifier(notifier_function)
    end
    tool.app_idle_observable:add_notifier(notifier_function)
  else
    -- Fallback: try again after a short delay
    renoise.app():schedule_timer(0.1, function()
      setup_delayed_initialization()
    end)
  end
end

-- Start the delayed initialization
setup_delayed_initialization()
