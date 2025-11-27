# QNX Workspace

This folder captures everything required to bring QNX Neutrino onto one of the U54 cores while Linux and Zephyr occupy the remaining harts. Use it to stage build files, BSP customisations, and sample applications before turning them into automated scripts.

Recommended structure:

- `bsp/` – QNX SDP BSP exports, startup code, and board-specific adaptations for PolarFire SoC.
- `apps/` – Example QNX resource managers or services that interact with Linux or Zephyr via shared memory.
- `ipc/` – Definitions of mailboxes, shared-memory APIs, and glue logic that enables cross-OS coordination.

Document build prerequisites (QNX SDP version, host OS requirements) so the rest of the repo can reference a consistent baseline.
