local M = {}

local play_return_state = nil
local pending_return_state = nil

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

function M.play_and_return_toggle()
  local song = renoise.song()
  if not play_return_state then
    play_return_state = {
      sequence = song.selected_sequence_index,
      track = song.selected_track_index,
      line = song.selected_line_index,
      was_playing = song.transport.playing
    }
    renoise.app():show_status(
      ("[DEBUG] Buffered: seq=%d, track=%d, line=%d"):
      format(
        play_return_state.sequence,
        play_return_state.track,
        play_return_state.line
      )
    )
    song.transport:start(renoise.Transport.PLAYMODE_CONTINUE_PATTERN)
  else
    renoise.app():show_status(
      ("[DEBUG] Before restore: seq=%d, track=%d, line=%d"):
      format(
        song.selected_sequence_index,
        song.selected_track_index,
        song.selected_line_index
      )
    )
    pending_return_state = play_return_state
    play_return_state = nil
    -- Add the notifier before stopping playback
    if not song.transport.playing_observable:has_notifier(on_transport_stopped) then
      song.transport.playing_observable:add_notifier(on_transport_stopped)
    end
    song.transport:stop()
    -- The actual jump will happen when playback has stopped
  end
end

function M.jump_to_test_position()
  local song = renoise.song()
  -- Jump to sequence 2 (if it exists), track 1, line 21
  local seq_idx = math.min(2, #song.sequencer.pattern_sequence)
  song.selected_sequence_index = seq_idx

  local track_idx = 1
  song.selected_track_index = track_idx

  -- Get the pattern index for this sequence position
  local patt_idx = song.sequencer:pattern(seq_idx)
  local patt = song:pattern(patt_idx)
  local line_idx = math.min(21, patt.number_of_lines)
  song.selected_line_index = line_idx

  renoise.app():show_status(
    ("[DEBUG] Jumped to sequence %d, track %d, line %d."):
    format(seq_idx, track_idx, line_idx)
  )
end

return M 