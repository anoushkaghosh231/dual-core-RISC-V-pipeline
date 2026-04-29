## ============================================================
##  Nexys 4 DDR  –  Master XDC for dual_core_top
##  Board: Digilent Nexys 4 DDR (Artix-7 XC7A100T-1CSG324C)
##  Project: Dual-Core 5-Stage Pipelined RISC-V Processor
## ============================================================

## ---- System Clock (100 MHz) ---------------------------------
set_property -dict { PACKAGE_PIN E3   IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk }];

## ---- Buttons ------------------------------------------------
## btnC = Centre button → Reset
set_property -dict { PACKAGE_PIN N17  IOSTANDARD LVCMOS33 } [get_ports { btnC }];

## ---- Slide Switches (sw[15:0]) ------------------------------
set_property -dict { PACKAGE_PIN J15  IOSTANDARD LVCMOS33 } [get_ports { sw[0]  }];
set_property -dict { PACKAGE_PIN L16  IOSTANDARD LVCMOS33 } [get_ports { sw[1]  }];
set_property -dict { PACKAGE_PIN M13  IOSTANDARD LVCMOS33 } [get_ports { sw[2]  }];
set_property -dict { PACKAGE_PIN R15  IOSTANDARD LVCMOS33 } [get_ports { sw[3]  }];
set_property -dict { PACKAGE_PIN R17  IOSTANDARD LVCMOS33 } [get_ports { sw[4]  }];
set_property -dict { PACKAGE_PIN T18  IOSTANDARD LVCMOS33 } [get_ports { sw[5]  }];
set_property -dict { PACKAGE_PIN U18  IOSTANDARD LVCMOS33 } [get_ports { sw[6]  }];
set_property -dict { PACKAGE_PIN R13  IOSTANDARD LVCMOS33 } [get_ports { sw[7]  }];
set_property -dict { PACKAGE_PIN T8   IOSTANDARD LVCMOS33 } [get_ports { sw[8]  }];
set_property -dict { PACKAGE_PIN U8   IOSTANDARD LVCMOS33 } [get_ports { sw[9]  }];
set_property -dict { PACKAGE_PIN R16  IOSTANDARD LVCMOS33 } [get_ports { sw[10] }];
set_property -dict { PACKAGE_PIN T13  IOSTANDARD LVCMOS33 } [get_ports { sw[11] }];
set_property -dict { PACKAGE_PIN H6   IOSTANDARD LVCMOS33 } [get_ports { sw[12] }];
set_property -dict { PACKAGE_PIN U12  IOSTANDARD LVCMOS33 } [get_ports { sw[13] }];
set_property -dict { PACKAGE_PIN U11  IOSTANDARD LVCMOS33 } [get_ports { sw[14] }];
set_property -dict { PACKAGE_PIN V10  IOSTANDARD LVCMOS33 } [get_ports { sw[15] }];

## ---- LEDs (led[15:0]) ---------------------------------------
set_property -dict { PACKAGE_PIN H17  IOSTANDARD LVCMOS33 } [get_ports { led[0]  }];
set_property -dict { PACKAGE_PIN K15  IOSTANDARD LVCMOS33 } [get_ports { led[1]  }];
set_property -dict { PACKAGE_PIN J13  IOSTANDARD LVCMOS33 } [get_ports { led[2]  }];
set_property -dict { PACKAGE_PIN N14  IOSTANDARD LVCMOS33 } [get_ports { led[3]  }];
set_property -dict { PACKAGE_PIN R18  IOSTANDARD LVCMOS33 } [get_ports { led[4]  }];
set_property -dict { PACKAGE_PIN V17  IOSTANDARD LVCMOS33 } [get_ports { led[5]  }];
set_property -dict { PACKAGE_PIN U17  IOSTANDARD LVCMOS33 } [get_ports { led[6]  }];
set_property -dict { PACKAGE_PIN U16  IOSTANDARD LVCMOS33 } [get_ports { led[7]  }];
set_property -dict { PACKAGE_PIN V16  IOSTANDARD LVCMOS33 } [get_ports { led[8]  }];
set_property -dict { PACKAGE_PIN T15  IOSTANDARD LVCMOS33 } [get_ports { led[9]  }];
set_property -dict { PACKAGE_PIN U14  IOSTANDARD LVCMOS33 } [get_ports { led[10] }];
set_property -dict { PACKAGE_PIN T16  IOSTANDARD LVCMOS33 } [get_ports { led[11] }];
set_property -dict { PACKAGE_PIN V15  IOSTANDARD LVCMOS33 } [get_ports { led[12] }];
set_property -dict { PACKAGE_PIN V14  IOSTANDARD LVCMOS33 } [get_ports { led[13] }];
set_property -dict { PACKAGE_PIN V12  IOSTANDARD LVCMOS33 } [get_ports { led[14] }];
set_property -dict { PACKAGE_PIN V11  IOSTANDARD LVCMOS33 } [get_ports { led[15] }];

