export UART_SPEED := 115200
export PROJ := $(lastword $(subst /, ,${CURDIR}))
export CFU_ROOT := $(realpath $(CURDIR)/../..)
export TARGET := digilent_arty
export TTY := /dev/ttyUSB1

SOC_DIR := $(CFU_ROOT)/soc
SOC_BUILD_NAME := $(TARGET).$(PROJ)
SOC_BUILD_DIR := $(SOC_DIR)/build/$(SOC_BUILD_NAME)
SOC_SOFTWARE_DIR := $(SOC_BUILD_DIR)/software
export SOC_SOFTWARE_DIR
SOC_GATEWARE_DIR := $(SOC_BUILD_DIR)/gateware

LXTERM := $(CFU_ROOT)/tools/litex/litex/tools/litex_term.py
BITSTREAM := $(SOC_GATEWARE_DIR)/common_soc.bit

PROJ_DIR := $(realpath .)
CFU_VERILOG := $(PROJ_DIR)/cfu.v
BUILD_DIR := $(PROJ_DIR)/build

SOFTWARE_BIN := $(BUILD_DIR)/software.bin
SOFTWARE_ELF := $(BUILD_DIR)/software.elf

SRC_DIR := $(abspath $(PROJ_DIR)/src)
SOC_MK := $(MAKE) -C $(SOC_DIR) -f $(SOC_DIR)/common_soc.mk


.PHONY: prog clean
prog: $(CFU_VERILOG)
	$(SOC_MK) prog

clean:
	$(SOC_MK) clean
	@echo Removin $(BUILD_DIR)
	rm -rf $(BUILD_DIR)
