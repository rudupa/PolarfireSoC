# Cross-OS IPC Definitions

Centralise all artifacts that describe how QNX, Linux, and Zephyr exchange data:

- Memory map files listing shared regions, cache policy, and ownership rules.
- Mailbox/interrupt routing tables tied to the PolarFire MSS Event Controller.
- Header files that define message IDs, structs, and synchronization primitives.

Coordinate with `docs/architecture/interconnect.md` and `bsp/hss` payload manifests so hardware/software stay aligned.
