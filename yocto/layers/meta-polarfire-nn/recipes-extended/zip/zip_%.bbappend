# SPDX-License-Identifier: MIT
# zipnote/zipsplit need zlib's crc32() but the upstream Makefile never links
# them against libz, so add the dependency and flag explicitly.

DEPENDS:append:class-target = " zlib"
LDFLAGS:append = " -lz"

do_compile() {
	oe_runmake -f unix/Makefile flags IZ_BZIP2=no_such_directory
	sed -i 's#LFLAGS1=""#LFLAGS1="${LDFLAGS}"#' flags
	linkflags="${LDFLAGS}"
	sed -i "s|^LFLAGS2=.*|LFLAGS2=\"${linkflags}\"|" flags
	oe_runmake -f unix/Makefile generic IZ_BZIP2=no_such_directory
}
