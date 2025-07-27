local M = {}

function M.register_menu_and_keybindings(handlers)
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Show Hello",
    invoke = handlers.show_hello
  }

  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Render Selection To New Track",
    invoke = handlers.render_selection_to_new_track
  }

  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Render Selection To New Track Destructive",
    invoke = handlers.render_selection_to_new_track_destructive
  }

  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Set Playhead Buffer",
    invoke = handlers.set_playhead_buffer
  }
  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Play From Buffer",
    invoke = handlers.play_from_buffer
  }

  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Jump To Test Position",
    invoke = handlers.jump_to_test_position
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
    name = "Main Menu:Tools:HexTools:Sample And Merge Track Notes",
    invoke = handlers.sample_and_merge_track_notes
  }

  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Find Duplicate Single-Sample Instruments",
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
    name = "Main Menu:Tools:HexTools:Export Keybindings (Markdown)",
    invoke = handlers.export_keybindings_md
  }

  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Collapse Unused Tracks in Pattern",
    invoke = handlers.collapse_unused_tracks_in_pattern
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
    name = "Main Menu:Tools:HexTools:Toggle Auto-Collapse Before Jump",
    invoke = handlers.toggle_auto_collapse_before_jump
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
    name = "Instrument Box:Remap Selected Notes to This",
    invoke = handlers.remap_selected_notes_to_this
  }

  renoise.tool():add_menu_entry{
    name = "Track:Sample And Merge Track Notes",
    invoke = handlers.sample_and_merge_track_notes
  }

  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:HexTools:Toggle Auto-Collapse On Focus Loss",
    invoke = handlers.toggle_auto_collapse_on_focus_loss
  }

  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Set Playhead Buffer",
    invoke = handlers.set_playhead_buffer
  }
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Play From Buffer",
    invoke = handlers.play_from_buffer
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
    name = "Pattern Editor:Tools:Toggle Auto-Collapse On Focus Loss",
    invoke = handlers.toggle_auto_collapse_on_focus_loss
  }
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
end

return M 