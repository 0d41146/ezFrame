#!/usr/bin/env python3

#
# This file is part of LiteX.
#
# Copyright (c) 2020-2022 Florent Kermarrec <florent@enjoy-digital.fr>
# SPDX-License-Identifier: BSD-2-Clause

import os
import sys

from migen import *

from litex.gen import *

from litex_boards.platforms import digilent_arty

from litex.soc.cores.clock import *
from litex.soc.integration.soc import SoCRegion
from litex.soc.integration.soc_core import *
from litex.soc.integration.builder import *
from litex.soc.cores.led import LedChaser
from litex.soc.cores.gpio import GPIOIn, GPIOTristate
from litex.soc.cores.xadc import XADC
from litex.soc.cores.dna  import DNA

from litedram.modules import MT41K128M16
from litedram.phy import s7ddrphy

from liteeth.phy.mii import LiteEthPHYMII

class _CRG(LiteXModule):
    def __init__(self, platform, sys_clk_freq, with_dram=True, with_rst=True):
        self.rst    = Signal()
        self.cd_sys = ClockDomain()
        self.cd_eth = ClockDomain()
        if with_dram:
            self.cd_sys4x     = ClockDomain()
            self.cd_sys4x_dqs = ClockDomain()
            self.cd_idelay    = ClockDomain()

        # # #

        # Clk/Rst.
        clk100 = platform.request("clk100")
        rst    = ~platform.request("cpu_reset") if with_rst else 0

        # PLL.
        self.pll = pll = S7PLL(speedgrade=-1)
        self.comb += pll.reset.eq(rst | self.rst)
        pll.register_clkin(clk100, 100e6)
        pll.create_clkout(self.cd_sys, sys_clk_freq)
        pll.create_clkout(self.cd_eth, 25e6)
        self.comb += platform.request("eth_ref_clk").eq(self.cd_eth.clk)
        platform.add_false_path_constraints(self.cd_sys.clk, pll.clkin) # Ignore sys_clk to pll.clkin path created by SoC's rst.
        if with_dram:
            pll.create_clkout(self.cd_sys4x,     4*sys_clk_freq)
            pll.create_clkout(self.cd_sys4x_dqs, 4*sys_clk_freq, phase=90)
            pll.create_clkout(self.cd_idelay,    200e6)

        # IdelayCtrl.
        if with_dram:
            self.idelayctrl = S7IDELAYCTRL(self.cd_idelay)


class BaseSoC(SoCCore):
    def __init__(self, variant="a7-35", toolchain="vivado", sys_clk_freq=100e6,
        with_xadc       = False,
        with_dna        = False,
        with_ethernet   = False,
        with_etherbone  = False,
        eth_ip          = "192.168.1.50",
        remote_ip       = None,
        eth_dynamic_ip  = False,
        with_usb        = False,
        with_led_chaser = True,
        with_spi_flash  = False,
        with_buttons    = False,
        with_pmod_gpio  = False,
        **kwargs):
        platform = digilent_arty.Platform(variant=variant, toolchain=toolchain)

        # CRG --------------------------------------------------------------------------------------
#with_dram = (kwargs.get("integrated_rom_size", 0) == 0)
        with_dram = True
        self.crg = _CRG(platform, sys_clk_freq, with_dram)

        # SoCCore  ----------------------------------------------------------------------------------
        SoCCore.__init__(self, platform, sys_clk_freq,
            ident          = "LiteX SoC on Digilent Arty A7",
            cpu_variant    = "full+cfu",
            cpu_cfu        = "cfu.v",
            **kwargs)
        
        # XADC -------------------------------------------------------------------------------------
        if with_xadc:
            print("XADC is not supported on this board.")
            sys.exit(1)
        
        # DNA --------------------------------------------------------------------------------------
        if with_dna:
            print("DNA is not supported on this board.")
            sys.exit(1)
        
        # DDR3 SDRAM -------------------------------------------------------------------------------
        if not self.integrated_main_ram_size:
            self.ddrphy = s7ddrphy.A7DDRPHY(platform.request("ddram"),
                memtype        = "DDR3",
                nphases        = 4,
                sys_clk_freq   = sys_clk_freq)
            self.add_sdram("sdram",
                phy           = self.ddrphy,
                module        = MT41K128M16(sys_clk_freq, "1:4"),
                l2_cache_size = kwargs.get("l2_size", 8192)
            )
        
        # Ethernet ---------------------------------------------------------------------------------
        if with_ethernet or with_etherbone:
            print("Ethernet is not supported on this board.")
            sys.exit(1)
        
        # SPI Flash --------------------------------------------------------------------------------
        if with_spi_flash:
            print("SPI Flash is not supported on this board.")
            sys.exit(1)
        
        # USB Host ---------------------------------------------------------------------------------
        if with_usb:
            print("USB Host is not supported on this board.")
            sys.exit(1)
        
        # Led Chaser -------------------------------------------------------------------------------
        if with_led_chaser:
            self.leds = LedChaser(
                pads = platform.request_all("user_led"),
                sys_clk_freq = sys_clk_freq,)
        
        # Buttons ----------------------------------------------------------------------------------
        if with_buttons:
            print("Buttons are not supported on this board.")
            sys.exit(1)
        
        # GPIOs through PMOD -----------------------------------------------------------------------
        if with_pmod_gpio:
            print("GPIOs through PMOD are not supported on this board.")
            sys.exit(1)



