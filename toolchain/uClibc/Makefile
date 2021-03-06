#
# Copyright (C) 2006-2008 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk
#include $(INCLUDE_DIR)/target.mk

PKG_VERSION:=$(call qstrip,$(CONFIG_UCLIBC_VERSION))
PKG_VERSION_SNAPSHOT:=$(call qstrip,$(CONFIG_UCLIBC_VERSION_SNAPSHOT))
ifeq ($(call qstrip,$(CONFIG_UCLIBC_NG)),y)
PKG_NAME:=uClibc-ng
PKG_SOURCE_URL:=http://downloads.uclibc-ng.org/releases/$(PKG_VERSION)/
else
PKG_NAME:=uClibc
PKG_SOURCE_URL:=http://www.uclibc.org/downloads
ifeq ($(PKG_VERSION_SNAPSHOT),y)
PKG_SOURCE_URL:=$(PKG_SOURCE_URL)/snapshots
endif
endif
PATCH_DIR:=./patches/$(PKG_VERSION)
CONFIG_DIR:=./config/$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz

STAGING_DIR_HOST:=$(TOOLCHAIN_DIR)
BUILD_DIR_HOST:=$(BUILD_DIR_TOOLCHAIN)
PKG_BUILD_DIR:=$(BUILD_DIR_HOST)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/host-build.mk

STAMP_BUILT:=$(TOOLCHAIN_DIR)/stamp/.uclibc_installed
STAMP_INSTALLED:=$(TOOLCHAIN_DIR)/stamp/.uclibc-utils_installed

UCLIBC_TARGET_ARCH:=$(shell echo $(ARCH) | sed -e s'/-.*//' \
		-e 's/i.86/i386/' \
		-e 's/sparc.*/sparc/' \
		-e 's/arm.*/arm/g' \
		-e 's/avr32.*/avr32/g' \
		-e 's/m68k.*/m68k/' \
		-e 's/ppc/powerpc/g' \
		-e 's/v850.*/v850/g' \
		-e 's/sh64/sh/' \
		-e 's/sh[234].*/sh/' \
		-e 's/mips.*/mips/' \
		-e 's/mipsel.*/mips/' \
		-e 's/cris.*/cris/' \
)

GEN_CONFIG=$(SCRIPT_DIR)/kconfig.pl -n \
	$(if $(wildcard $(CONFIG_DIR)/common),'+' $(CONFIG_DIR)/common) \
	$(if $(CONFIG_UCLIBC_ENABLE_DEBUG),$(if $(wildcard $(CONFIG_DIR)/debug),'+' $(CONFIG_DIR)/debug)) \
	$(CONFIG_DIR)/$(ARCH)$(if $(wildcard $(CONFIG_DIR)/$(ARCH).$(BOARD)),.$(BOARD))

define Build/Prepare/Snapshot
	$(PKG_UNPACK)
	rm -Rf $(PKG_BUILD_DIR)
	ln -snf $(BUILD_DIR_TOOLCHAIN)/$(PKG_NAME) $(PKG_BUILD_DIR)
	$(Build/Patch)
	$(if $(QUILT),touch $(PKG_BUILD_DIR)/.quilt_used)
endef

define Build/Prepare
	@echo prepare $(PKG_NAME) version $(PKG_VERSION)
ifeq ($(PKG_VERSION_SNAPSHOT),y)
	$(call Build/Prepare/Snapshot)
else
	$(call Build/Prepare/Default)
