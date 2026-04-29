// ============================================================
//  Pipeline Registers  –  standalone helper modules
//  The core.v module uses these as primitives so that the
//  register boundaries are clearly identifiable during
//  synthesis / timing closure.
// ============================================================

// ---- IF / ID register ----------------------------------------
module IF_ID_Reg (
    input  wire        clk,
    input  wire        reset,
    input  wire        flush,   // Branch taken
    input  wire        stall,   // Load-use hazard
    input  wire [31:0] pc_in,
    input  wire [31:0] instr_in,
    output reg  [31:0] pc_out,
    output reg  [31:0] instr_out
);
    always @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            pc_out    <= 32'h0;
            instr_out <= 32'h0;   // NOP
        end else if (!stall) begin
            pc_out    <= pc_in;
            instr_out <= instr_in;
        end
    end
endmodule

// ---- ID / EX register ----------------------------------------
module ID_EX_Reg (
    input  wire        clk,
    input  wire        reset,
    input  wire        flush,   // Branch or load-use bubble
    // Data
    input  wire [31:0] pc_in,
    input  wire [31:0] rd1_in, rd2_in, imm_in,
    input  wire [4:0]  rs1_in, rs2_in, rd_in,
    input  wire [2:0]  funct3_in,
    input  wire        funct7_5_in,
    // Control
    input  wire        RegWrite_in, ALUSrc_in, MemRead_in,
    input  wire        MemWrite_in, MemToReg_in, Branch_in,
    input  wire [1:0]  ALUOp_in,
    // Outputs
    output reg  [31:0] pc_out,
    output reg  [31:0] rd1_out, rd2_out, imm_out,
    output reg  [4:0]  rs1_out, rs2_out, rd_out,
    output reg  [2:0]  funct3_out,
    output reg         funct7_5_out,
    output reg         RegWrite_out, ALUSrc_out, MemRead_out,
    output reg         MemWrite_out, MemToReg_out, Branch_out,
    output reg  [1:0]  ALUOp_out
);
    always @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            pc_out       <= 0; rd1_out  <= 0; rd2_out  <= 0; imm_out  <= 0;
            rs1_out      <= 0; rs2_out  <= 0; rd_out   <= 0;
            funct3_out   <= 0; funct7_5_out <= 0;
            RegWrite_out <= 0; ALUSrc_out   <= 0; MemRead_out  <= 0;
            MemWrite_out <= 0; MemToReg_out <= 0; Branch_out   <= 0;
            ALUOp_out    <= 0;
        end else begin
            pc_out       <= pc_in;
            rd1_out      <= rd1_in;
            rd2_out      <= rd2_in;
            imm_out      <= imm_in;
            rs1_out      <= rs1_in;
            rs2_out      <= rs2_in;
            rd_out       <= rd_in;
            funct3_out   <= funct3_in;
            funct7_5_out <= funct7_5_in;
            RegWrite_out <= RegWrite_in;
            ALUSrc_out   <= ALUSrc_in;
            MemRead_out  <= MemRead_in;
            MemWrite_out <= MemWrite_in;
            MemToReg_out <= MemToReg_in;
            Branch_out   <= Branch_in;
            ALUOp_out    <= ALUOp_in;
        end
    end
endmodule

// ---- EX / MEM register ---------------------------------------
module EX_MEM_Reg (
    input  wire        clk,
    input  wire        reset,
    // Data
    input  wire [31:0] pc_branch_in,
    input  wire [31:0] alu_result_in,
    input  wire [31:0] rd2_in,
    input  wire [4:0]  rd_in,
    input  wire        zero_in,
    // Control
    input  wire        RegWrite_in, MemRead_in,
    input  wire        MemWrite_in, MemToReg_in, Branch_in,
    // Outputs
    output reg  [31:0] pc_branch_out,
    output reg  [31:0] alu_result_out,
    output reg  [31:0] rd2_out,
    output reg  [4:0]  rd_out,
    output reg         zero_out,
    output reg         RegWrite_out, MemRead_out,
    output reg         MemWrite_out, MemToReg_out, Branch_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_branch_out  <= 0; alu_result_out <= 0;
            rd2_out        <= 0; rd_out         <= 0; zero_out <= 0;
            RegWrite_out   <= 0; MemRead_out    <= 0;
            MemWrite_out   <= 0; MemToReg_out   <= 0; Branch_out <= 0;
        end else begin
            pc_branch_out  <= pc_branch_in;
            alu_result_out <= alu_result_in;
            rd2_out        <= rd2_in;
            rd_out         <= rd_in;
            zero_out       <= zero_in;
            RegWrite_out   <= RegWrite_in;
            MemRead_out    <= MemRead_in;
            MemWrite_out   <= MemWrite_in;
            MemToReg_out   <= MemToReg_in;
            Branch_out     <= Branch_in;
        end
    end
endmodule

// ---- MEM / WB register ---------------------------------------
module MEM_WB_Reg (
    input  wire        clk,
    input  wire        reset,
    // Data
    input  wire [31:0] alu_result_in,
    input  wire [31:0] mem_data_in,
    input  wire [4:0]  rd_in,
    // Control
    input  wire        RegWrite_in,
    input  wire        MemToReg_in,
    // Outputs
    output reg  [31:0] alu_result_out,
    output reg  [31:0] mem_data_out,
    output reg  [4:0]  rd_out,
    output reg         RegWrite_out,
    output reg         MemToReg_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            alu_result_out <= 0; mem_data_out <= 0; rd_out <= 0;
            RegWrite_out   <= 0; MemToReg_out <= 0;
        end else begin
            alu_result_out <= alu_result_in;
            mem_data_out   <= mem_data_in;
            rd_out         <= rd_in;
            RegWrite_out   <= RegWrite_in;
            MemToReg_out   <= MemToReg_in;
        end
    end
endmodule
