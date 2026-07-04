# PCB making

Single-sided PCBs on the modified printer, in three stages:

1. **Paint** the whole copper side with a permanent marker / spray as etch
   resist.
2. **Laser** away the resist over everything that should be etched, leaving
   ink only on the traces (mount: [`mods/laser-holder`](../mods)).
3. **Drill** the holes with the 775-motor spindle (mount:
   [`mods/motor-775-holder`](../mods)).

Then etch off-printer (ferric chloride / iron perclorate) and clean the
remaining ink.

> An earlier workflow drew the traces directly with a pen instead of
> painting + lasering. Those files are still here
> (`pen-drawing.cfg`, `preamble.ngc`, `preamble_for_drill.ngc`) but the laser
> flow below is the current one.

> **Drilling now has a browser app.** The manual alignment + pcb2gcode drill
> flow documented below is superseded for the drill pass by
> **[blau-drill](https://github.com/lostbean/blau_drill)**, which fits the
> fiducials into an affine transform (no touch-off `G92`), forces a dry-run
> before the real run, and streams to the printer over Web Serial. Run it at
> <https://onedgy.com/lab/blau-drill/>. The design rationale is written up in
> the post [From Ritual to Software](https://onedgy.com/blog/blau-drill/). The
> configs below are still the reference for the etch/laser pass and the manual
> fallback.

This folder holds the printer-specific pieces — the pcb2gcode config with
tuned feeds and depths, the G-code preamble that handles touch-off and
zeroing, and a post-processor that adapts pcb2gcode's output to this
printer's Marlin.

| File                       | Purpose                                                             |
| -------------------------- | ------------------------------------------------------------------- |
| `drill.cfg`                | pcb2gcode config: Excellon → G-code for the drill pass              |
| `preamble_laser_drill.ngc` | Touch-off + `G92` zero on a fiducial (no pen→drill offset)          |
| `postamble.ngc`            | Returns to home                                                     |
| `postprocess_drill.py`     | Fixes spindle command for Marlin; emits a dry-run + real-drill pair |
| `pen-drawing.cfg`          | (legacy) pen pass — fills inverted Gerber with marker lines         |
| `preamble.ngc`             | (legacy) pen pass — pause, zero, tip-cleaning triangle              |
| `preamble_for_drill.ngc`   | (legacy) pen→drill offset preamble                                  |

An example KiCad project made with the pen process lives in
[autofascination/living-blinds/PCB](https://github.com/lostbean/autofascination/tree/master/living-blinds/PCB).

## 1. Design (KiCad)

- Put **fiducials on all four corners** of the board, on the copper side you
  drill from (back copper). Use a copper fiducial footprint (e.g.
  `Fiducial:Fiducial_BCu_Cross_1.5mm_Mask2mm`). Corner fiducials are the
  alignment reference — and unlike the board edge, **they survive etching**,
  so you can still register to them after the outline copper is gone.
- Set the **Drill/Place File Origin** onto one of those corner fiducials
  (not the bare corner). That fiducial becomes the drill-file origin and your
  physical touch-off point.
- Export from **File → Fabrication Outputs → Drill Files** with:
  - Format **Excellon**
  - _Use drill/place file origin_
  - _PTH and NPTH in a single file_ (so you get one `*.drl`, not `-PTH`/`-NPTH`)
  - _Use alternate drill mode for oval holes_
  - **Do not** enable _Mirror Y axis_ — pcb2gcode handles the back-side mirror
    itself (`drill-side=back`). Mirroring here would flip the holes out of the
    reachable frame.

  Sanity check the exported `.drl`: coordinates should be small and centred on
  the chosen fiducial (one axis going negative is fine), not large absolute
  page coordinates (e.g. X135, Y−149) — those mean the drill origin was never
  set.

## 2. Generate G-code (pcb2gcode → post-process)

Point the paths at the top of `drill.cfg` at your exported `.drl`, then run
from that folder. The pcb2gcode in current nixpkgs fails to build against
boost 1.87, so pin the 24.05 channel (it ships a working prebuilt binary):

```bash
nix run github:NixOS/nixpkgs/nixos-24.05#pcb2gcode -- --config drill.cfg
python3 postprocess_drill.py board.drl.gcode --speed 255 --hover 0.2
```

That writes two files:

- `board.dryrun.gcode` — **spindle off**, hovers `--hover` mm above the
  touched-off surface at every hole instead of plunging. Run this first to
  confirm registration without cutting.
- `board.drill.gcode` — the real run: spindle on at full power, plunges to
  `zdrill`.

Preview either at [NCViewer](https://ncviewer.com/).

### Why the post-processor is needed

pcb2gcode (`software=custom`) emits spindle control that does **not** work on
this printer's Marlin: a cosmetic standalone `G00 S<speed>` line plus a bare
`M3`. Marlin needs the duty value **on** the `M3` line (`M3 S255`) or the PWM
is never set ([MarlinFirmware/Marlin#8379](https://github.com/MarlinFirmware/Marlin/issues/8379)).
The spindle now shares the **laser PWM hardware**, so it is driven directly by
G-code rather than an external controller. `postprocess_drill.py` rewrites the
spindle command, builds the dry-run variant, and can set the touch-off `G92`
to a fiducial position (`--fiducial`, see below).

Values tuned on this printer — change with care:

- `zdrill=-2.5` (through the board into the sacrificial layer),
  `drill-feed=200`, `zsafe=5`, `zchange=30` (lift for bit changes).
- `software=custom` + `nog81=true` because Marlin has no canned drill cycles.
- `drill-speed=255` = full PWM duty (Marlin `CUTTER_POWER_UNIT=PWM255`).

## 3. Align to the fiducial

The drill file's origin is on a corner fiducial, so the fiducial corresponds
to the origin of the G-code frame. In the simple case (origin fiducial maps
to G-code `(0,0)`), the preamble's plain `G92 X0 Y0 Z0` at touch-off is
correct, and holes on the far side may sit at slightly negative coordinates —
the machine accommodates that after the local `G92`.

If the fiducial you align to maps to a non-zero corner of the hole envelope
(e.g. because of the back-side X mirror), let the post-processor read that
corner from the G-code and bake it into the preamble's `G92` — no CAD lookup:

```bash
python3 postprocess_drill.py board.drl.gcode --fiducial bl   # bl|br|tl|tr
```

`--fiducial bl` sets `G92 X<minX> Y<minY> Z0` (the min-X/min-Y hole-envelope
corner), so touching off there tells Marlin where the fiducial is and every
hole lands relative to it. Pick the corner that the back-side mirror maps your
chosen fiducial to (for a KiCad lower-right fiducial drilled from the back,
that is `bl`). Verify in the post-processor's printed hole-envelope numbers.

## 4. Drill

The generated files include pauses (`M0`) — one at touch-off, and one per bit
size change.

1. Upload `board.dryrun.gcode` and `board.drill.gcode` to the printer
   (OctoPrint recommended).
2. Mount the drill bit. At the first pause, position the bit over the corner
   fiducial and lower Z until it just touches.

   **Energize the motors before the final adjustment.** When the steppers are
   de-energized (idle) and then re-engage, they snap to the nearest full step
   and jump 1–2 mm — enough to ruin alignment. So make the _final_ X/Y nudge
   with the motors already on, using the printer's jog/move control, rather
   than pushing the head by hand and letting it re-engage. Jog each axis a
   little first to make sure every motor is holding, then fine-tune onto the
   fiducial.

3. Resume. The preamble runs `G92` to set the fiducial as the zero reference.
4. **Run the dry run first** (`board.dryrun.gcode`). The bit hovers
   `--hover` mm above every hole so you can confirm the pattern lines up with
   the board. There are still per-bit pauses — just resume through them; you
   are not changing bits during a dry run.
5. If registration is good, run `board.drill.gcode`. It drills every hole,
   pausing at each bit-diameter change so you can swap the bit. **Do not move
   X/Y at the bit-change pauses** — only swap the bit and re-touch Z.

## 5. Etch

Etching happens off-printer: the remaining marker ink is the resist, so etch
the board (ferric chloride / iron perclorate) and clean off the ink
afterwards.
