# Port of Amiga emulator "Minimig"

Started from Minimig_ECS for Fleasystems "Ohm" board
and making it more portable to work on Altera, Lattice
and Xilinx. Also used to test compatibility of various
vendors and boards when running a complex project.

    Altera Cyclone-V (5CEBA4F23C7)
    Lattice ECP5 (LFE5U-25F-6BG381C and LFE5U-45F-6BG381C)
    Xilinx Artix-7 (XC7A100T-FGG484-2)

Keyboard driver modified not to control keyboard LEDs
to avoid compatibility issues with various keyboard.

VGA to HDMI converter is replaced from "snake" template
because original video output didn't make monitor sync.
New video doesn't have hdmi-audio.

Except clock PLL generators, most (if not all) vendor specific
RAM/ROMs are converted to generic vhdl with python scripts
and other modules slightly adjusted to use new generic modules.

There is a script which unzips original archive, removes
unneed files and converts some binaries to generic vhdl.

# SD browser menu

Press all 4 cursor buttons together at the same time and
Minimig menu will appear where you can browse SD card to
load *.adf files and change Minimig emulation parameters.

OSD menu is running on auxililary 68k CPU. It's source is here:
[minimig_tc64](https://github.com/robinsonb5/minimig_tc64)

# WIP

* Run `unzip_clean_generic.sh` to unzip the core source files.
