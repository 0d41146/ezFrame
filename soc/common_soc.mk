ifndef PROJ
  $(error PROJ must be set. $(HELP_MESSAGE))
endif

ifndef UART_SPEED
  $(error UART_SPEED must be set. $(HELP_MESSAGE))
endif

ifndef CFU_ROOT
  $(error CFU_ROOT must be set. $(HELP_MESSAGE))
endif

ifneq ($(PROJ),proj1)
    $(error PROJ must be set to 'proj1'. Current value: '$(PROJ)')
endif



PROJ_DIR := $(CFU_ROOT)/proj/$(PROJ)
CFU_V := $(PROJ_DIR)/cfu.v
SOC_NAME := $(TARGET).$(PROJ)
OUT_DIR := build/$(SOC_NAME)

LITEX_ARGS += --output-dir $(OUT_DIR)
LITEX_ARGS += --csr-json $(OUT_DIR)/csr.json

TARGET_RUN := $(CFU_ROOT)/soc/common_soc.py $(LITEX_ARGS)

BIOS_BIN := $(OUT_DIR)/software/bios/bios.bin
BITSTREAM := $(OUT_DIR)/gateware/$(TARGET).bit

.PHONY: prog clean

clean:
	@echo Removing $(OUT_DIR)
	rm -rf $(OUT_DIR)

prog: $(BITSTREAM)
	@echo Loading bitstream onto board
	python3 $(TARGET_RUN) --no-compile-software --load

$(BITSTREAM):
	@echo Building bitstream for $(TARGET).
	python3 $(TARGET_RUN) --build $(LITEX_ARGS)
