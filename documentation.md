# HexTools Documentation

**Author:** Hex  
**Version:** v0.3.3  

Complete documentation for HexTools features and functionality.

## Features

HexTools adds the following utilities and workflow enhancements to Renoise:

### **Track Management & Navigation**
- **Smart Track Collapsing**: Automatically collapse null tracks (empty tracks) with color coding
  - **Active tracks**: Blue color for tracks with notes (previously orange)
  - **Null tracks**: Gray color for empty/collapsed tracks (previously dark grey)
  - **Focused tracks**: Red tint for currently selected tracks
- **Intelligent Track Navigation**: 
  - Jump between active tracks while skipping null tracks
  - Jump between null tracks for quick access to empty tracks
  - Move to next track (skip collapsed) - alternative navigation method
  - Jump to next track with solo - automatically solos the target track
  - Jump to previous track with solo - automatically solos the target track
  - Auto-collapse before navigation (toggleable)
- **Pattern State Tracking**: Remembers collapsed/expanded state per pattern
- **Focus Management**: Automatically handles track focus states and color transitions

### **Pattern Matrix Tools**
- **Pattern Matrix Slot Coloring**: Color selected pattern matrix grid slots with random theme colors
  - Select individual track slots in the pattern matrix
  - Apply consistent random colors from the current theme palette
  - Accessible via Pattern Matrix menu or keybinding
- **Pattern Matrix Remove Empty Tracks**: Remove tracks that have no notes across all patterns
  - Scans all patterns in the song for empty tracks
  - Removes tracks that contain no musical notes (1-120)
  - Useful for cleaning up unused tracks after composition
  - Accessible via Pattern Matrix menu or keybinding
- **Pattern Matrix Track Solo**: Solo tracks that have selected slots in the pattern matrix
  - Select multiple pattern matrix slots across different tracks
  - Automatically mutes all other tracks and solos the selected tracks
  - Accessible via Pattern Matrix menu or keybinding
- **Pattern Matrix Track Merge**: Advanced merging functionality for pattern matrix selections
  - Select multiple pattern matrix slots across different tracks and patterns
  - Renders audio from selected tracks to a single new track with C-4 notes
  - Automatically skips patterns with no musical notes in selected tracks
  - Filters out special Renoise note values (only counts actual musical notes 1-120)
  - Sequential rendering to avoid "rendering already in progress" errors
  - **Pattern-level alias detection**: Skips re-rendering if same pattern already processed
  - **Track-level alias detection**: Skips re-rendering if same track combination already processed
  - **Chronological processing**: Patterns processed in sequence order, not pattern index order
  - Accessible via Pattern Matrix menu or keybinding
- **Pattern Matrix Track Merge Destructive**: Same as merge but removes source tracks
  - Performs the same merge operation as above
  - **Smart cleanup**: Only deletes patterns that were selected and merged
  - **Preserves unselected content**: Tracks with content in unselected patterns are preserved
  - **Removes only empty tracks**: Only removes tracks that become completely empty after pattern deletion
  - Useful for cleaning up after merging

### **Rendering & Playback**
- **Render Selection to New Track**: Renders the current pattern selection to a new instrument and track, inserting a C-4 note. Optionally, the original selection can be cleared (destructive render).
- **Render Selection to Next Track**: Renders the current pattern selection to a new instrument and the next existing track, inserting a C-4 note. Optionally, the original selection can be cleared (destructive render).
- **Playhead Buffering**: Store the current playhead position and return to it later, or play from a buffered position.
- **Jump to Test Position**: Quickly jump the playhead to a test location in the song.

### **Instrument Utilities**
- **Find Duplicate Single-Sample Instruments**: Find instruments with identical waveforms
- **Merge Instruments**: Merge multiple instruments into one, reassigning pattern references
- **Remap Instruments**: Remap pattern instrument references to a new instrument, with optional deletion of old instruments
- **Remap Selected Notes**: Remap selected notes to the currently selected instrument
- **Render Selection to Instrument Sample**: Render the current pattern selection to a new sample in the selected instrument (accumulation mode)

