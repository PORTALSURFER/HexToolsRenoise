local M = {}

function M.register_menu_and_keybindings(handlers)
  -- Development/Debug Tools
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Show Hello",
    invoke = handlers.show_hello
  }

  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Export Keybindings (Markdown)",
    invoke = handlers.export_keybindings_md
  }

  -- Playback & Navigation
  renoise.tool():add_menu_entry{
    name = "--- Main Menu:Tools:HexTools:Set Playhead Buffer",
    invoke = handlers.set_playhead_buffer
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Play From Buffer",
    invoke = handlers.play_from_buffer
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Jump To Buffered Play Line",
    invoke = handlers.jump_to_buffered_play_line
  }

  -- Track Management
  renoise.tool():add_menu_entry{
    name = "--- Main Menu:Tools:HexTools:Collapse Unused Tracks in Pattern",
    invoke = handlers.collapse_unused_tracks_in_pattern
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Remove Empty Tracks",
    invoke = handlers.remove_empty_tracks
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Jump To Next Track (Skip Collapsed)",
    invoke = handlers.jump_to_next_track
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Jump To Previous Track (Skip Collapsed)",
    invoke = handlers.jump_to_previous_track
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Move To Next Track (Skip Collapsed)",
    invoke = handlers.move_to_next_track_skip_collapsed
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Jump To Previous Track (With Solo)",
    invoke = handlers.jump_to_previous_track_with_solo
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Jump To Next Track (With Solo)",
    invoke = handlers.jump_to_next_track_with_solo
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Jump To Next Collapsed Track",
    invoke = handlers.jump_to_next_collapsed_track
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Jump To Previous Collapsed Track",
    invoke = handlers.jump_to_previous_collapsed_track
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Jump Quarter Up",
    invoke = handlers.jump_quarter_up
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Jump Quarter Down",
    invoke = handlers.jump_quarter_down
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Toggle Auto-Collapse Before Jump",
    invoke = handlers.toggle_auto_collapse_before_jump
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Toggle Auto-Collapse On Focus Loss",
    invoke = handlers.toggle_auto_collapse_on_focus_loss
  }

  -- Rendering & Audio
  renoise.tool():add_menu_entry{
    name = "--- Main Menu:Tools:HexTools:Render Selection To New Track",
    invoke = handlers.render_selection_to_new_track
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Render Selection To New Track Destructive",
    invoke = handlers.render_selection_to_new_track_destructive
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Render Selection To Next Track",
    invoke = handlers.render_selection_to_next_track
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Render Selection To Next Track Destructive",
    invoke = handlers.render_selection_to_next_track_destructive
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Render Selection To Copy Buffer",
    invoke = handlers.render_selection_to_copy_buffer
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Clear Sample Clipboard",
    invoke = handlers.clear_sample_clipboard
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Sample And Merge Track Notes",
    invoke = handlers.sample_and_merge_track_notes
  }

  -- Instrument Management
  renoise.tool():add_menu_entry{
    name = "--- Main Menu:Tools:HexTools:Find Duplicate Single-Sample Instruments",
    invoke = handlers.find_duplicate_single_sample_instruments
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Merge Instruments",
    invoke = handlers.prompt_and_merge_instruments
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Remap Instruments",
    invoke = handlers.prompt_and_remap_instruments
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Remap Selected Notes to This",
    invoke = handlers.remap_selected_notes_to_this
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Render Selection To Instrument Sample",
    invoke = handlers.render_selection_to_instrument_sample
  }

  -- Pattern Management
  renoise.tool():add_menu_entry{
    name = "--- Main Menu:Tools:HexTools:Double Pattern Length",
    invoke = handlers.double_pattern_length
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Halve Pattern Length",
    invoke = handlers.halve_pattern_length
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Change LPB",
    invoke = handlers.change_lpb
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Nudge Note Up",
    invoke = handlers.nudge_note_up
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Nudge Note Down",
    invoke = handlers.nudge_note_down
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Expand Selection To Full Pattern",
    invoke = handlers.expand_selection_to_full_pattern
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Mute Notes Toggle",
    invoke = handlers.mute_notes_toggle
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Color Selected Pattern Slots",
    invoke = handlers.color_selected_pattern_slots
  }

  -- Automation Tools
  renoise.tool():add_menu_entry{
    name = "--- Main Menu:Tools:HexTools:Focus Automation Editor for Selection",
    invoke = handlers.focus_automation_editor_for_selection
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Convert Automation To Pattern",
    invoke = handlers.convert_automation_to_pattern
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Convert Pattern To Automation",
    invoke = handlers.convert_pattern_to_automation
  }

  -- Keybindings (Pattern Editor)
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Set Playhead Buffer",
    invoke = handlers.set_playhead_buffer
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Play From Buffer",
    invoke = handlers.play_from_buffer
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Jump To Buffered Play Line",
    invoke = handlers.jump_to_buffered_play_line
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Render Selection To New Track",
    invoke = handlers.render_selection_to_new_track
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Render Selection To New Track Destructive",
    invoke = handlers.render_selection_to_new_track_destructive
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Render Selection To Next Track",
    invoke = handlers.render_selection_to_next_track
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Render Selection To Next Track Destructive",
    invoke = handlers.render_selection_to_next_track_destructive
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Render Selection To Copy Buffer",
    invoke = handlers.render_selection_to_copy_buffer
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Paste Sample from Clipboard",
    invoke = handlers.paste_sample_from_clipboard
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Clear Sample Clipboard",
    invoke = handlers.clear_sample_clipboard
  }
  renoise.tool():add_keybinding {
    name = "Instrument Editor:Tools:Paste Sample from Clipboard",
    invoke = handlers.paste_sample_from_clipboard
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Sample And Merge Track Notes",
    invoke = handlers.sample_and_merge_track_notes
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Find Duplicate Single-Sample Instruments",
    invoke = handlers.find_duplicate_single_sample_instruments
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Merge Instruments",
    invoke = handlers.prompt_and_merge_instruments
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Remap Instruments",
    invoke = handlers.prompt_and_remap_instruments
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Render Selection To Instrument Sample",
    invoke = handlers.render_selection_to_instrument_sample
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Increase Velocity",
    invoke = handlers.increase_velocity
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Decrease Velocity",
    invoke = handlers.decrease_velocity
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Increase Velocity (Sensitive)",
    invoke = handlers.increase_velocity_sensitive
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Decrease Velocity (Sensitive)",
    invoke = handlers.decrease_velocity_sensitive
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Focus Automation Editor for Selection",
    invoke = handlers.focus_automation_editor_for_selection
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Convert Automation To Pattern",
    invoke = handlers.convert_automation_to_pattern
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Convert Pattern To Automation",
    invoke = handlers.convert_pattern_to_automation
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Collapse Unused Tracks in Pattern",
    invoke = handlers.collapse_unused_tracks_in_pattern
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Jump To Next Track (Skip Collapsed)",
    invoke = handlers.jump_to_next_track
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Jump To Previous Track (Skip Collapsed)",
    invoke = handlers.jump_to_previous_track
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Move To Next Track (Skip Collapsed)",
    invoke = handlers.move_to_next_track_skip_collapsed
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Jump To Previous Track (With Solo)",
    invoke = handlers.jump_to_previous_track_with_solo
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Jump To Next Track (With Solo)",
    invoke = handlers.jump_to_next_track_with_solo
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Toggle Auto-Collapse Before Jump",
    invoke = handlers.toggle_auto_collapse_before_jump
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Jump To Next Collapsed Track",
    invoke = handlers.jump_to_next_collapsed_track
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Jump To Previous Collapsed Track",
    invoke = handlers.jump_to_previous_collapsed_track
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Jump Quarter Up",
    invoke = handlers.jump_quarter_up
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Jump Quarter Down",
    invoke = handlers.jump_quarter_down
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Toggle Auto-Collapse On Focus Loss",
    invoke = handlers.toggle_auto_collapse_on_focus_loss
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Double Pattern Length",
    invoke = handlers.double_pattern_length
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Halve Pattern Length",
    invoke = handlers.halve_pattern_length
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Change LPB",
    invoke = handlers.change_lpb
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Nudge Note Up",
    invoke = handlers.nudge_note_up
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Nudge Note Down",
    invoke = handlers.nudge_note_down
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Expand Selection To Full Pattern",
    invoke = handlers.expand_selection_to_full_pattern
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Color Selected Pattern Slots",
    invoke = handlers.color_selected_pattern_slots
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Mute Notes Toggle",
    invoke = handlers.mute_notes_toggle
  }
  renoise.tool():add_keybinding {
    name = "Pattern Matrix:Tools:Solo Selected Tracks",
    invoke = handlers.solo_selected_pattern_matrix_tracks
  }
  renoise.tool():add_keybinding {
    name = "Pattern Matrix:Tools:Remove Empty Tracks",
    invoke = handlers.remove_empty_tracks
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Remove Empty Tracks",
    invoke = handlers.remove_empty_tracks
  }
  renoise.tool():add_keybinding {
    name = "Pattern Matrix:Tools:Merge Selected Tracks",
    invoke = handlers.merge_selected_pattern_matrix_tracks
  }
  renoise.tool():add_keybinding {
    name = "Pattern Matrix:Tools:Merge Selected Tracks Destructive",
    invoke = handlers.merge_selected_pattern_matrix_tracks_destructive
  }

  -- Pattern Editor Menu Entries
  renoise.tool():add_menu_entry{
    name = "Pattern Editor:Focus Automation Editor for Selection",
    invoke = handlers.focus_automation_editor_for_selection
  }
  renoise.tool():add_menu_entry{
    name = "Pattern Editor:Convert Automation To Pattern",
    invoke = handlers.convert_automation_to_pattern
  }
  renoise.tool():add_menu_entry{
    name = "Pattern Editor:Convert Pattern To Automation",
    invoke = handlers.convert_pattern_to_automation
  }
  renoise.tool():add_menu_entry{
    name = "--- Pattern Editor:Sample And Merge Track Notes",
    invoke = handlers.sample_and_merge_track_notes
  }
  renoise.tool():add_menu_entry{
    name = "--- Pattern Editor:Double Pattern Length",
    invoke = handlers.double_pattern_length
  }
  renoise.tool():add_menu_entry{
    name = "Pattern Editor:Halve Pattern Length",
    invoke = handlers.halve_pattern_length
  }
  renoise.tool():add_menu_entry{
    name = "Pattern Matrix:Color Selected Pattern Slots",
    invoke = handlers.color_selected_pattern_slots
  }
  renoise.tool():add_menu_entry{
    name = "Pattern Matrix:Remove Empty Tracks",
    invoke = handlers.remove_empty_tracks
  }
  renoise.tool():add_menu_entry{
    name = "Pattern Matrix:Solo Selected Tracks",
    invoke = handlers.solo_selected_pattern_matrix_tracks
  }
  renoise.tool():add_menu_entry{
    name = "Pattern Matrix:Merge Selected Tracks",
    invoke = handlers.merge_selected_pattern_matrix_tracks
  }
  renoise.tool():add_menu_entry{
    name = "Pattern Matrix:Merge Selected Tracks Destructive",
    invoke = handlers.merge_selected_pattern_matrix_tracks_destructive
  }

  -- Instrument Box Menu Entry
  renoise.tool():add_menu_entry{
    name = "Instrument Box:Remap Selected Notes to This",
    invoke = handlers.remap_selected_notes_to_this
  }
  renoise.tool():add_menu_entry{
    name = "Sample Editor:Paste Sample from Clipboard",
    invoke = handlers.paste_sample_from_clipboard
  }
end

return M 