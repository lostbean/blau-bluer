#!/usr/bin/env python3
"""Post-process pcb2gcode drill output for the laser+drill workflow.

pcb2gcode (software=custom) emits spindle control that does not work on
Marlin: a cosmetic standalone `G00 S<speed>` line plus a bare `M3`. Marlin
needs the duty value ON the M3 line (`M3 S255`) or the spindle PWM is never
set (see MarlinFirmware/Marlin#8379). This script fixes that and produces
two ready-to-run files from one pcb2gcode output:

  <name>.drill.gcode   real drill   -- M3 S<speed>, plunges to zdrill
  <name>.dryrun.gcode  dry run      -- spindle OFF, hovers at +HOVER instead
                                        of drilling, so you can confirm every
                                        hole lines up without cutting.

FIDUCIAL ALIGNMENT (--fiducial)
-------------------------------
The board edge is etched away, so you align to a copper fiducial instead of
a corner. The drill file is already exported with its origin ON that
fiducial, so the fiducial corresponds to a CORNER of the hole envelope in the
G-code. We do NOT shift the toolpath; instead we set the preamble's zeroing
G92 to that corner's coordinates. Then at the machine you touch the bit on
the fiducial and resume -- the G92 tells Marlin "the bit is at (Xc,Yc)", and
every hole lands correctly relative to the fiducial.

    --fiducial bl|br|tl|tr   which hole-envelope corner the fiducial sits at,
                             in the G-code frame (default: none -> G92 X0 Y0)

The corner coordinates are read from the G-code's own moves -- no CAD lookup.
For this board (KiCad lower-right fiducial, drilled from the BACK so X is
mirrored) the fiducial maps to the min-X/min-Y corner = `bl`.

Usage:
    python3 postprocess_drill.py INPUT.gcode \\
        [--speed 255] [--hover 0.2] [--fiducial bl]
"""

import argparse
import re
import sys
from pathlib import Path

# A drilling plunge looks like `G1 Z-2.50000` (negative Z, the cut). The
# retract is `G1 Z5.00000` (positive). We only rewrite the plunge.
PLUNGE_Z_RE = re.compile(r"^(?P<cmd>G0?1\s+Z)(?P<z>-?\d+\.?\d*)\b(?P<rest>.*)$", re.IGNORECASE)
BARE_M3_RE = re.compile(r"^\s*M3\b(?P<rest>.*)$", re.IGNORECASE)
STANDALONE_S_RE = re.compile(r"^\s*G0+\s+S\d+\b.*$", re.IGNORECASE)
# A rapid/feed XY move: captures leading cmd, X value, gap, Y value, trailing.
XY_MOVE_RE = re.compile(
    r"^(?P<pre>G0?[0123]\s+)X(?P<x>-?\d+\.?\d*)(?P<mid>\s+)Y(?P<y>-?\d+\.?\d*)(?P<rest>.*)$",
    re.IGNORECASE,
)


def hole_envelope(lines):
    """Min/max XY of the actual drilled holes (a G0 move followed by a plunge).

    Uses real holes, not every rapid, so the corners are touchable points
    rather than padded bounding-box phantoms.
    """
    xs, ys = [], []
    for i, line in enumerate(lines):
        m = XY_MOVE_RE.match(line.strip())
        if not m:
            continue
        # Is the next code line a plunge into the board (G1 Z-...)?
        for j in range(i + 1, min(i + 3, len(lines))):
            if PLUNGE_Z_RE.match(lines[j].strip()) and float(
                PLUNGE_Z_RE.match(lines[j].strip()).group("z")
            ) < 0:
                xs.append(float(m.group("x")))
                ys.append(float(m.group("y")))
                break
    if not xs:
        return None
    return min(xs), max(xs), min(ys), max(ys)


def fiducial_xy(env, corner):
    """Coordinates of the chosen hole-envelope corner -> the preamble G92 value."""
    if corner == "none" or env is None:
        return 0.0, 0.0
    minx, maxx, miny, maxy = env
    cx = {"bl": minx, "tl": minx, "br": maxx, "tr": maxx}[corner]
    cy = {"bl": miny, "br": miny, "tl": maxy, "tr": maxy}[corner]
    return cx, cy


