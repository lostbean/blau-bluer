# PCB making

Single-sided PCBs on the modified printer, in two passes with a manual tool
change in between:

1. **Draw** the traces with a permanent marker (PILOT, 1.0 mm tip) acting as
   etch resist.
2. **Drill** the holes with the 775-motor spindle (mount:
   [`mods/motor-775-holder`](../mods)).

A laser-based workflow (using [`mods/laser-holder`](../mods)) will be added
here later.

This folder holds the printer-specific pieces — the pcb2gcode configs with the
tuned feeds and depths, and the G-code pre/postambles that handle zeroing and
the pen→drill offset:

| File                     | Used by     | Purpose                                                                |
| ------------------------ | ----------- | ---------------------------------------------------------------------- |
| `pen-drawing.cfg`        | marker pass | Fills the traces (inverted Gerber) with 0.4 mm marker lines            |
| `drill.cfg`              | drill pass  | Excellon → G-code, with pauses for bit changes                         |
| `preamble.ngc`           | marker pass | Pauses to position the pen, zeroes axes, draws a tip-cleaning triangle |
| `preamble_for_drill.ngc` | drill pass  | Moves by the calibrated pen→drill offset, pauses, re-zeroes            |
| `postamble.ngc`          | both        | Returns to home                                                        |

An example KiCad project made with this process lives in
[autofascination/living-blinds/PCB](https://github.com/lostbean/autofascination/tree/master/living-blinds/PCB).

## 1. Design (KiCad)

- Set the **Drill/Place File Origin** to the lower-right corner of the PCB.
- Export from **File → Plot**: the back copper Gerber (`*-B_Cu.gbr`) for
  drawing, and the Excellon drill file (`*.drl`), with these options enabled:
  - _Use drill/place file origin_
  - _Use alternate drill mode_
  - _PTH and NPTH in a single file_

## 2. Generate G-code (pcb2gcode)

Point the project paths at the top of `pen-drawing.cfg` and `drill.cfg` to
your exported files, then run from this folder:

```bash
pcb2gcode --config pen-drawing.cfg && pcb2gcode --config drill.cfg
```

Preview the result at [NCViewer](https://ncviewer.com/).

Values tuned on this printer — change with care:

- **Marker pass** — `zwork=-0.05` (tip just touching), `mill-feed=600`,
  `mill-diameters=0.4mm` (the line width the marker draws),
  `milling-overlap=25%`. `invert-gerbers=true` with a huge `isolation-width`
  fills the traces with ink instead of isolation-milling around them.
- **Drill pass** — `zdrill=-2.5` (through the board into the sacrificial
  layer), `drill-feed=200`, `zsafe=5`, `zchange=30` (lift for bit changes).
  `software=custom` + `nog81=true` because Marlin has no canned drill cycles.

## 3. Calibrate the pen→drill offset

Needed once per holder setup; the result goes into `preamble_for_drill.ngc`.

1. Place the drill bit in the chuck and lower the Z-axis until the bit is
   close to a sacrificial area.
2. Using OctoPrint (or the printer panel), jog back and forth along all axes
   so every motor is energized and holds its position.
3. Lower the Z-axis and drill a small hole to mark the drilling X/Y home
   position.
4. Send `G92 X0 Y0 Z0` to set the current position as home.
5. Raise the Z-axis, remove the drill bit, and mount the pen.
6. Jog the pen tip to that same hole and lower Z until the tip touches,
   aligned with the hole.
7. Send `M114` and note the X and Y values.
8. Put those values in the `G00 X… Y…` line of `preamble_for_drill.ngc`.

## 4. Draw and drill

The generated files include pauses (`M0`) for positioning and tool changes.

1. Upload both G-code files to the printer (OctoPrint recommended).
2. Mount the pen and manually position it at the lower-left corner of the
   board, leaving a few mm of margin so it can't draw off the PCB. Adjust Z so
   the tip is **touching** the board — 0.2–0.5 mm below the touching point is
   fine, but lower than that tilts the pen during drawing or damages the tip.
3. Start the `*-B_Cu.gbr.gcode` file. After the positioning pause it zeroes
   the axes, draws a triangular marker to clean the tip, then draws the
   traces.
4. When drawing finishes the pen returns to its start position. Raise Z and
   swap the pen for the drill bit. **Do not move X or Y** — the drill G-code
   repositions itself from the drawing home.
5. Start the `*.drl.gcode` file. It pauses, then moves by the calibrated
   offset to the drilling home position.
6. At the next pause, manually lower Z until the bit **touches** the board,
   and check it lines up with the triangular marker.
7. Resume. The printer drills all the holes, pausing whenever a different bit
   diameter is needed.

## 5. Etch

Etching happens off-printer: the marker ink is the resist, so etch the board
(e.g. ferric chloride) and clean off the ink afterwards.
