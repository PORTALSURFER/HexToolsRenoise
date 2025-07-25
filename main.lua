-- Hello World Tool
-- Adds a menu entry that shows 'Hello, world!' in the status bar.
-- See the Renoise API documentation: https://renoise.github.io/xrnx/API/index.htm

local function show_hello()
  renoise.app():show_status("Hello, world!")
end

-- Render the current pattern selection to a WAV file. See
-- https://renoise.github.io/xrnx/API/renoise.song.API.html#render
local function render_selection_to_new_track_impl(destructive)
  local song = renoise.song()
  local sel = song.selection_in_pattern

  if not sel then
    renoise.app():show_status("Nothing selected to render")
    return
  end

  local start_pos = renoise.SongPos(song.selected_sequence_index, sel.start_line)
  local end_pos = renoise.SongPos(song.selected_sequence_index, sel.end_line)
  local temp_file = os.tmpname() .. ".wav"

  local options = {
    start_pos = start_pos,
    end_pos = end_pos,
    priority = "high"
  }

  song:render(options, temp_file, function()
    -- 1. Create new instrument and load sample
    local new_instr_idx = song.selected_instrument_index + 1
    local instr = song:insert_instrument_at(new_instr_idx)
    instr:insert_sample_at(1)
    instr:sample(1).sample_buffer:load_from(temp_file)
    os.remove(temp_file)

    -- 2. Create a new track to the right of the current track
    local new_track_idx = song.selected_track_index + 1
    song:insert_track_at(new_track_idx)

    -- 3. Add a C-4 note with full velocity at the top of the selection
    local pattern = song:pattern(song.selected_pattern_index)
    local track = pattern:track(new_track_idx)
    local line = track:line(sel.start_line)
    line:note_column(1).note_value = 48 -- C-4
    line:note_column(1).instrument_value = new_instr_idx - 1 -- 0-based
    line:note_column(1).volume_value = 0x80 -- full velocity (128 in hex)

    -- 4. Optionally cut (clear) all note/effect data in the original selection
    if destructive then
      local orig_track = pattern:track(song.selected_track_index)
      for l = sel.start_line, sel.end_line do
        local orig_line = orig_track:line(l)
        for nc = 1, #orig_line.note_columns do
          orig_line:note_column(nc):clear()
        end
        for ec = 1, #orig_line.effect_columns do
          orig_line:effect_column(ec):clear()
        end
      end
      renoise.app():show_status("Rendered selection, added new note, and cut original selection")
    else
      renoise.app():show_status("Rendered selection to new instrument and added C-4 note in new track")
    end
  end)
end

local function render_selection_to_new_track()
  render_selection_to_new_track_impl(false)
end

local function render_selection_to_new_track_destructive()
  render_selection_to_new_track_impl(true)
end

-- Buffer for play/return state
local play_return_state = nil

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

local function jump_to_test_position()
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

local pending_return_state = nil

renoise.tool():add_menu_entry{
  name = "Main Menu:Tools:Hello World Tool:Show Hello",
  invoke = show_hello
}

renoise.tool():add_menu_entry{
  name = "Main Menu:Tools:Hello World Tool:Render Selection To New Track",
  invoke = render_selection_to_new_track
}

renoise.tool():add_menu_entry{
  name = "Main Menu:Tools:Hello World Tool:Render Selection To New Track Destructive",
  invoke = render_selection_to_new_track_destructive
}

renoise.tool():add_menu_entry{
  name = "Main Menu:Tools:Hello World Tool:Play And Return Toggle",
  invoke = play_and_return_toggle
}

renoise.tool():add_menu_entry{
  name = "Main Menu:Tools:Hello World Tool:Jump To Test Position",
  invoke = jump_to_test_position
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Tools:Play And Return Toggle",
  invoke = play_and_return_toggle
}
