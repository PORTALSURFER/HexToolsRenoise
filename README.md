# HexTools for Renoise

**Author:** Hex  
**Version:** v0.2.0

Collection of useful tools for the Renoise digital audio workstation.

## Features

HexTools adds the following utilities and workflow enhancements to Renoise:

### **Track Management & Navigation**
- **Smart Track Collapsing**: Automatically collapse null tracks (empty tracks) with color coding
  - **Active tracks**: Blue color for tracks with notes
  - **Null tracks**: Gray color for empty/collapsed tracks  
  - **Focused tracks**: Red tint for currently selected tracks
- **Intelligent Track Navigation**: 
  - Jump between active tracks while skipping null tracks
  - Jump between null tracks for quick access to empty tracks
  - Auto-collapse before navigation (toggleable)
- **Pattern State Tracking**: Remembers collapsed/expanded state per pattern
- **Focus Management**: Automatically handles track focus states and color transitions

### **Pattern Matrix Tools**
- **Pattern Matrix Slot Coloring**: Color selected pattern matrix grid slots with random theme colors
  - Select individual track slots in the pattern matrix
  - Apply consistent random colors from the current theme palette
  - Accessible via Pattern Matrix menu or keybinding

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

### **Note Velocity Tools**
- **Increase/Decrease Velocity**: Adjust velocity of selected notes by 10 or by 1 for fine adjustment
- **Sensitive Velocity Control**: Precise velocity adjustment for detailed editing

### **Automation Tools**
- **Focus Automation Editor**: Focus the automation editor for the current pattern selection
- **Convert Automation to Pattern**: Convert automation envelopes to pattern data (and remove the envelope)
- **Convert Pattern to Automation**: Convert pattern effect columns to automation envelopes (and clear the effect columns)

### **Pattern Editing**
- **Double Pattern Length**: Duplicate the first half of a pattern to double its length
- **Halve Pattern Length**: Reduce pattern length by half, preserving the first half
- **Change LPB**: Modify Lines Per Beat while maintaining note timing relationships

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
- `Pattern Editor:Tools:Find Duplicate Single-Sample Instruments`
- `Pattern Editor:Tools:Merge Instruments`
- `Pattern Editor:Tools:Remap Instruments`
- `Pattern Editor:Tools:Increase Velocity`
- `Pattern Editor:Tools:Decrease Velocity`
- `Pattern Editor:Tools:Increase Velocity (Sensitive)`
- `Pattern Editor:Tools:Decrease Velocity (Sensitive)`
- `Pattern Editor:Tools:Focus Automation Editor for Selection`
- `Pattern Editor:Tools:Convert Automation To Pattern`
- `Pattern Editor:Tools:Convert Pattern To Automation`
- `Pattern Editor:Tools:Collapse Unused Tracks in Pattern` *(toggles collapse/expand)*
- `Pattern Editor:Tools:Jump To Next Track (Skip Collapsed)`
- `Pattern Editor:Tools:Jump To Previous Track (Skip Collapsed)`
- `Pattern Editor:Tools:Jump To Next Collapsed Track`
- `Pattern Editor:Tools:Jump To Previous Collapsed Track`
- `Pattern Editor:Tools:Toggle Auto-Collapse Before Jump`
- `Pattern Editor:Tools:Toggle Auto-Collapse On Focus Loss`
- `Pattern Editor:Tools:Double Pattern Length`
- `Pattern Editor:Tools:Halve Pattern Length`
- `Pattern Editor:Tools:Change LPB`
- `Pattern Editor:Tools:Color Selected Pattern Slots`

### **Pattern Matrix Tools**
- `Pattern Matrix:Color Selected Pattern Slots`

## Installation

1. Copy the `HexTools.xrnx` directory into your Renoise `Tools` folder. Renoise will detect the tool automatically.
2. In Renoise, open the `Tools` menu and choose `HexTools > ...`.

For more details about developing Renoise tools, see the [official API documentation](https://renoise.github.io/xrnx/API/index.htm).

## Technical Details

### **Track State Management**
- **Active tracks**: Tracks containing notes (blue color)
- **Null tracks**: Empty tracks that can be collapsed (gray color)
- **Focused tracks**: Currently selected tracks (red tint)
- **Auto-collapse**: Automatically collapses null tracks before navigation
- **Focus management**: Handles track state transitions and color changes

### **Pattern Matrix Coloring**
- Uses theme colors from the current Renoise skin
- Supports selection of individual track slots in the pattern matrix
- Applies consistent random colors to selected slots
- Integrates with the pattern sequencer selection system

## Mentions

- [esaruoho/paketti](https://github.com/esaruoho/paketti): A great collection of Renoise tools and a source of inspiration for this project.
