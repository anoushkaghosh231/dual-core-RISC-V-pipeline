// ============================================================
//  Register File  –  32 × 32-bit  (x0 hardwired to 0)
//  Synchronous write, asynchronous read.
//  Exposes a debug read port for display logic (no pipeline
//  side-effects).
// ============================================================
module RegisterFile (
    input  wire        clk,
    input  wire        reset,
    // Normal pipeline ports
    input  wire        RegWrite,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] write_data,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2,
    // Debug / display port
    input  wire [4:0]  dbg_addr,
    output wire [31:0] dbg_data
);
    reg [31:0] regs [0:31];
    integer i;

    // Reset all registers to 0
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'h0;
        end else if (RegWrite && (rd != 5'h0)) begin
            regs[rd] <= write_data;
        end
    end

    // Asynchronous reads (combinational)
    assign read_data1 = (rs1 == 5'h0) ? 32'h0 : regs[rs1];
    assign read_data2 = (rs2 == 5'h0) ? 32'h0 : regs[rs2];

    // Debug port – always valid
    assign dbg_data   = (dbg_addr == 5'h0) ? 32'h0 : regs[dbg_addr];
endmodule
