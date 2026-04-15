# ADCTest Agent Notes

## Project Shape
- This is a Quartus Prime Lite FPGA project, not a software package workspace.
- Project name and revision are both `SCOMP`; top-level entity is `SCOMP_System`; target device is `5CSXFC6D6F31C6` (Cyclone V). Verify against `SCOMP.qpf` and `SCOMP.qsf`.

## Source Of Truth
- Treat `SCOMP.qsf` as the intended source list and pin assignment file.
- Treat `SCOMP_System.bdf` as the real top-level wiring. It instantiates `SCOMP`, `DIG_IN`, `DIG_OUT`, `TIMER`, `HEX_DISP_6`, `ADC_peripheral`, `PLL_main`, and `clk_div`.
- `SCOMP_System.bdf` and `HEX_DISP_6.bdf` both warn against hand-editing in text if the design will still be maintained in Quartus Block Editor.
- `PLL_main.vhd` is generated IP wrapper output; regenerate/update through Quartus IP flow instead of hand-editing the wrapper.
- `output_files/`, `db/`, `incremental_db/`, and `simulation/questa/` are build artifacts, not primary sources.

## Clock And Reset
- `clock_50` feeds `PLL_main`; the design uses the PLL output net `clk_10MHz`.
- `SCOMP` and `ADC_peripheral` run on `clk_10MHz`.
- `TIMER` runs on `clock_10Hz` from `clk_div`, not on the CPU clock.
- Shared `resetn` comes from `PLL_main.locked`; `KEY0` drives the PLL reset path.

## Firmware / Program Memory
- `SCOMP.vhd` hardcodes the unified RAM init file as `ADCTEST.mif` via `altsyncram init_file => "ADCTEST.mif"`.
- Editing `project.asm` or `project.mif` does not affect the current build; the meaningful firmware source is `ADCTEST.asm` -> `ADCTEST.mif`.
- `scasm.cfg` defines the assembler output format: 11-bit addresses, 16-bit words, `.mif` output.

## Verified I/O Map
- `0x000`: `DIG_IN` reads external inputs. In `SCOMP_System.bdf`, that bus is `0,0,0,0,0,0,SW[9..0]`, so switches are zero-extended to 16 bits.
- `0x001`: `DIG_OUT` writes LEDs.
- `0x002`: `TIMER` read/reset register.
- `0x0C0`: ADC sample register in `ADC_peripheral`.
- `0x0C1`: ADC status register in `ADC_peripheral`; `busy` is exposed on bit 1.

## Build And Verification
- The last successful full compile is recorded in `output_files/SCOMP.flow.rpt` using Quartus Prime Lite 24.1.
- Exact flow order from that report: `quartus_map`, `quartus_fit`, `quartus_asm`, `quartus_sta`, `quartus_eda` on project/revision `SCOMP`.
- `SCOMP.sdc` is empty. The clean `output_files/SCOMP.sta.summary` only reports `altera_reserved_tck`, so user clocks are effectively unconstrained right now.
- Simulation export is configured for Questa as Verilog, not VHDL (`simulation/questa/SCOMP.vo`, `EDA_OUTPUT_DATA_FORMAT "VERILOG HDL"`).

## Repo Gotchas
- `SCOMP.qsf` still references missing `peripheral.vhd`.
- Quartus currently succeeds only because it auto-finds `ADC_peripheral.vhd` from the block diagram, which leaves warnings in `output_files/SCOMP.map.rpt` (`peripheral.vhd` missing, `adc_peripheral.vhd` auto-found but not listed).
- If you touch the ADC peripheral or clean up the source list, fix `SCOMP.qsf` instead of relying on Quartus auto-discovery.
- Legacy modules use `std_logic_arith` / `std_logic_unsigned`, `lpm`, and `altera_mf`; keep changes consistent within the touched module unless you are deliberately doing a wider cleanup.
