# electronic-geartrain

A CNC 4th axis project. Inspired by a [youtube video](https://www.youtube.com/watch?v=7WleHVtIc1c) about building a hobbing attachment.
This project will have more complex electronics so it can also be used other ways. The project is intended to be used on a manual mill  
with out any CNC capabilites. Signals from linear scales are used for some modes.

## modes
1. Dividing head - move to a rotational position and hold.
2. Helical milling attachment - maintain rotational position proportional to the position of a linear axis.
3. Gear Hobbing attachment - syncronize the spindexer spindle RPM proportional to the main spindle RPM.

## parts
1. [Seeed Spartan Edge Accelerator](https://wiki.seeedstudio.com/Spartan-Edge-Accelerator-Board/#encrypted-internet-of-things)
1. Spindexer
2. a few encoders (models tbd)
    * TTL linear glass scales already installed on the mill.
    * A hall effect sensor and magnet creating a diy 1 p/r encoder on the main spindle.
    * A rotational quadrature encoder on the spindexer's spindle.
4. a stepper motor (model whatever my makerspace has)
5. a [GeckoDrive stepper controller](https://www.geckodrive.com/products). (model tbd)
6. Power supply (tbd)
7. SD card
8. Other electronic parts not selected yet

## Tools Used
1. Xilinx Vivado
2. Arduino IDE (programming the sp32 included on the board).

## TBD
1. Do we need a brake?
2. What kind of transmission between the stepper and the spindexer
    * Worm and wheel would be resistant to back-drive but may limit top speed.
    * What kind of gear ratio would be useful (dividing heads use 40:1)
3. What kind of top speed and holding torque do the stepper provide.
