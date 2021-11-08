# electronic-geartrain

A CNC 4th axis project. Inspired by a [youtube video](https://www.youtube.com/watch?v=7WleHVtIc1c) about building a hobbing attachment.
This project will have more complex electronics so it can also be used other ways. The project is intended to be used on a manual mill  
with out any CNC capabilites. Signals from linear scales are used for some modes.

oxtools explaining helical milling and doing a similar project [here](https://www.youtube.com/watch?v=AVydTvwqmRs)

## modes
1. Dividing head - move to a rotational position and hold.
2. Helical milling attachment - maintain rotational position proportional to the position of a linear axis.
3. Gear Hobbing attachment - syncronize the spindexer spindle RPM proportional to the main spindle RPM.

## parts
1. Xilinx Spartan 7 FPGA
2. ESP32-d0wd SOC
3. [TFT LCD MODULE](https://www.lcd-module.com/fileadmin/eng/pdf/grafik/ediptft57-ae.pdf)
4. [Hall effect Sensor](https://www.littelfuse.com/~/media/electronics/datasheets/hall_effect_sensors/littelfuse_hall_effect_sensors_55100_datasheet.pdf.pdf)
5. Spindexer
6. a few encoders (models tbd)
    * TTL linear glass scales already installed on the mill.
    * A rotational quadrature encoder on the spindexer's spindle.
7. a stepper motor (model whatever my makerspace has)
8. a [GeckoDrive stepper controller](https://www.geckodrive.com/products). (model tbd)
9. Power supply
10. Other electronic parts not selected yet

## Tools Used
1. Xilinx Vivado
2. Arduino IDE (programming the sp32 included on the board).
3. KiCAD

## TBD
1. Do we need a brake?
2. What kind of transmission between the stepper and the spindexer
    * Worm and wheel would be resistant to back-drive but may limit top speed.
    * What kind of gear ratio would be useful (dividing heads use 40:1)
3. What kind of top speed and holding torque do the stepper provide.
