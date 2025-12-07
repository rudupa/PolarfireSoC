# Kernel Assets

- Store defconfig fragments targeting PolarFire SoC AMP setups.
- Track patches enabling radar DSP drivers, DMA engines, or mailbox IP.
- Include helper scripts to sync patches into Yocto recipes.

## Defconfig Fragments

- `fragments/mpfs_amp.fragment` – Baseline options for Linux on harts U54_0/U54_1 (SMP enablement, RPMsg, DMA buffers, tracing hooks).
- Merge fragments on top of Microchip's vendor defconfig with `scripts/kconfig/merge_config.sh`:

```bash
export LINUX_SRC=$HOME/work/linux-microchip
cd "$LINUX_SRC"
./scripts/kconfig/merge_config.sh -m \
	arch/riscv/configs/microchip_mpfs_defconfig \
	$REPO_ROOT/linux/kernel/fragments/mpfs_amp.fragment
make olddefconfig
```

Attach resulting `.config` (or a diff) to the Yocto recipe via `SRC_URI += "file://mpfs_amp.cfg"` so BitBake kernels stay in sync with the repo fragment.
