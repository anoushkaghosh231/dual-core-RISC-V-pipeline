// ============================================================
//  dual_core_top.v  –  Nexys 4 DDR Top-Level Module
//
//  Instantiates:
//    • Two independent 5-stage RISC-V pipeline cores
//    • Clock divider (100 MHz → CPU clock + 7-seg refresh)
//    • 8-digit 7-segment display driver
//
//  Switch / button mapping
//  ───────────────────────
//  btnC          → synchronous reset for both cores
//  sw[4:0]       → register index to inspect (0–31)
//  sw[5]         → core select  (0 = Core 0, 1 = Core 1)
//  sw[15:6]      → unused (reserved)
//
//  LED mapping
//  ───────────
//  led[15:0]     → lower 16 bits of selected register value
//                  (blinks MSB on write-back activity)
//
//  7-seg display
//  ─────────────
//  All 8 digits show the selected register value in hex.
//  Digit 7 (leftmost) = bits[31:28], digit 0 = bits[3:0].
// ============================================================
// All sub-modules are compiled as separate source files.
// In Vivado: add all .v files to the project sources list.
// In iverilog: compile all .v files together on one command line.

module dual_core_top (
    input  wire        clk,         // 100 MHz onboard oscillator  (E3)
    input  wire        btnC,        // Centre push-button → reset   (N17)
    input  wire [15:0] sw,          // Slide switches               (see XDC)
    output wire [15:0] led,         // LEDs                         (see XDC)
    output wire [6:0]  seg,         // 7-segment cathodes           (see XDC)
    output wire [7:0]  an           // 7-segment anodes (active low)(see XDC)
);

    // ----------------------------------------------------------------
    //  Reset synchronisation (two-stage metastability filter)
    // ----------------------------------------------------------------
    reg reset_sync1, reset_sync2;
    always @(posedge clk) begin
        reset_sync1 <= btnC;
        reset_sync2 <= reset_sync1;
    end
    wire reset = reset_sync2;

    // ----------------------------------------------------------------
    //  Clock divider
    // ----------------------------------------------------------------
    wire clk_cpu;   // Slow CPU clock for visible pipeline execution
    wire clk_seg;   // ~763 Hz for 7-segment multiplexing

    ClockDivider clk_div (
        .clk_100mhz (clk),
        .reset      (reset),
        .clk_cpu    (clk_cpu),
        .clk_seg    (clk_seg)
    );

    // ----------------------------------------------------------------
    //  Switch / display control decoding
    // ----------------------------------------------------------------
    wire [4:0] reg_index  = sw[4:0];   // Register to inspect (0-31)
    wire       core_sel   = sw[5];     // 0 = Core 0, 1 = Core 1

    // ----------------------------------------------------------------
    //  Core 0  (CORE_ID = 0 ⇒ uses InstrMem_Core0)
    // ----------------------------------------------------------------
    wire [31:0] core0_dbg_data;
    wire        core0_wb_active;

    Core #(.CORE_ID(0)) core0 (
        .clk          (clk_cpu),
        .reset        (reset),
        .dbg_reg_addr (reg_index),
        .dbg_reg_data (core0_dbg_data),
        .wb_active    (core0_wb_active)
    );

    // ----------------------------------------------------------------
    //  Core 1  (CORE_ID = 1 ⇒ uses InstrMem_Core1)
    // ----------------------------------------------------------------
    wire [31:0] core1_dbg_data;
    wire        core1_wb_active;

    Core #(.CORE_ID(1)) core1 (
        .clk          (clk_cpu),
        .reset        (reset),
        .dbg_reg_addr (reg_index),
        .dbg_reg_data (core1_dbg_data),
        .wb_active    (core1_wb_active)
    );

    // ----------------------------------------------------------------
    //  Mux: select data from the chosen core for display
    // ----------------------------------------------------------------
    wire [31:0] selected_data   = core_sel ? core1_dbg_data   : core0_dbg_data;
    wire        selected_active = core_sel ? core1_wb_active   : core0_wb_active;

    // ----------------------------------------------------------------
    //  LED output
    //  led[15:1] = bits [15:1] of selected register
    //  led[0]    = write-back activity strobe (pulses when core writes)
    // ----------------------------------------------------------------
    assign led[15:1] = selected_data[15:1];
    assign led[0]    = selected_active;   // Active-high write-back pulse

    // ----------------------------------------------------------------
    //  7-Segment display driver
    //  Shows all 32 bits of selected_data as 8 hex digits.
    // ----------------------------------------------------------------
    SevenSegDriver seg_driver (
        .clk_seg (clk_seg),
        .reset   (reset),
        .value   (selected_data),
        .seg     (seg),
        .an      (an)
    );

endmodule
