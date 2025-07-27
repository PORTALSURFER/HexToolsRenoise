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

return M 