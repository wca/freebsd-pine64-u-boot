U_BOOT_FLAGS=	ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-

all: u-boot

u-boot:
	${MAKE} -C external/u-boot-pine64 ${U_BOOT_FLAGS} sun50iw1p1_config
	${MAKE} -C external/u-boot-pine64 ${U_BOOT_FLAGS}