# The preamble's zeroing line, rewritten to declare the fiducial position.
G92_RE = re.compile(r"^\s*G92\s+X-?\d*\.?\d*\s+Y-?\d*\.?\d*\s+Z-?\d*\.?\d*", re.IGNORECASE)


def transform(lines, *, dry_run, speed, hover, g92x, g92y):
    out = []
    for line in lines:
        stripped = line.rstrip("\n")

        # Drop pcb2gcode's cosmetic `G00 S<n>` spindle-speed line; the speed
        # now lives on the M3 command instead.
        if STANDALONE_S_RE.match(stripped):
            continue

        # Spindle on: real run -> `M3 S<speed>`; dry run -> leave it off.
        # Only inspect the CODE part (before any `(` comment) for an existing
        # S word -- the stock comment "(Spindle on...)" contains an 'S'.
        m3 = BARE_M3_RE.match(stripped)
        if m3:
            code = m3.group("rest").split("(", 1)[0]
            if "S" not in code.upper():
                if dry_run:
                    out.append("( dry run: spindle left OFF )")
                    continue
                out.append(f"M3 S{speed}      (Spindle on clockwise at full PWM.)")
                continue

        # Declare the fiducial position at touch-off: rewrite the preamble's
        # `G92 X0 Y0 Z0` to `G92 X<fid> Y<fid> Z0`. The toolpath is NOT moved.
        if (g92x or g92y) and G92_RE.match(stripped):
            out.append(
                f"G92 X{g92x:.3f} Y{g92y:.3f} Z0"
                f"  ( fiducial is at this part-frame position )"
            )
            continue

        # Plunge depth: in dry run, replace the negative drilling Z with a
        # small positive hover above the touched-off surface (Z0).
        if dry_run:
            pm = PLUNGE_Z_RE.match(stripped)
            if pm:
                z = float(pm.group("z"))
                if z < 0:  # this is a drilling plunge, not the retract
                    out.append(
                        f"{pm.group('cmd')}{hover:.5f}{pm.group('rest')}"
                        f"  ( dry-run hover, was Z{z:.5f} )"
                    )
                    continue

        out.append(stripped)
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("input", type=Path, help="pcb2gcode drill .gcode output")
    ap.add_argument("--speed", type=int, default=255, help="spindle PWM duty for M3 (default 255)")
    ap.add_argument("--hover", type=float, default=0.2,
                    help="dry-run hover height above surface in mm (default 0.2)")
    ap.add_argument("--fiducial", choices=["none", "bl", "br", "tl", "tr"], default="none",
                    help="hole-envelope corner the alignment fiducial sits at; sets the "
                         "preamble G92 so touch-off declares the fiducial position. "
                         "Read from the gcode itself, no CAD lookup (default none)")
    args = ap.parse_args()

    if not args.input.exists():
        sys.exit(f"input not found: {args.input}")

    raw = args.input.read_text().splitlines()

    env = hole_envelope(raw)
    g92x, g92y = fiducial_xy(env, args.fiducial)

    # Strip the `.gcode` (or `.drl.gcode`) suffix to build sibling names.
    stem = args.input.name
    for suffix in (".drl.gcode", ".gcode"):
        if stem.endswith(suffix):
            base = stem[: -len(suffix)]
            break
    else:
        base = args.input.stem

    real_path = args.input.with_name(f"{base}.drill.gcode")
    dry_path = args.input.with_name(f"{base}.dryrun.gcode")

    real = transform(raw, dry_run=False, speed=args.speed, hover=args.hover, g92x=g92x, g92y=g92y)
    dry = transform(raw, dry_run=True, speed=args.speed, hover=args.hover, g92x=g92x, g92y=g92y)

    real_path.write_text("\n".join(real) + "\n")
    dry_path.write_text("\n".join(dry) + "\n")

    if env:
        print(f"hole envelope  X {env[0]:.3f}..{env[1]:.3f}  Y {env[2]:.3f}..{env[3]:.3f}")
    if args.fiducial != "none":
        print(f"fiducial '{args.fiducial}': touch-off G92 X{g92x:.3f} Y{g92y:.3f} Z0")
    print(f"wrote {real_path}  (real drill, M3 S{args.speed})")
    print(f"wrote {dry_path}  (dry run, spindle off, hover +{args.hover}mm)")


if __name__ == "__main__":
    main()
