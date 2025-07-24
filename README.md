# HexToolsRenoise

This repository contains example tools for the Renoise digital audio workstation.

## Hello World Tool

`HelloWorldTool.xrnx` is a minimal Renoise tool that adds a menu entry under
**Tools** called **Hello World Tool**. Selecting **Show Hello** displays
"Hello, world!" in Renoise's status bar.

### Installation

1. Copy the `HelloWorldTool.xrnx` directory into your Renoise `Tools`
   folder. Renoise will detect the tool automatically.
2. In Renoise, open the `Tools` menu and choose `Hello World Tool > Show Hello`.

For more details about developing Renoise tools, see the [official API
documentation](https://renoise.github.io/xrnx/API/index.htm).
