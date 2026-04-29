// ============================================================
//  ALU  –  32-bit RISC-V RV32I subset
//  Operations: ADD SUB AND OR XOR SLL SRL SRA SLT SLTU
// ============================================================
module ALU (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_ctrl,
    output reg  [31:0] result,
    output wire        zero
);
    always @(*) begin
        case (alu_ctrl)
            4'b0000: result = a + b;                              // ADD
            4'b0001: result = a - b;                              // SUB
            4'b0010: result = a & b;                              // AND
            4'b0011: result = a | b;                              // OR
            4'b0100: result = a ^ b;                              // XOR
            4'b0101: result = a << b[4:0];                        // SLL
            4'b0110: result = a >> b[4:0];                        // SRL
            4'b0111: result = $signed(a) >>> b[4:0];              // SRA
            4'b1000: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT
            4'b1001: result = (a < b) ? 32'd1 : 32'd0;           // SLTU
            default: result = 32'h0;
        endcase
    end

    assign zero = (result == 32'h0);
endmodule

// ============================================================
//  ALU Control  –  decodes ALUOp + funct fields
// ============================================================
module ALUControl (
    input  wire [1:0] alu_op,
    input  wire [2:0] funct3,
    input  wire       funct7_5,
    output reg  [3:0] alu_ctrl
);
    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl = 4'b0000; // Load / Store  → ADD
            2'b01: alu_ctrl = 4'b0001; // Branch        → SUB
            2'b10: begin               // R-type / I-type ALU
                case (funct3)
                    3'b000: alu_ctrl = funct7_5 ? 4'b0001 : 4'b0000; // SUB / ADD
                    3'b001: alu_ctrl = 4'b0101;  // SLL
                    3'b010: alu_ctrl = 4'b1000;  // SLT
                    3'b011: alu_ctrl = 4'b1001;  // SLTU
                    3'b100: alu_ctrl = 4'b0100;  // XOR
                    3'b101: alu_ctrl = funct7_5 ? 4'b0111 : 4'b0110; // SRA / SRL
                    3'b110: alu_ctrl = 4'b0011;  // OR
                    3'b111: alu_ctrl = 4'b0010;  // AND
                    default: alu_ctrl = 4'b0000;
                endcase
            end
            default: alu_ctrl = 4'b0000;
        endcase
    end
endmodule
