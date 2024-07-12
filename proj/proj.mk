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

SOFTWARE_BIN := $(BUILD_DIR)/src/software.bin
SOFTWARE_ELF := $(BUILD_DIR)/src/software.elf

SRC_DIR := $(abspath $(PROJ_DIR)/src)
SOC_MK := $(MAKE) -C $(SOC_DIR) -f $(SOC_DIR)/common_soc.mk

PYRUN           := $(CFU_ROOT)/pyrun



.PHONY: prog load clean litex-software build-dir
prog: $(CFU_VERILOG)
	$(SOC_MK) prog

load: $(SOFTWARE_BIN)
	python3 $(LXTERM) --kernel $(SOFTWARE_BIN) $(TTY)

litex-software:
	$(SOC_MK) litex-software

build-dir: $(BUILD_DIR)/src
	@echo "build-dir: copying source to build dir"
	cp -r $(SRC_DIR)/* $(BUILD_DIR)/src

clean:
	$(SOC_MK) clean
	@echo Removin $(BUILD_DIR)
	rm -rf $(BUILD_DIR)

$(BUILD_DIR)/src:
	@echo "Making BUILD_DIR"
	@mkdir -p $(BUILD_DIR)/src

$(SOFTWARE_BIN): litex-software build-dir
	$(MAKE) -C $(BUILD_DIR)/src all -j
