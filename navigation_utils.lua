local M = {}

local play_return_state = nil
local pending_return_state = nil

-- New unified buffer for play position
local play_buffer = nil

-- Local function to handle transport stopped events
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

-- Store current cursor position into play_buffer
function M.set_playhead_buffer()
  local song = renoise.song()
  play_buffer = {
    sequence = song.selected_sequence_index,
    track = song.selected_track_index,
    line = song.selected_line_index
  }
  renoise.app():show_status(("Buffered play position: seq=%d, track=%d, line=%d")
    :format(play_buffer.sequence, play_buffer.track, play_buffer.line))
end

-- Toggle play from buffer: if not playing, buffer current line and start playing; if playing, stop and jump back to buffered line
function M.play_from_buffer()
  local song = renoise.song()
  
  if not song.transport.playing then
    -- Not playing: buffer current line and start playing from that line
    -- In record mode, we want to play from the current cursor position, not where transport was
    play_buffer = {
      sequence = song.selected_sequence_index,
      track = song.selected_track_index,
      line = song.selected_line_index
    }
    
    renoise.app():show_status(("Buffered and playing from: seq=%d, track=%d, line=%d")
      :format(play_buffer.sequence, play_buffer.track, play_buffer.line))
    
    -- Start playing from the current cursor position
    song.transport:start_at(play_buffer.line)
  else
    -- Playing: stop playing and jump back to buffered line
    if not play_buffer then
      renoise.app():show_status("No play buffer set. Cannot return to previous position.")
      return
    end
    
    -- Store the buffer for the return operation
    pending_return_state = play_buffer
    play_buffer = nil
    
    -- Add the notifier before stopping playback
    if not song.transport.playing_observable:has_notifier(on_transport_stopped) then
      song.transport.playing_observable:add_notifier(on_transport_stopped)
    end
    
    song.transport:stop()
    -- The actual jump will happen when playback has stopped
  end
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

function M.jump_to_buffered_play_line()
  local song = renoise.song()
  
  if not play_buffer then
    renoise.app():show_status("No buffered play position set. Use 'Play From Buffer' first to set a position.")
    return
  end
  
  -- Jump to the buffered play position
  local seq_count = #song.sequencer.pattern_sequence
  local seq_idx = math.min(play_buffer.sequence, seq_count)
  song.selected_sequence_index = seq_idx

  local track_count = #song.tracks
  local track_idx = math.min(play_buffer.track, track_count)
  song.selected_track_index = track_idx

  -- Get the pattern index for this sequence position
  local patt_idx = song.sequencer:pattern(seq_idx)
  local patt = song:pattern(patt_idx)
  local line_idx = math.min(play_buffer.line, patt.number_of_lines)
  song.selected_line_index = line_idx

  renoise.app():show_status(
    ("Jumped to buffered play position: seq=%d, track=%d, line=%d"):
    format(seq_idx, track_idx, line_idx)
  )
end

return M 