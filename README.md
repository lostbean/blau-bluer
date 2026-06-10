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

## Contents

- `mods/` — printed mod parts (sources in `.scm`, meshes in `.stl`)
- `tuning/` — calibration patterns, test models, and reference docs
- `PCB/` — guide and configs for making PCBs with the drill mod
- `Cura/` — printer definition, material profiles, and project template
- `ICESL/` — IceSL slicer settings
