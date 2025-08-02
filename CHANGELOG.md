# Changelog

All notable changes to HexTools will be documented in this file.

## [0.3.2] - 2024

### Added
- **Pattern Matrix Track Merge**: Advanced merging functionality for pattern matrix selections
  - Select multiple pattern matrix slots across different tracks and patterns
  - Renders audio from selected tracks to a single new track with C-4 notes
  - Automatically skips patterns with no musical notes in selected tracks
  - Filters out special Renoise note values (only counts actual musical notes 1-120)
  - Sequential rendering to avoid "rendering already in progress" errors
  - Destructive version removes source tracks after merging
  - Accessible via Pattern Matrix menu or keybinding
- **Enhanced Track Navigation**: Added solo functionality to track navigation
  - Jump to next track with solo - automatically solos the target track
  - Jump to previous track with solo - automatically solos the target track

### Changed
- **Improved Note Detection**: Better filtering of musical vs. special Renoise notes
- **Sequential Rendering**: Fixed rendering conflicts by processing patterns one at a time
- **Master Track Handling**: Fixed "master track cannot be muted" errors in merge functions

### Technical
- **Enhanced Pattern Matrix Integration**: Better integration with Renoise's pattern matrix system
- **Improved Error Handling**: More robust handling of rendering and mute state operations

## [0.3.1] - 2024

### Added
- **Render Selection to Instrument Sample**: Render the current pattern selection to a new sample in the selected instrument (accumulation mode)
  - Similar to SamRender's accumulation mode functionality
  - Adds new samples to the selected instrument without creating new instruments
  - Automatically names samples with descriptive information (sequence, line range, sample number)
  - Enables autoseek for rendered samples

## [0.3.0] - 2024

### Added
- **Pattern Matrix Slot Coloring**: Color selected pattern matrix grid slots with random theme colors
- **Null Track Navigation**: Jump between null (empty) tracks for quick access to empty tracks
- **Enhanced Track State Management**: Improved terminology and color coding system
- **Auto-Collapse for Null Track Navigation**: Automatically collapse patterns before jumping to null tracks
- **Jump To Next Collapsed Track**: Navigate directly to the next collapsed track
- **Jump To Previous Collapsed Track**: Navigate directly to the previous collapsed track
- **Toggle Auto-Collapse On Focus Loss**: Automatically collapse tracks when focus is lost

### Changed
- **Refactored Track Collapse System**: Cleaner terminology and more maintainable code
- **Better Color Management**: Clear distinction between active, null, and focused tracks
- **Enhanced User Experience**: More intuitive navigation and visual feedback
- **Theme Color Integration**: Pattern matrix coloring uses current Renoise skin colors

### Technical
- **Improved Code Organization**: Better function naming and structure
- **Enhanced State Management**: More robust track focus and collapse handling
- **Better Error Handling**: More reliable navigation and state transitions

## [0.2.0] - 2024

### Added
- **Smart Track Collapsing**: Automatically collapse null tracks (empty tracks) with color coding
  - Active tracks: Blue color for tracks with notes
  - Null tracks: Gray color for empty/collapsed tracks
  - Focused tracks: Red tint for currently selected tracks
- **Intelligent Track Navigation**: 
  - Jump between active tracks while skipping null tracks
  - Jump between null tracks for quick access to empty tracks
  - Auto-collapse before navigation (toggleable)
- **Pattern State Tracking**: Remembers collapsed/expanded state per pattern
- **Focus Management**: Automatically handles track focus states and color transitions
- **Collapse Unused Tracks in Pattern**: Collapse tracks that have no notes in the current pattern
- **Jump To Next Track (Skip Collapsed)**: Navigate to next active track, skipping collapsed ones
- **Jump To Previous Track (Skip Collapsed)**: Navigate to previous active track, skipping collapsed ones
- **Toggle Auto-Collapse Before Jump**: Control whether tracks auto-collapse before navigation

### Added
- **Pattern Editing Tools**:
  - **Double Pattern Length**: Duplicate the first half of a pattern to double its length
  - **Halve Pattern Length**: Reduce pattern length by half, preserving the first half
  - **Change LPB**: Modify Lines Per Beat while maintaining note timing relationships

### Added
- **Automation Tools**:
  - **Focus Automation Editor**: Focus the automation editor for the current pattern selection
  - **Convert Automation to Pattern**: Convert automation envelopes to pattern data (and remove the envelope)
  - **Convert Pattern to Automation**: Convert pattern effect columns to automation envelopes (and clear the effect columns)

### Added
- **Note Velocity Tools**:
  - **Increase/Decrease Velocity**: Adjust velocity of selected notes by 10 or by 1 for fine adjustment
  - **Sensitive Velocity Control**: Precise velocity adjustment for detailed editing

### Added
- **Instrument Utilities**:
  - **Find Duplicate Single-Sample Instruments**: Find instruments with identical waveforms
  - **Merge Instruments**: Merge multiple instruments into one, reassigning pattern references
  - **Remap Instruments**: Remap pattern instrument references to a new instrument, with optional deletion of old instruments
  - **Remap Selected Notes**: Remap selected notes to the currently selected instrument

## [0.1.0] - 2024

### Added
- **Rendering & Playback Tools**:
  - **Render Selection to New Track**: Renders the current pattern selection to a new instrument and track, inserting a C-4 note. Optionally, the original selection can be cleared (destructive render).
  - **Render Selection to Next Track**: Renders the current pattern selection to a new instrument and the next existing track, inserting a C-4 note. Optionally, the original selection can be cleared (destructive render).
  - **Playhead Buffering**: Store the current playhead position and return to it later, or play from a buffered position.
  - **Jump to Test Position**: Quickly jump the playhead to a test location in the song.
  - **Play And Return Toggle**: Store current position, play from selection, and return when stopped
  - **Sample And Merge Track Notes**: Sample and merge track notes functionality

### Added
- **Basic Tool Infrastructure**:
  - Initial tool registration and menu system
  - Basic utility functions and helpers
  - Export keybindings functionality (Markdown format)

---

## Key Features by Category

### Track Management & Navigation (v0.2.0+)
- Smart track collapsing with color coding
- Intelligent track navigation (skip collapsed tracks)
- Pattern state tracking
- Focus management

### Pattern Matrix Tools (v0.3.0+)
- Pattern matrix slot coloring with theme colors

### Rendering & Playback (v0.1.0+)
- Render selection to new/next track
- Playhead buffering system
- Play and return functionality

### Instrument Utilities (v0.2.0+)
- Find duplicate instruments
- Merge instruments
- Remap instruments and notes

### Note Velocity Tools (v0.2.0+)
- Increase/decrease velocity
- Sensitive velocity control

### Automation Tools (v0.2.0+)
- Focus automation editor
- Convert between automation and pattern data

### Pattern Editing (v0.2.0+)
- Double/halve pattern length
- Change LPB (Lines Per Beat) 