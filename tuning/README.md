# Bed Level
==========

## Gross level adjustment
First bed level adjustment should be using a piece of paper and the "Level Bed Corners" option on Marlin. This option will bring the nozzle on top of each spring/screew support.
- Before starting, make sure the nozzle doesn't hit the plate when at Z=0.0 by over-compressing the springs (using the knobs under the plate).
- Start the sequence and on each corner put the paper under the nozzle and, while releasing the srping, keep moving the paper in circular motion.
- Stop when the paper starts to get stuck (very suddle feeling) between the plate and the nozzle.
- Repeat the round at least two more times

## Fine mesh level adjustment
This is a fine refinement of the bed level adjustment. It maps the Z variation at different points over the bed creating a Z variation surface to compesate for flatness distortions on the plate.
This process is similar to the process above using the paper but instaed of adjusting the springs, the nozzle will move a high Z possition (normally 0.2mm) and a menu will allow the to adjust the Z position.

After the procedure, store the settings.

## Z offset adjustment
After the bed level adjustment, the Z offset (the distance between the nozzle and the plate) has also to be adjusted. The correct height of the first layer depends of correct Z offset. The Z offset can be configured on the "Bed Z" option.
A GCODE pattern with 5 single layer squares (four on corners and one on the center) is used to validate the correct Z offset.

## References
https://marlinfw.org/docs/gcode/G029-mbl.html
https://teachingtechyt.github.io/calibration.html#firstlayer
https://help.prusa3d.com/en/article/first-layer-calibration_112364/
