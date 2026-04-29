// ============================================================
//  dual_core_top.v  –  Nexys 4 DDR Top-Level Module
//
//  
// ============================================================

module dual_core_top (
    input  wire        clk,         // 100 MHz onboard oscillator  (E3)
    input  wire        btnC,        // Centre push-button → reset   (N17)
    input  wire [15:0] sw,          // Slide switches               
    output wire [15:0] led,         // LEDs                         
    output wire [6:0]  seg,         // 7-segment cathodes           
    output wire [7:0]  an           // 7-segment anodes (active low)
);


    reg reset_sync1, reset_sync2;
    always @(posedge clk) begin
        reset_sync1 <= btnC;
        reset_sync2 <= reset_sync1;
    end
    wire reset = reset_sync2;

    wire clk_cpu;   // Slow CPU clock for visible pipeline execution
    wire clk_seg;   // ~763 Hz for 7-segment multiplexing

    ClockDivider clk_div (
        .clk_100mhz (clk),
        .reset      (reset),
        .clk_cpu    (clk_cpu),
        .clk_seg    (clk_seg)
    );


    wire [4:0] reg_index  = sw[4:0];   // Register to inspect (0-31)
    wire       core_sel   = sw[5];     // 0 = Core 0, 1 = Core 1


    wire [31:0] core0_dbg_data;
    wire        core0_wb_active;

    Core #(.CORE_ID(0)) core0 (
        .clk          (clk_cpu),
        .reset        (reset),
        .dbg_reg_addr (reg_index),
        .dbg_reg_data (core0_dbg_data),
        .wb_active    (core0_wb_active)
    );

    wire [31:0] core1_dbg_data;
    wire        core1_wb_active;

    Core #(.CORE_ID(1)) core1 (
        .clk          (clk_cpu),
        .reset        (reset),
        .dbg_reg_addr (reg_index),
        .dbg_reg_data (core1_dbg_data),
        .wb_active    (core1_wb_active)
    );


    wire [31:0] selected_data   = core_sel ? core1_dbg_data   : core0_dbg_data;
    wire        selected_active = core_sel ? core1_wb_active   : core0_wb_active;


    assign led[15:1] = selected_data[15:1];
    assign led[0]    = selected_active;   // Active-high write-back pulse


    SevenSegDriver seg_driver (
        .clk_seg (clk_seg),
        .reset   (reset),
        .value   (selected_data),
        .seg     (seg),
        .an      (an)
    );

endmodule
