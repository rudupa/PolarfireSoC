# Zephyr Board Customizations

Document hart-specific board definitions here. The repo currently includes DTS overlays consumed by `scripts/build/zephyr_amp.sh`:

- `mpfs_discovery_u54_1.overlay` – Keeps only hart `u54_1` active (useful for experiments where Linux temporarily yields a hart to Zephyr) and tags mailbox channel `2` / doorbell IRQ `62`.
- `mpfs_discovery_u54_2.overlay` – Reserved for QNX bring-up scenarios; captures mailbox/IRQ routing if Zephyr ever targets this hart.
- `mpfs_discovery_u54_3.overlay` – Default overlay for the production Zephyr hart, encoding mailbox channel `4` / doorbell IRQ `60` plus CPU affinity.

Extend these overlays (or add new ones) with clock, pinmux, and mailbox bindings as requirements grow.