def main():
    from litex.build.parser import LiteXArgumentParser
    parser = LiteXArgumentParser(platform=digilent_arty.Platform, description="LiteX SoC on Arty A7.")
    parser.add_target_argument("--flash",          action="store_true",       help="Flash bitstream.")
    parser.add_target_argument("--variant",        default="a7-35",           help="Board variant (a7-35 or a7-100).")
    parser.add_target_argument("--sys-clk-freq",   default=100e6, type=float, help="System clock frequency.")
    parser.add_target_argument("--with-xadc",      action="store_true",       help="Enable 7-Series XADC.")
    parser.add_target_argument("--with-dna",       action="store_true",       help="Enable 7-Series DNA.")
    parser.add_target_argument("--with-usb",       action="store_true",       help="Enable USB Host.")
    parser.add_target_argument("--with-ethernet",  action="store_true",       help="Enable Ethernet support.")
    parser.add_target_argument("--with-etherbone", action="store_true",       help="Enable Etherbone support.")
    parser.add_target_argument("--eth-ip",         default="192.168.1.50",    help="Ethernet/Etherbone IP address.")
    parser.add_target_argument("--remote-ip",      default="192.168.1.100",   help="Remote IP address of TFTP server.")
    parser.add_target_argument("--eth-dynamic-ip", action="store_true",       help="Enable dynamic Ethernet IP addresses setting.")
    sdopts = parser.target_group.add_mutually_exclusive_group()
    sdopts.add_argument("--with-spi-sdcard",       action="store_true",       help="Enable SPI-mode SDCard support.")
    sdopts.add_argument("--with-sdcard",           action="store_true",       help="Enable SDCard support.")
    parser.add_target_argument("--sdcard-adapter",                            help="SDCard PMOD adapter (digilent or numato).")
    parser.add_target_argument("--with-spi-flash", action="store_true",       help="Enable SPI Flash (MMAPed).")
    parser.add_target_argument("--with-pmod-gpio", action="store_true",       help="Enable GPIOs through PMOD.") # FIXME: Temporary test.
    args = parser.parse_args()

    assert not (args.with_etherbone and args.eth_dynamic_ip)

    soc = BaseSoC(
        variant        = args.variant,
        toolchain      = args.toolchain,
        sys_clk_freq   = args.sys_clk_freq,
        with_xadc      = args.with_xadc,
        with_dna       = args.with_dna,
        with_ethernet  = args.with_ethernet,
        with_etherbone = args.with_etherbone,
        eth_ip         = args.eth_ip,
        remote_ip      = args.remote_ip,
        eth_dynamic_ip = args.eth_dynamic_ip,
        with_usb       = args.with_usb,
        with_spi_flash = args.with_spi_flash,
        with_pmod_gpio = args.with_pmod_gpio,
        **parser.soc_argdict
    )

    if args.sdcard_adapter == "numato":
        soc.platform.add_extension(digilent_arty._numato_sdcard_pmod_io)
    else:
        soc.platform.add_extension(digilent_arty._sdcard_pmod_io)
    
    if args.with_spi_sdcard:
        print("SPI-mode SDCard is not supported on this board.")
        sys.exit(1)
    if args.with_sdcard:
        print("SDCard is not supported on this board.")
        sys.exit(1)
    
    builder = Builder(soc, **parser.builder_argdict)
    

    if args.build:
        builder.build(**parser.toolchain_argdict)
    
    if args.load:
        prog = soc.platform.create_programmer()
        prog.load_bitstream(builder.get_bitstream_filename(mode="sram"))

    if args.flash:
        print("flashing is not supported on this board.")
        sys.exit(1)
#prog = soc.platform.create_programmer()
#prog.flash(0, builder.get_rom_filename(mode="flash"))

if __name__ == "__main__":
    main()

