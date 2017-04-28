# 
# Copyright (C) 2007-2010 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

TMP_DIR ?= $(TOPDIR)/tmp
-include $(TMP_DIR)/.host.mk

export TAR

ifneq ($(__host_inc),1)
__host_inc:=1

try-run = $(shell set -e; \
	TMP_F="$(TMP_DIR)/try-run.$$$$.tmp"; \
	if ($(1)) >/dev/null 2>&1; then echo "$(2)"; else echo "$(3)"; fi; \
	rm -f "$$TMP_F"; \
)

host-cc-option = $(call try-run, \
	$(HOSTCC) $(HOST_CFLAGS) $(1) -c -xc /dev/null -o "$$TMP_F",$(1),$(2) \
)

.PRECIOUS: $(TMP_DIR)/.host.mk
$(TMP_DIR)/.host.mk: $(TOPDIR)/include/host.mk
	@mkdir -p $(TMP_DIR)
	@( \
		HOST_OS=`uname`; \
		case "$$HOST_OS" in \
			Linux) HOST_ARCH=`uname -m`;; \
			*) HOST_ARCH=`uname -p`;; \
		esac; \
		GNU_HOST_NAME=`gcc -dumpmachine`; \
		[ -n "$$GNU_HOST_NAME" ] || \
			GNU_HOST_NAME=`$(SCRIPT_DIR)/config.guess`; \
		echo "HOST_OS:=$$HOST_OS" > $@; \
		echo "HOST_ARCH:=$$HOST_ARCH" >> $@; \
		echo "GNU_HOST_NAME:=$$GNU_HOST_NAME" >> $@; \
		TAR=`which gtar 2>/dev/null`; \
		[ -n "$$TAR" -a -x "$$TAR" ] || TAR=`which gnutar 2>/dev/null`; \
		[ -n "$$TAR" -a -x "$$TAR" ] || TAR=`which tar 2>/dev/null`; \
		echo "TAR:=$$TAR" >> $@; \
		FIND=`which gfind 2>/dev/null`; \
		[ -n "$$FIND" -a -x "$$FIND" ] || FIND=`which find 2>/dev/null`; \
		echo "FIND:=$$FIND" >> $@; \
		echo "BASH:=$(shell which bash)" >> $@; \
	)

endif

ifeq ($(HOST_OS),Linux)
  XARGS:=xargs -r
else
  XARGS:=xargs
endif