endif
	$(GEN_CONFIG) > $(PKG_BUILD_DIR)/.config
	$(SED) 's,^KERNEL_HEADERS=.*,KERNEL_HEADERS=\"$(LINUX_HEADERS_DIR)/include\",g' \
		-e 's,.*UCLIBC_HAS_FPU.*,UCLIBC_HAS_FPU=$(if $(CONFIG_SOFT_FLOAT),n\nUCLIBC_HAS_FLOATS=y\nUCLIBC_HAS_SOFT_FLOAT=y,y),g' \
		-e 's,^.*UCLIBC_HAS_LFS.*,UCLIBC_HAS_LFS=$(if $(CONFIG_LARGEFILE),y,n),g' \
		-e 's,^.*CONFIG_ARM_EABI.*,CONFIG_ARM_EABI=$(if $(CONFIG_EABI_SUPPORT),y,n),g' \
		-e 's,^.*CONFIG_ARM_OABI.*,CONFIG_ARM_OABI=$(if $(CONFIG_EABI_SUPPORT),n,y),g' \
		-e 's,^.*UCLIBC_HAS_SHADOW.*,UCLIBC_HAS_SHADOW=$(if $(CONFIG_SHADOW_PASSWORDS),y,n),g' \
		$(PKG_BUILD_DIR)/.config
	mkdir -p $(BUILD_DIR_HOST)/uClibc-dev/usr/include
	mkdir -p $(BUILD_DIR_HOST)/uClibc-dev/usr/lib
	mkdir -p $(BUILD_DIR_HOST)/uClibc-dev/lib
	if [ ! -f $(BUILD_DIR_HOST)/uClibc-dev/usr/include/linux/version.h ] ; then \
		cp -pLR $(LINUX_HEADERS_DIR)/* $(BUILD_DIR_HOST)/uClibc-dev/usr/; \
	fi;
	$(MAKE) -C $(PKG_BUILD_DIR) oldconfig KBUILD_HAVE_NLS= HOSTCFLAGS="-DKBUILD_NO_NLS"
	$(MAKE) -C $(PKG_BUILD_DIR)/extra/config conf KBUILD_HAVE_NLS= HOSTCFLAGS="-DKBUILD_NO_NLS"
	PATH=$(TARGET_PATH) $(MAKE) -C $(PKG_BUILD_DIR) \
		PREFIX=$(BUILD_DIR_HOST)/uClibc-dev/ \
		DEVEL_PREFIX=/usr/ \
		RUNTIME_PREFIX=$(BUILD_DIR_HOST)/uClibc-dev/ \
		HOSTCC="$(HOSTCC)" \
		CC="$(TARGET_CC)" \
		CPU_CFLAGS="$(TARGET_CFLAGS)" \
		ARCH="$(CONFIG_ARCH)" \
		pregen \
		install_headers
endef

define Build/Configure
endef

UCLIBC_MAKE := PATH=$(TARGET_PATH) $(MAKE) -C $(PKG_BUILD_DIR) \
	$(TARGET_CONFIGURE_OPTS) \
	DEVEL_PREFIX=/ \
	RUNTIME_PREFIX=/ \
	HOSTCC="$(HOSTCC)" \
	CPU_CFLAGS="$(TARGET_CFLAGS)" \
	LIBGCC="$(subst libgcc.a,libgcc_initial.a,$(shell $(TARGET_CC) -print-libgcc-file-name))" \

ifeq ($(CONFIG_UCLIBC_ENABLE_DEBUG),y)
	UCLIBC_MAKE += DODEBUG=y DODEBUG_PT=y
endif

define Build/Compile
	$(SED) 's,^CROSS=.*,CROSS=$(TARGET_CROSS),g' $(PKG_BUILD_DIR)/Rules.mak
	$(UCLIBC_MAKE) PREFIX= all
	$(UCLIBC_MAKE) PREFIX=$(STAGING_DIR_HOST)/ install_runtime install_dev
	$(SED) 's,UCLIBC_VERSION=.*,UCLIBC_VERSION=$(PKG_VERSION),' $(TOOLCHAIN_DIR)/info.mk
endef

define Build/Install
	$(UCLIBC_MAKE) PREFIX= utils
	$(INSTALL_DIR) $(TOOLCHAIN_DIR)/target-utils
	$(INSTALL_BIN) \
		$(PKG_BUILD_DIR)/utils/ldd \
		$(PKG_BUILD_DIR)/utils/ldconfig \
		$(TOOLCHAIN_DIR)/target-utils/
# Build hostutils (it can't be different in bitness with target yet)
	$(UCLIBC_MAKE) HOSTCFLAGS="-m32" PREFIX= hostutils
	$(INSTALL_BIN) -T \
		$(PKG_BUILD_DIR)/utils/ldd.host \
		$(TOOLCHAIN_DIR)/bin/$(ARCH)-uclibc-ldd
	$(INSTALL_BIN) -T \
		$(PKG_BUILD_DIR)/utils/ldconfig.host \
		$(TOOLCHAIN_DIR)/bin/$(ARCH)-uclibc-ldconfig
endef

define Build/Clean
	rm -rf $(PKG_BUILD_DIR) $(BUILD_DIR_HOST)/uClibc-dev
endef

$(eval $(call HostBuild))