### **Note Velocity Tools**
- **Increase/Decrease Velocity**: Adjust velocity of selected notes by 10 or by 1 for fine adjustment
- **Sensitive Velocity Control**: Precise velocity adjustment for detailed editing
- **Mute Notes Toggle**: Toggle note velocity between 0 and original/full velocity
  - Mutes notes with velocity > 0 by setting velocity to 0
  - Unmutes notes with velocity = 0 by restoring original velocity or setting to full
  - Buffers original velocities for accurate restoration
  - Works on pattern selection in the pattern editor

### **Automation Tools**
- **Focus Automation Editor**: Focus the automation editor for the current pattern selection
- **Convert Automation to Pattern**: Convert automation envelopes to pattern data (and remove the envelope)
- **Convert Pattern to Automation**: Convert pattern effect columns to automation envelopes (and clear the effect columns)

### **Pattern Editing**
- **Double Pattern Length**: Duplicate the first half of a pattern to double its length
- **Halve Pattern Length**: Reduce pattern length by half, preserving the first half
- **Change LPB**: Modify Lines Per Beat while maintaining note timing relationships

### **Menu Integration**
- **All features accessible** from the Renoise Tools menu or Pattern Editor context menus
- **Track Visibility Toggle**: Collapse all unused tracks in the current pattern, or expand all tracks if any are collapsed

## Usage Tips

### **Track Navigation Workflow**
1. **Collapse null tracks** using the collapse tool (tracks turn blue/gray)
2. **Jump between active tracks** using the jump functions (automatically skips null tracks)
3. **Jump between null tracks** to quickly access empty tracks for new content
4. **Toggle auto-collapse** if you want manual control over when tracks collapse

### **Pattern Matrix Coloring Workflow**
1. **Select pattern matrix slots** by clicking on individual track slots in the pattern matrix
2. **Apply random colors** using the coloring tool to visually organize your patterns
3. **Use theme colors** that automatically match your current Renoise skin

### **Pattern Matrix Merge Workflow**
1. **Select pattern matrix slots** across different tracks and patterns
2. **Use merge tool** to render audio to a single new track
3. **Use destructive merge** to clean up source tracks (only removes selected patterns)
4. **Tracks with unselected content are preserved** automatically

### **Recommended Keybindings**
- `Ctrl+Right Arrow` - Jump to next active track (skip null tracks)
- `Ctrl+Left Arrow` - Jump to previous active track (skip null tracks)
- `Ctrl+Shift+Right Arrow` - Jump to next null track
- `Ctrl+Shift+Left Arrow` - Jump to previous null track
- `Ctrl+Shift+C` - Toggle track collapse/expand
- `Ctrl+Shift+A` - Toggle auto-collapse before jump
- `Ctrl+Shift+O` - Toggle auto-collapse on focus loss

## Keymaps

All features below can be mapped to custom keys in Renoise via the Preferences > Keys dialog:

### **Pattern Editor Tools**
- `Pattern Editor:Tools:Play And Return Toggle`
- `Pattern Editor:Tools:Set Playhead Buffer`
- `Pattern Editor:Tools:Play From Buffer`
- `Pattern Editor:Tools:Render Selection To New Track`
- `Pattern Editor:Tools:Render Selection To New Track Destructive`
- `Pattern Editor:Tools:Render Selection To Next Track`
- `Pattern Editor:Tools:Render Selection To Next Track Destructive`
- `Pattern Editor:Tools:Sample And Merge Track Notes`
- `Pattern Editor:Tools:Find Duplicate Single-Sample Instruments`
- `Pattern Editor:Tools:Jump To Next Track (Skip Collapsed)`
- `Pattern Editor:Tools:Jump To Previous Track (Skip Collapsed)`
- `Pattern Editor:Tools:Move To Next Track (Skip Collapsed)`
- `Pattern Editor:Tools:Jump To Next Track (With Solo)`
- `Pattern Editor:Tools:Jump To Previous Track (With Solo)`
- `Pattern Editor:Tools:Color Selected Pattern Slots`
- `Pattern Editor:Tools:Mute Notes Toggle`
- `Pattern Matrix:Tools:Remove Empty Tracks`
- `Pattern Matrix:Tools:Solo Selected Tracks`
- `Pattern Matrix:Tools:Merge Selected Tracks`
- `Pattern Matrix:Tools:Merge Selected Tracks Destructive`

