# Libero SoC Projects

Track FPGA sources for the radar DSP accelerator here:

- `projects/` – Libero design database (consider `.gitignore` for generated outputs).
- `scripts/` – TCL flows to regenerate bitstreams and export headers.
- `exports/` – Bitstreams and handoff data consumed by HSS payloads.

Document DSP block parameters (filter taps, FFT size, etc.) so downstream software can stay in sync.
