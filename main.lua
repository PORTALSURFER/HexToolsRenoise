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

local function jump_to_test_position()
  navigation_utils.jump_to_test_position()
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
  jump_to_test_position = jump_to_test_position,
  find_duplicate_single_sample_instruments = find_duplicate_single_sample_instruments,
  prompt_and_merge_instruments = prompt_and_merge_instruments,
  prompt_and_remap_instruments = prompt_and_remap_instruments,
  remap_selected_notes_to_this = remap_selected_notes_to_this,
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
  jump_quarter_up = jump_quarter_up,
  jump_quarter_down = jump_quarter_down,
  toggle_auto_collapse_before_jump = toggle_auto_collapse_before_jump,
  toggle_auto_collapse_on_focus_loss = toggle_auto_collapse_on_focus_loss,
  double_pattern_length = double_pattern_length,
  halve_pattern_length = halve_pattern_length,
  change_lpb = change_lpb,
  color_selected_pattern_slots = color_selected_pattern_slots,
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
