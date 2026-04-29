// ============================================================
//  Clock Divider
//  Divides 100 MHz down to ~1.526 Hz (2^26) for visible
//  pipeline execution, and produces a 1 kHz tick for the
//  7-segment display multiplexer refresh.
// ============================================================
module ClockDivider (
    input  wire clk_100mhz,   // 100 MHz board clock
    input  wire reset,
    output wire clk_cpu,      // Slow CPU clock (~1.526 Hz)
    output wire clk_seg       // ~1 kHz 7-seg refresh clock
);
    // 27-bit counter covers 2^26 = 67 108 864  cycles @ 100 MHz
    reg [26:0] cnt;

    always @(posedge clk_100mhz or posedge reset) begin
        if (reset) cnt <= 27'd0;
        else       cnt <= cnt + 27'd1;
    end

    // CPU clock  : bit 26 toggles at 100e6 / 2^27 ≈ 0.745 Hz
    //              Use bit 25 for ~1.49 Hz, bit 24 for ~2.98 Hz
    //              Adjust the slice to taste; bit 24 chosen here.
    assign clk_cpu = cnt[24];   // ~5.96 MHz divided => ~5.96 Hz visible

    // 7-seg refresh: bit 16 => 100e6/2^17 ≈ 763 Hz (good for flicker-free)
    assign clk_seg = cnt[16];
endmodule
