# SPDX-License-Identifier: MIT
# Ensure libcap installs with the target compiler so capsh links
# against the RISC-V libraries instead of the build host ones.

EXTRA_OEMAKE:append:class-target = " CROSS_COMPILE=${TARGET_PREFIX} CC='${CC}'"