## ---- 7-Segment Display : Cathodes (seg[6:0]) ----------------
## Nexys 4 DDR: CA CB CC CD CE CF CG (active low, common anode)
## seg[0]=CA  seg[1]=CB  ... seg[6]=CG
set_property -dict { PACKAGE_PIN T10  IOSTANDARD LVCMOS33 } [get_ports { seg[0] }];
set_property -dict { PACKAGE_PIN R10  IOSTANDARD LVCMOS33 } [get_ports { seg[1] }];
set_property -dict { PACKAGE_PIN K16  IOSTANDARD LVCMOS33 } [get_ports { seg[2] }];
set_property -dict { PACKAGE_PIN K13  IOSTANDARD LVCMOS33 } [get_ports { seg[3] }];
set_property -dict { PACKAGE_PIN P15  IOSTANDARD LVCMOS33 } [get_ports { seg[4] }];
set_property -dict { PACKAGE_PIN T11  IOSTANDARD LVCMOS33 } [get_ports { seg[5] }];
set_property -dict { PACKAGE_PIN L18  IOSTANDARD LVCMOS33 } [get_ports { seg[6] }];

## ---- 7-Segment Display : Anodes (an[7:0], active low) -------
## an[0] = rightmost digit, an[7] = leftmost digit
set_property -dict { PACKAGE_PIN J17  IOSTANDARD LVCMOS33 } [get_ports { an[0] }];
set_property -dict { PACKAGE_PIN J18  IOSTANDARD LVCMOS33 } [get_ports { an[1] }];
set_property -dict { PACKAGE_PIN T9   IOSTANDARD LVCMOS33 } [get_ports { an[2] }];
set_property -dict { PACKAGE_PIN J14  IOSTANDARD LVCMOS33 } [get_ports { an[3] }];
set_property -dict { PACKAGE_PIN P14  IOSTANDARD LVCMOS33 } [get_ports { an[4] }];
set_property -dict { PACKAGE_PIN T14  IOSTANDARD LVCMOS33 } [get_ports { an[5] }];
set_property -dict { PACKAGE_PIN K2   IOSTANDARD LVCMOS33 } [get_ports { an[6] }];
set_property -dict { PACKAGE_PIN U13  IOSTANDARD LVCMOS33 } [get_ports { an[7] }];

## ---- Configuration / Bitstream Settings ---------------------
set_property CFGBVS VCCO [current_design];
set_property CONFIG_VOLTAGE 3.3 [current_design];
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design];

## ---- Timing Exceptions for Slow CPU Clock -------------------
## The CPU runs on clk_cpu which is derived from a counter bit
## (not a dedicated MMCM output), so we mark it as a generated
## clock so the timing engine understands its relationship to
## the board clock.
##
## If you use Vivado, uncomment the line below after synthesis
## so the tool can auto-derive it from the clock divider logic:
#
create_generated_clock -name clk_cpu \
    -source [get_pins clk_div/cnt_reg[24]/C] \
     -divide_by 2 \
     [get_pins clk_div/cnt_reg[24]/Q]

set_clock_groups -asynchronous \
     -group [get_clocks sys_clk_pin] \
     -group [get_clocks clk_cpu]
