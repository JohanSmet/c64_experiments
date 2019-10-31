# C64 experiments
This repository collects the small programs I write while learning 6502 assembly and C64 development. 
I only do this sporadically, so this is mostly overdocumented code to make it easy to refresh my memory ;-)

Seasoned C64 vets will probably frown at most of this code. If you've got (constructive) criticims, please don't hesitate to drop my a line.

## License
All code in this repository is provided under the 3-clause BSD license unless stated otherwise.

## Tools
Nothing fancy here, cross-developing on a linux machine using [64tass](https://sourceforge.net/projects/tass64/). 
I use neovim with 6502 highlighting as an editor and [Vice](http://vice-emu.sourceforge.net/) to run the programs.

## Resources
A lot of 6502 and C64 tutorials from around the web. I'll do my best to link them here.
 - [kodiak64](https://kodiak64.com/)
 - [DustLayer](https://dustlayer.com/c64-coding-tutorials/)
 - [New Old Things](https://www.gamedev.net/blogs/blog/949-new-old-things/)

Useful links:
 - [Commodore 64 memory map](http://sta.c64.org/cbm64mem.html)
 - [C64 Wiki](https://www.c64-wiki.com)
 - [Codebase64](https://codebase64.org)

## Overview

| Directory | Explanation |
| --------- | ----------- | 
| scripts   | scripts I use while developing |
| demo01    | Clear the screen of the C64    |
| demo02    | Write text to the screen       |
| demo03    | Raster interrupts and simple animation |
| demo04    | A little more interesting animation |
| demo05    | Keyboard input without using the Kernal |

