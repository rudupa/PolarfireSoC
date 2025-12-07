# amp_pingpong

Minimal RPMsg/OpenAMP demo that exercises the Linux ↔ Zephyr message path used in the AMP plan.

Features:

- Registers an IPC Service endpoint named `amp-pingpong` bound to the shared memory chosen node.
- Echoes any payload received from Linux/QNX back to the sender.
- Emits 1 Hz heartbeats containing the hart index (`CONFIG_MPFS_HART_INDEX`).

Build example:

```sh
west build -b mpfs_icicle zephyr/apps/amp_pingpong \
  -- -DCONFIG_MPFS_HART_INDEX=1
```
