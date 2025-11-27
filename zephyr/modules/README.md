# Zephyr Modules

Use this area for reusable Zephyr components:

- `radar_hal/` – Shared APIs for accessing FPGA registers.
- `shared_mem/` – Utilities to manage buffers shared with Linux or DMA engines.
- `profiling/` – Hooks for tracing hart workloads.

Each module can be imported via `west.yml` or Zephyr's `module.yml` once ready.
