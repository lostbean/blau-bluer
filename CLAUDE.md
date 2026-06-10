# blau-bluer

Mods, tuning, and slicer profiles for the Two Trees Bluer 3D printer. There is
no application code here — the repo holds CAD sources for printed mod parts,
calibration assets, and slicer configuration. The Marlin firmware for the
printer lives in its own repo (with its own nix flake for building):
https://github.com/lostbean/Marlin

## Repository layout

- `mods/` — printed mod parts. Sources are libfive Studio Scheme models
  (`.scm`); exported meshes (`.stl`) are committed next to them.
- `tuning/` — bed-leveling and calibration material: gcode patterns
  (`patterns/`), test models (`models/`, mostly `.scm`/`.stl` plus one
  parametric OpenSCAD source), and reference docs (`docs/`).
- `Cura/` — Cura printer definition, material profiles, and a project
  template.
- `ICESL/` — IceSL slicer settings (machine-generated Lua, exported from
  IceSL).

## Tooling

This repo uses a Nix-native dev setup.

- **Dev shell** — run `nix develop` to enter a shell with the toolchains, or
  let direnv load it automatically (`direnv allow` once). The shell provides
  **libfive** (Studio + Guile bindings, for the `.scm` models), **OpenSCAD**
  (for `.scad`), and **lefthook**.
- **Formatting** — `nix fmt` formats the whole repo via treefmt (nixfmt for
  Nix, prettier for Markdown, stylua for Lua). libfive Scheme (`.scm`) and
  OpenSCAD (`.scad`) have no formatter and are left as-is. `ICESL/settings/`
  is excluded from formatting — those files are kept exactly as IceSL exports
  them.
- **Commit gate** — a lefthook `pre-commit` hook formats staged files and
  re-stages them, so commits are always formatted. Install hooks with
  `lefthook install`. If a commit reformats files, it still succeeds — the
  formatted result is what gets committed.

## Conventions

### Do

- Keep exported meshes in sync with their sources: after editing a `.scm` or
  `.scad` model, re-export the neighbouring `.stl`.
- Treat `Cura/` and `ICESL/` files as application exports — prefer editing in
  Cura/IceSL and re-exporting over hand-editing.

### Don't

- **Do not add trailers, attribution, `Co-Authored-By`, or `Generated with`
  footers to commit messages.**
- Don't hand-edit generated artifacts (`.stl`, `.3mf`, `.gcode`).
