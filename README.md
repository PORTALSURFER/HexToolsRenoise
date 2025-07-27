# HexTools for Renoise

**Author:** Hex  
**Version:** v0.1.0

Collection of useful tools for the Renoise digital audio workstation.

## Features

HexTools adds the following utilities and workflow enhancements to Renoise:

- **Render Selection to New Track**: Renders the current pattern selection to a new instrument and track, inserting a C-4 note. Optionally, the original selection can be cleared (destructive render).
- **Render Selection to Next Track**: Renders the current pattern selection to a new instrument and the next existing track, inserting a C-4 note. Optionally, the original selection can be cleared (destructive render).
- **Playhead Buffering**: Store the current playhead position and return to it later, or play from a buffered position.
- **Jump to Test Position**: Quickly jump the playhead to a test location in the song.
- **Instrument Utilities**:
  - Find duplicate single-sample instruments (by waveform).
  - Merge multiple instruments into one, reassigning pattern references.
  - Remap pattern instrument references to a new instrument, with optional deletion of old instruments.
  - Remap selected notes to the currently selected instrument.
- **Note Velocity Tools**:
  - Increase/decrease velocity of selected notes (by 10 or by 1, for fine adjustment).
- **Automation Tools**:
  - Focus the automation editor for the current pattern selection.
  - Convert automation envelopes to pattern data (and remove the envelope).
  - Convert pattern effect columns to automation envelopes (and clear the effect columns).
- **Menu Integration**: All features are accessible from the Renoise Tools menu or Pattern Editor context menus.

## Keymaps

All features below can be mapped to custom keys in Renoise via the Preferences > Keys dialog:

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

## Installation

1. Copy the `HexTools.xrnx` directory into your Renoise `Tools` folder. Renoise will detect the tool automatically.
2. In Renoise, open the `Tools` menu and choose `HexTools > ...`.

For more details about developing Renoise tools, see the [official API documentation](https://renoise.github.io/xrnx/API/index.htm).

## Mentions

- [esaruoho/paketti](https://github.com/esaruoho/paketti): A great collection of Renoise tools and a source of inspiration for this project.
