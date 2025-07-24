-- Hello World Tool
-- Adds a menu entry that shows 'Hello, world!' in the status bar.
-- See the Renoise API documentation: https://renoise.github.io/xrnx/API/index.htm

local function show_hello()
  renoise.app():show_status("Hello, world!")
end

renoise.tool():add_menu_entry{
  name = "Main Menu:Tools:Hello World Tool:Show Hello",
  invoke = show_hello
}
