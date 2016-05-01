PROJECT=	wca-freebsd-pine64-u-boot
REQUIRED_BINS=	gdd unix2dos arm-none-eabi-gcc aarch64-none-elf-gcc
REQUIRED_PKGS=	coreutils unix2dos arm-none-eabi-gcc492 aarch64-none-elf-gcc

MAKE_PATH=	env PATH=`pwd`/bin:${PATH} ${MAKE}

U_BOOT_PATH=	external/u-boot-pine64
U_BOOT_FLAGS=	ARCH=arm CROSS_COMPILE=arm-none-eabi-
U_BOOT_MAKE=	${MAKE_PATH} -C ${U_BOOT_PATH} ${U_BOOT_FLAGS}
U_BOOT_DEP=	${U_BOOT_PATH}/u-boot-sun50iw1p1.bin

ATF_PATH=	external/arm-trusted-firmware-pine64
ATF_FLAGS=	ARCH=arm CROSS_COMPILE=aarch64-none-elf- PLAT=sun50iw1p1
ATF_MAKE=	${MAKE_PATH} -C ${ATF_PATH} ${ATF_FLAGS}
ATF_DEP=	${ATF_PATH}/build/sun50iw1p1/release/bl31.bin

SUNXI_PATH=	external/sunxi-pack-tools
SUNXI_MAKE=	${MAKE_PATH} -C ${SUNXI_PATH}
SUNXI_DEP=	${SUNXI_PATH}/bin/merge_uboot

LONGSLEEP_PATH=	external/longsleep-build-pine64-image

all: regenerate-bin image

check-deps:
	@if ! which ${REQUIRED_BINS} >/dev/null 2>&1; then		\
		echo "Error: Missing required programs."		\
		echo "To fix, run 'pkg install ${REQUIRED_PKGS}'";	\
		exit 1;							\
	fi

# This target is always re-executed in case pointers need updating.
regenerate-bin: check-deps
	@mkdir -p bin
	@ln -sf `which gdd` bin/dd
	@ln -sf `which gnustat` bin/stat

u-boot: ${U_BOOT_DEP}

${U_BOOT_PATH}/u-boot-sun50iw1p1.bin:
	${U_BOOT_MAKE} sun50iw1p1_config
	${U_BOOT_MAKE}

atf: ${ATF_DEP}

${ATF_PATH}/build/sun50iw1p1/release/bl31.bin:
	${ATF_MAKE} clean
	${ATF_MAKE} bl31

sunxi: ${SUNXI_DEP}

${SUNXI_PATH}/bin/merge_uboot:
	${SUNXI_MAKE}

image: ${LONGSLEEP_PATH}/build/u-boot-with-dtb.bin

${LONGSLEEP_PATH}/build/u-boot-with-dtb.bin: ${U_BOOT_DEP} ${ATF_DEP} ${SUNXI_DEP}
	cd ${LONGSLEEP_PATH}/u-boot-postprocess && ./u-boot-postprocess.sh

clean:
	${U_BOOT_MAKE} clean || true
	${ATF_MAKE} clean || true
	${SUNXI_MAKE} clean || true
	rm -f ${U_BOOT_DEP} ${ATF_DEP} ${SUNXI_DEP}

# Only used to generate a release distfile.
distfile:
	git clean -fdx
	git submodule update --init --recursive
	@release=`git show-ref --tags -d | awk -F/ '{print $$3}'`; \
		tar --exclude=.git -czf ../${PROJECT}-$${release}.tar.gz . && \
		ls -l ../${PROJECT}-$${release}.tar.gz
