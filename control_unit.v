// ============================================================
//  Main Control Unit
//  Decodes the 7-bit opcode and drives all pipeline control
//  signals for the RV32I subset supported here.
// ============================================================
module ControlUnit (
    input  wire [6:0] opcode,
    output reg        RegWrite,
    output reg        ALUSrc,
    output reg        MemRead,
    output reg        MemWrite,
    output reg        MemToReg,
    output reg        Branch,
    output reg  [1:0] ALUOp
);
    always @(*) begin
        // Safe defaults (NOP)
        {RegWrite, ALUSrc, MemRead, MemWrite, MemToReg, Branch} = 6'b0;
        ALUOp = 2'b00;

        case (opcode)
            7'b0110011: begin // R-type
                RegWrite = 1; ALUSrc = 0; MemRead = 0; MemWrite = 0;
                MemToReg = 0; Branch = 0; ALUOp = 2'b10;
            end
            7'b0010011: begin // I-type ALU (addi, ori, …)
                RegWrite = 1; ALUSrc = 1; MemRead = 0; MemWrite = 0;
                MemToReg = 0; Branch = 0; ALUOp = 2'b10;
            end
            7'b0000011: begin // Load (lw)
                RegWrite = 1; ALUSrc = 1; MemRead = 1; MemWrite = 0;
                MemToReg = 1; Branch = 0; ALUOp = 2'b00;
            end
            7'b0100011: begin // Store (sw)
                RegWrite = 0; ALUSrc = 1; MemRead = 0; MemWrite = 1;
                MemToReg = 0; Branch = 0; ALUOp = 2'b00;
            end
            7'b1100011: begin // Branch (beq, bne, …)
                RegWrite = 0; ALUSrc = 0; MemRead = 0; MemWrite = 0;
                MemToReg = 0; Branch = 1; ALUOp = 2'b01;
            end
            default: begin
                RegWrite = 0; ALUSrc = 0; MemRead = 0; MemWrite = 0;
                MemToReg = 0; Branch = 0; ALUOp = 2'b00;
            end
        endcase
    end
endmodule
