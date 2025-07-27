-- HexTools
-- Adds a menu entry that shows 'Hello, world!' in the status bar.
-- See the Renoise API documentation: https://renoise.github.io/xrnx/API/index.htm

local function show_hello()
  renoise.app():show_status("Hello, world!")
end

local render_utils = require("render_utils")
local navigation_utils = require("navigation_utils")
local instrument_utils = require("instrument_utils")
local utils = require("utils")

-- Buffer for play/return state
local play_return_state = nil

local function render_selection_to_new_track()
  render_utils.render_selection_to_new_track(false)
end

local function render_selection_to_new_track_destructive()
  render_utils.render_selection_to_new_track(true)
end

local function render_selection_to_next_track()
  render_utils.render_selection_to_next_track(false)
end

local function render_selection_to_next_track_destructive()
  render_utils.render_selection_to_next_track(true)
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

local pending_return_state = nil

local registration = require("registration")

registration.register_menu_and_keybindings({
  show_hello = show_hello,
  render_selection_to_new_track = render_selection_to_new_track,
  render_selection_to_new_track_destructive = render_selection_to_new_track_destructive,
  render_selection_to_next_track = render_selection_to_next_track,
  render_selection_to_next_track_destructive = render_selection_to_next_track_destructive,
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
  toggle_auto_collapse_before_jump = toggle_auto_collapse_before_jump
})
