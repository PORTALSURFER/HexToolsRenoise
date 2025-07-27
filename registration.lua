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
    name = "Main Menu:Tools:HexTools:Play And Return Toggle",
    invoke = handlers.play_and_return_toggle
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

  renoise.tool():add_keybinding {
    name = "Pattern Editor:Tools:Play And Return Toggle",
    invoke = handlers.play_and_return_toggle
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
end

return M 