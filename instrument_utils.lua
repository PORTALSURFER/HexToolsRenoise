local M = {}

-- Compare all samples in all instruments and list those that are exactly the same
function M.find_duplicate_single_sample_instruments()
  local song = renoise.song()
  local samples = {}
  -- Collect all samples with their instrument/sample indices
  for i = 1, #song.instruments do
    local instr = song:instrument(i)
    for s = 1, #instr.samples do
      local sample = instr:sample(s)
      local buf = sample.sample_buffer
      if buf.has_sample_data then
        table.insert(samples, {
          instr_idx = i,
          instr_name = instr.name,
          sample_idx = s,
          sample_name = sample.name,
          buffer = buf
        })
      end
    end
  end

  local duplicates = {}
  -- Compare each pair of samples
  for i = 1, #samples - 1 do
    local a = samples[i]
    local a_buf = a.buffer
    for j = i + 1, #samples do
      local b = samples[j]
      local b_buf = b.buffer
      if a_buf.number_of_frames == b_buf.number_of_frames and a_buf.number_of_channels == b_buf.number_of_channels and a_buf.sample_rate == b_buf.sample_rate then
        local identical = true
        for frame = 1, a_buf.number_of_frames do
          for ch = 1, a_buf.number_of_channels do
            if a_buf:sample_data(ch, frame) ~= b_buf:sample_data(ch, frame) then
              identical = false
              break
            end
          end
          if not identical then break end
        end
        if identical then
          table.insert(duplicates, {
            a = a,
            b = b
          })
        end
      end
    end
  end

  if #duplicates > 0 then
    local msg = "Duplicate samples found (exact waveform match):\n"
    for _, pair in ipairs(duplicates) do
      msg = msg .. ("Instrument %d ('%s'), Sample %d ('%s')\n  == Instrument %d ('%s'), Sample %d ('%s')\n")
        :format(
          pair.a.instr_idx, pair.a.instr_name, pair.a.sample_idx, pair.a.sample_name,
          pair.b.instr_idx, pair.b.instr_name, pair.b.sample_idx, pair.b.sample_name
        )
    end
    renoise.app():show_message(msg)
  else
    renoise.app():show_message("No duplicate samples found.")
  end
end

return M 