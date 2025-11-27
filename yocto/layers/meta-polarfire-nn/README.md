# meta-polarfire-nn

Custom Yocto layer that packages PolarFire-specific accelerator components:

- Kernel/device-tree patches for radar DSP and NN IP blocks.
- Out-of-tree accelerator driver modules.
- Userspace HAL libraries and Python bindings.
- Example inference + telemetry applications.

Add standard layer metadata files (`conf/layer.conf`, recipes) as development progresses.
