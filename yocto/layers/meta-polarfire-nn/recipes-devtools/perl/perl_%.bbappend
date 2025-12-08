# SPDX-License-Identifier: MIT
# Some CPAN sub-makes regenerate their Makefiles mid-build and intentionally
# request a rerun. Retry once before bubbling the failure up.

do_compile() {
    if ! oe_runmake; then
        bbwarn "perl build requested a second pass; retrying once"
        oe_runmake
    fi
}
