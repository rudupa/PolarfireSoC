# SPDX-License-Identifier: MIT

require recipes-core/images/core-image-minimal.bb

SUMMARY = "PolarFire SoC AMP developer image"
DESCRIPTION = "Extends core-image-full-cmdline with AMP runtime helpers and debugging services"

IMAGE_FEATURES:append = " package-management ssh-server-openssh debug-tweaks"
IMAGE_INSTALL:append = " amp-runtime"
CORE_IMAGE_EXTRA_INSTALL += " packagegroup-core-full-cmdline"