### **Main Menu Tools**
- `Main Menu:Tools:HexTools:Show Hello`
- `Main Menu:Tools:HexTools:Export Keybindings (Markdown)`
- `Main Menu:Tools:HexTools:Set Playhead Buffer`
- `Main Menu:Tools:HexTools:Play From Buffer`
- `Main Menu:Tools:HexTools:Jump To Buffered Play Line`
- `Main Menu:Tools:HexTools:Collapse Unused Tracks in Pattern`
- `Main Menu:Tools:HexTools:Remove Empty Tracks`
- `Main Menu:Tools:HexTools:Jump To Next Track (Skip Collapsed)`
- `Main Menu:Tools:HexTools:Jump To Previous Track (Skip Collapsed)`
- `Main Menu:Tools:HexTools:Move To Next Track (Skip Collapsed)`
- `Main Menu:Tools:HexTools:Jump To Previous Track (With Solo)`
- `Main Menu:Tools:HexTools:Jump To Next Track (With Solo)`
- `Main Menu:Tools:HexTools:Jump To Next Collapsed Track`
- `Main Menu:Tools:HexTools:Jump To Previous Collapsed Track`
- `Main Menu:Tools:HexTools:Jump Quarter Up`
- `Main Menu:Tools:HexTools:Jump Quarter Down`
- `Main Menu:Tools:HexTools:Toggle Auto-Collapse Before Jump`
- `Main Menu:Tools:HexTools:Toggle Auto-Collapse On Focus Loss`
- `Main Menu:Tools:HexTools:Render Selection To New Track`
- `Main Menu:Tools:HexTools:Render Selection To New Track Destructive`
- `Main Menu:Tools:HexTools:Render Selection To Next Track`
- `Main Menu:Tools:HexTools:Render Selection To Next Track Destructive`
- `Main Menu:Tools:HexTools:Render Selection To Copy Buffer`
- `Main Menu:Tools:HexTools:Clear Sample Clipboard`
- `Main Menu:Tools:HexTools:Sample And Merge Track Notes`
- `Main Menu:Tools:HexTools:Find Duplicate Single-Sample Instruments`
- `Main Menu:Tools:HexTools:Merge Instruments`
- `Main Menu:Tools:HexTools:Remap Instruments`
- `Main Menu:Tools:HexTools:Remap Selected Notes to This`
- `Main Menu:Tools:HexTools:Render Selection To Instrument Sample`
- `Main Menu:Tools:HexTools:Double Pattern Length`
- `Main Menu:Tools:HexTools:Halve Pattern Length`
- `Main Menu:Tools:HexTools:Change LPB`
- `Main Menu:Tools:HexTools:Nudge Note Up`
- `Main Menu:Tools:HexTools:Nudge Note Down`
- `Main Menu:Tools:HexTools:Expand Selection To Full Pattern`
- `Main Menu:Tools:HexTools:Mute Notes Toggle`
- `Main Menu:Tools:HexTools:Color Selected Pattern Slots`
- `Main Menu:Tools:HexTools:Focus Automation Editor for Selection`
- `Main Menu:Tools:HexTools:Convert Automation To Pattern`
- `Main Menu:Tools:HexTools:Convert Pattern To Automation`

### **Pattern Matrix Tools**
- `Pattern Matrix:Color Selected Pattern Slots`
- `Pattern Matrix:Remove Empty Tracks`
- `Pattern Matrix:Solo Selected Tracks`
- `Pattern Matrix:Merge Selected Tracks`
- `Pattern Matrix:Merge Selected Tracks Destructive`

### **Pattern Editor Tools**
- `Pattern Editor:Focus Automation Editor for Selection`
- `Pattern Editor:Convert Automation To Pattern`
- `Pattern Editor:Convert Pattern To Automation`
- `Pattern Editor:Sample And Merge Track Notes`
- `Pattern Editor:Double Pattern Length`
- `Pattern Editor:Halve Pattern Length`

### **Instrument Box Tools**
- `Instrument Box:Remap Selected Notes to This`

### **Sample Editor Tools**
- `Sample Editor:Paste Sample from Clipboard` 