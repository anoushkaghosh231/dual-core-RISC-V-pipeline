// ============================================================
//  seven_segment_driver.v
//  8-digit multiplexed 7-segment display driver
//
//  Displays a 32-bit value as 8 hex digits across all 8
//  digits of the Nexys 4 DDR's common-anode display.
//
//  Digits are multiplexed using clk_seg (≈763 Hz), giving
//  a ~95 Hz refresh per digit (well above flicker threshold).
//
//  Segment encoding (active-low, common anode):
//    seg[6:0] = {g, f, e, d, c, b, a}
//    0 → 7'b1000000   (a–f on, g off)
//    1 → 7'b1111001
//    ...
// ============================================================
module SevenSegDriver (
    input  wire        clk_seg,   // ~763 Hz multiplexing clock
    input  wire        reset,
    input  wire [31:0] value,     // 32-bit value to display
    output reg  [6:0]  seg,       // Active-low segment pattern
    output reg  [7:0]  an         // Active-low digit enable
);
    // 3-bit counter selects 1-of-8 digits
    reg [2:0] digit_sel;

    always @(posedge clk_seg or posedge reset) begin
        if (reset) digit_sel <= 3'd0;
        else       digit_sel <= digit_sel + 3'd1;
    end

    // Select the correct nibble for the active digit
    reg [3:0] nibble;
    always @(*) begin
        case (digit_sel)
            3'd0: nibble = value[ 3: 0];
            3'd1: nibble = value[ 7: 4];
            3'd2: nibble = value[11: 8];
            3'd3: nibble = value[15:12];
            3'd4: nibble = value[19:16];
            3'd5: nibble = value[23:20];
            3'd6: nibble = value[27:24];
            3'd7: nibble = value[31:28];
            default: nibble = 4'h0;
        endcase
    end

    // Active-low anode: only the selected digit is enabled
    always @(*) begin
        an = 8'hFF;                     // All off by default
        an[digit_sel] = 1'b0;           // Enable selected digit
    end

    // 7-segment decoder (active-low, common anode)
    //  seg order: {g, f, e, d, c, b, a}
    always @(*) begin
        case (nibble)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'ha: seg = 7'b0001000;
            4'hb: seg = 7'b0000011;
            4'hc: seg = 7'b1000110;
            4'hd: seg = 7'b0100001;
            4'he: seg = 7'b0000110;
            4'hf: seg = 7'b0001110;
            default: seg = 7'b1111111; // All off
        endcase
    end
endmodule
