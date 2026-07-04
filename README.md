# blau-bluer

Mods, tuning, slicer profiles, and PCB-making setup for the Two Trees Bluer 3D
printer.

## Firmware

The Marlin firmware lives in its own repo (with its own nix flake for building):
https://github.com/lostbean/Marlin

## PCB making

The printer is adapted to hold a drill spindle and a laser (mounts in
`mods/`). [`PCB/`](PCB/README.md) documents how to make PCBs with it —
marker-drawn etch resist plus drilled holes — including the pcb2gcode configs
and G-code preambles. A laser-based workflow will be added there later.

The alignment-and-drilling half of this now has a browser app,
**[blau-drill](https://github.com/lostbean/blau_drill)**, that replaces the
manual pcb2gcode + touch-off flow: it fits the fiducials, gates the dangerous
moves behind states you have to pass through, and drives the printer directly
over Web Serial. Try it live at <https://onedgy.com/lab/blau-drill/>; the post
[From Ritual to Software](https://onedgy.com/blog/blau-drill/) explains why it is
built the way it is.

## Contents

- `mods/` — printed mod parts (sources in `.scm`, meshes in `.stl`)
- `tuning/` — calibration patterns, test models, and reference docs
- `PCB/` — guide and configs for making PCBs with the drill mod
- `Cura/` — printer definition, material profiles, and project template
- `ICESL/` — IceSL slicer settings
