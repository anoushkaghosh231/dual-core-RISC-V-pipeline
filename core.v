// ============================================================
//  core.v  –  Single 5-Stage Pipelined RISC-V Core (RV32I)
//
//  Stages  : IF → ID → EX → MEM → WB
//  Features: Data forwarding, load-use stall, branch flush
//
//  Parameterised so Core 0 and Core 1 can run different
//  initial programs simply by changing IMEM_INIT_FILE or
//  by editing the two InstructionMemory instantiations in
//  dual_core_top.v.
//
//  The register file is instantiated inside this module but
//  its debug-read port is exposed at the top level so the
//  display logic can inspect any register without disturbing
//  normal pipeline operation.
// ============================================================

// ---- Immediate Generator ------------------------------------
module ImmGen (
    input  wire [31:0] instr,
    output reg  [31:0] imm_out
);
    wire [6:0] opcode = instr[6:0];
    always @(*) begin
        case (opcode)
            7'b0010011,          // I-type ALU
            7'b0000011:          // Load
                imm_out = {{20{instr[31]}}, instr[31:20]};
            7'b0100011:          // S-type Store
                imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            7'b1100011:          // B-type Branch
                imm_out = {{19{instr[31]}}, instr[31], instr[7],
                           instr[30:25], instr[11:8], 1'b0};
            7'b1101111:          // J-type JAL
                imm_out = {{11{instr[31]}}, instr[31], instr[19:12],
                           instr[20], instr[30:21], 1'b0};
            7'b0110111,          // U-type LUI
            7'b0010111:          // AUIPC
                imm_out = {instr[31:12], 12'b0};
            default:
                imm_out = 32'h0;
        endcase
    end
endmodule

// ---- Hazard Detection Unit ----------------------------------
module HazardDetection (
    input  wire        ID_EX_MemRead,
    input  wire [4:0]  ID_EX_rd,
    input  wire [4:0]  IF_ID_rs1,
    input  wire [4:0]  IF_ID_rs2,
    output reg         pc_stall,
    output reg         IF_ID_stall,
    output reg         control_flush
);
    always @(*) begin
        if (ID_EX_MemRead &&
           ((ID_EX_rd == IF_ID_rs1) || (ID_EX_rd == IF_ID_rs2))) begin
            pc_stall      = 1'b1;
            IF_ID_stall   = 1'b1;
            control_flush = 1'b1;
        end else begin
            pc_stall      = 1'b0;
            IF_ID_stall   = 1'b0;
            control_flush = 1'b0;
        end
    end
endmodule

// ---- Forwarding Unit ----------------------------------------
module ForwardingUnit (
    input  wire [4:0] EX_MEM_rd,
    input  wire [4:0] MEM_WB_rd,
    input  wire       EX_MEM_RegWrite,
    input  wire       MEM_WB_RegWrite,
    input  wire [4:0] ID_EX_rs1,
    input  wire [4:0] ID_EX_rs2,
    output reg  [1:0] forward_a,
    output reg  [1:0] forward_b
);
    always @(*) begin
        // ---- Forward A ----
        if (EX_MEM_RegWrite && (EX_MEM_rd != 5'h0) &&
            (EX_MEM_rd == ID_EX_rs1))
            forward_a = 2'b10;
        else if (MEM_WB_RegWrite && (MEM_WB_rd != 5'h0) &&
                 (MEM_WB_rd == ID_EX_rs1))
            forward_a = 2'b01;
        else
            forward_a = 2'b00;

        // ---- Forward B ----
        if (EX_MEM_RegWrite && (EX_MEM_rd != 5'h0) &&
            (EX_MEM_rd == ID_EX_rs2))
            forward_b = 2'b10;
        else if (MEM_WB_RegWrite && (MEM_WB_rd != 5'h0) &&
                 (MEM_WB_rd == ID_EX_rs2))
            forward_b = 2'b01;
        else
            forward_b = 2'b00;
    end
endmodule

// ---- Instruction Memory (ROM – 256 × 32) --------------------
//  Core 0 program  –  same test program as the original design
module InstrMem_Core0 (
    input  wire [31:0] addr,
    output wire [31:0] instr
);
    reg [31:0] mem [0:255];
    integer i;
    initial begin
        //  addi x1,  x0,  5       x1  = 5
        //  addi x2,  x0,  10      x2  = 10
        //  add  x3,  x1,  x2      x3  = 15
        //  sub  x4,  x1,  x2      x4  = -5
        //  and  x5,  x1,  x2      x5  = 0
        //  or   x6,  x1,  x2      x6  = 15
        //  sw   x3,  0(x0)        mem[0] = 15
        //  lw   x7,  0(x0)        x7  = 15  (load-use hazard)
        //  add  x8,  x7,  x1      x8  = 20  (stall one cycle)
        //  beq  x1,  x1,  8       branch → skip next two words
        //  addi x9,  x0,  99      SKIPPED
        //  addi x10, x0,  42      x10 = 42
        //  sll  x11, x1,  x2      x11 = 5 << 10 = 5120
        //  srl  x12, x1,  x2      x12 = 5 >> 10 = 0
        //  xor  x13, x1,  x2      x13 = 15
        /*mem[0]  = 32'h00500093;
        mem[1]  = 32'h00a00113;
        mem[2]  = 32'h002081b3;
        mem[3]  = 32'h40208233;
        mem[4]  = 32'h0020f2b3;
        mem[5]  = 32'h0020e333;
        mem[6]  = 32'h00302023;
        mem[7]  = 32'h00002383;
        mem[8]  = 32'h00138433;
        mem[9]  = 32'h00108463;
        mem[10] = 32'h06300493;
        mem[11] = 32'h02a00513;
        mem[12] = 32'h002095b3;
        mem[13] = 32'h0020d633;
        mem[14] = 32'h0020c6b3;
        for (i = 15; i < 256; i = i + 1)
            mem[i] = 32'h00000013; // NOP*/
        $readmemh("program.mem", mem);  // Load instructions from file
    end
    assign instr = mem[addr[9:2]];
endmodule

// ---- Instruction Memory – Core 1 ----------------------------
//  A different demo program to show the two cores are
//  independent:
//    addi x1, x0, 3     x1 = 3
//    addi x2, x0, 7     x2 = 7
//    add  x3, x1, x2    x3 = 10
//    sub  x4, x2, x1    x4 = 4
//    or   x5, x1, x2    x5 = 7
//    and  x6, x1, x2    x6 = 3
//    xor  x7, x1, x2    x7 = 4
//    sll  x8, x1, x2    x8 = 3 << 7 = 384
//    addi x9, x0, 100   x9 = 100
module InstrMem_Core1 (
    input  wire [31:0] addr,
    output wire [31:0] instr
);
    reg [31:0] mem [0:255];
    integer i;
    initial begin
        mem[0]  = 32'h00300093; // addi x1,  x0, 3
        mem[1]  = 32'h00700113; // addi x2,  x0, 7
        mem[2]  = 32'h002081b3; // add  x3,  x1, x2
        mem[3]  = 32'h40108233; // sub  x4,  x2, x1
        mem[4]  = 32'h0020e2b3; // or   x5,  x1, x2
        mem[5]  = 32'h0020f333; // and  x6,  x1, x2
        mem[6]  = 32'h0020c3b3; // xor  x7,  x1, x2
        mem[7]  = 32'h00209433; // sll  x8,  x1, x2
        mem[8]  = 32'h06400493; // addi x9,  x0, 100
        for (i = 9; i < 256; i = i + 1)
            mem[i] = 32'h00000013; // NOP
    end
    assign instr = mem[addr[9:2]];
endmodule

// ---- Data Memory (BRAM – 256 × 32) -------------------------
module DataMemory (
    input  wire        clk,
    input  wire        MemRead,
    input  wire        MemWrite,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    output wire [31:0] read_data
);
    reg [31:0] mem [0:255];
    integer j;
    initial begin
        for (j = 0; j < 256; j = j + 1)
            mem[j] = 32'h0;
    end
    always @(posedge clk) begin
        if (MemWrite)
            mem[addr[9:2]] <= write_data;
    end
    assign read_data = MemRead ? mem[addr[9:2]] : 32'h0;
endmodule

// ============================================================
//  CORE  –  top-level single-core pipeline wrapper
//  CORE_ID selects which instruction memory is used (0 or 1).
// ============================================================
module Core #(
    parameter CORE_ID = 0  // 0 = Core0 program, 1 = Core1 program
) (
    input  wire        clk,
    input  wire        reset,
    // Debug / display port
    input  wire [4:0]  dbg_reg_addr,
    output wire [31:0] dbg_reg_data,
    // Activity indicator (pulsed on write-back)
    output wire        wb_active
);

    // ================================================================
    //  Internal wires and registers
    // ================================================================

    // IF stage
    wire [31:0] pc_current;
    wire [31:0] pc_plus4;
    wire [31:0] instr_IF;

    // Hazard / forwarding control
    wire        pc_stall, IF_ID_stall, ctrl_flush;

    // IF/ID pipeline register outputs
    wire [31:0] IF_ID_pc_r, IF_ID_instr_r;

    // ID stage
    wire [4:0]  rs1_ID, rs2_ID, rd_ID;
    wire [31:0] read_data1_ID, read_data2_ID;
    wire [31:0] imm_ID;
    wire        RegWrite_ID, ALUSrc_ID, MemRead_ID;
    wire        MemWrite_ID, MemToReg_ID, Branch_ID;
    wire [1:0]  ALUOp_ID;

    // ID/EX pipeline register outputs
    wire [31:0] ID_EX_pc_r, ID_EX_rd1_r, ID_EX_rd2_r, ID_EX_imm_r;
    wire [4:0]  ID_EX_rs1_r, ID_EX_rs2_r, ID_EX_rd_r;
    wire [2:0]  ID_EX_funct3_r;
    wire        ID_EX_funct7_5_r;
    wire        ID_EX_RegWrite_r, ID_EX_ALUSrc_r, ID_EX_MemRead_r;
    wire        ID_EX_MemWrite_r, ID_EX_MemToReg_r, ID_EX_Branch_r;
    wire [1:0]  ID_EX_ALUOp_r;

    // EX stage
    wire [1:0]  forward_a, forward_b;
    wire [31:0] alu_in_a, alu_in_b, alu_src_b;
    wire [3:0]  alu_ctrl;
    wire [31:0] alu_result_EX;
    wire        zero_EX;
    wire [31:0] pc_branch_EX;

    // EX/MEM pipeline register outputs
    wire [31:0] EX_MEM_pc_branch_r, EX_MEM_alu_result_r, EX_MEM_rd2_r;
    wire [4:0]  EX_MEM_rd_r;
    wire        EX_MEM_zero_r;
    wire        EX_MEM_RegWrite_r, EX_MEM_MemRead_r;
    wire        EX_MEM_MemWrite_r, EX_MEM_MemToReg_r, EX_MEM_Branch_r;

    // MEM stage
    wire [31:0] mem_read_data_MEM;
    wire        branch_taken;

    // MEM/WB pipeline register outputs
    wire [31:0] MEM_WB_alu_result_r, MEM_WB_mem_data_r;
    wire [4:0]  MEM_WB_rd_r;
    wire        MEM_WB_RegWrite_r, MEM_WB_MemToReg_r;

    // WB stage
    wire [31:0] wb_data;

    // ================================================================
    //  STAGE 1 – INSTRUCTION FETCH
    // ================================================================

    assign pc_plus4    = pc_current + 32'd4;
    assign branch_taken = EX_MEM_Branch_r & EX_MEM_zero_r;
    wire [31:0] pc_next = branch_taken ? EX_MEM_pc_branch_r : pc_plus4;

    // Program Counter
    reg [31:0] pc_reg;
    always @(posedge clk or posedge reset) begin
        if (reset)         pc_reg <= 32'h0;
        else if (!pc_stall) pc_reg <= pc_next;
    end
    assign pc_current = pc_reg;

    // Instruction memories (only one is synthesised per instance)
    generate
        if (CORE_ID == 0) begin : imem_core0
            InstrMem_Core0 imem (.addr(pc_current), .instr(instr_IF));
        end else begin : imem_core1
            InstrMem_Core1 imem (.addr(pc_current), .instr(instr_IF));
        end
    endgenerate

    // IF/ID register
    IF_ID_Reg if_id_reg (
        .clk      (clk),
        .reset    (reset),
        .flush    (branch_taken),
        .stall    (IF_ID_stall),
        .pc_in    (pc_current),
        .instr_in (instr_IF),
        .pc_out   (IF_ID_pc_r),
        .instr_out(IF_ID_instr_r)
    );

    // ================================================================
    //  STAGE 2 – INSTRUCTION DECODE
    // ================================================================

    assign rs1_ID = IF_ID_instr_r[19:15];
    assign rs2_ID = IF_ID_instr_r[24:20];
    assign rd_ID  = IF_ID_instr_r[11:7];

    RegisterFile regfile (
        .clk        (clk),
        .reset      (reset),
        .RegWrite   (MEM_WB_RegWrite_r),
        .rs1        (rs1_ID),
        .rs2        (rs2_ID),
        .rd         (MEM_WB_rd_r),
        .write_data (wb_data),
        .read_data1 (read_data1_ID),
        .read_data2 (read_data2_ID),
        .dbg_addr   (dbg_reg_addr),
        .dbg_data   (dbg_reg_data)
    );
    //ImmGen and CU checks opcode and sets regs/sign extends immediates
    ImmGen immgen (
        .instr  (IF_ID_instr_r),
        .imm_out(imm_ID)
    );

    ControlUnit ctrl (
        .opcode   (IF_ID_instr_r[6:0]),
        .RegWrite (RegWrite_ID),
        .ALUSrc   (ALUSrc_ID),
        .MemRead  (MemRead_ID),
        .MemWrite (MemWrite_ID),
        .MemToReg (MemToReg_ID),
        .Branch   (Branch_ID),
        .ALUOp    (ALUOp_ID)
    );

    HazardDetection hazard (
        .ID_EX_MemRead (ID_EX_MemRead_r),
        .ID_EX_rd      (ID_EX_rd_r),
        .IF_ID_rs1     (rs1_ID),
        .IF_ID_rs2     (rs2_ID),
        .pc_stall      (pc_stall),
        .IF_ID_stall   (IF_ID_stall),
        .control_flush (ctrl_flush)
    );

    // ID/EX register
    ID_EX_Reg id_ex_reg (
        .clk         (clk),
        .reset       (reset),
        .flush       (ctrl_flush | branch_taken),
        .pc_in       (IF_ID_pc_r),
        .rd1_in      (read_data1_ID),
        .rd2_in      (read_data2_ID),
        .imm_in      (imm_ID),
        .rs1_in      (rs1_ID),
        .rs2_in      (rs2_ID),
        .rd_in       (rd_ID),
        .funct3_in   (IF_ID_instr_r[14:12]),
        .funct7_5_in (IF_ID_instr_r[30]),
        .RegWrite_in (RegWrite_ID),
        .ALUSrc_in   (ALUSrc_ID),
        .MemRead_in  (MemRead_ID),
        .MemWrite_in (MemWrite_ID),
        .MemToReg_in (MemToReg_ID),
        .Branch_in   (Branch_ID),
        .ALUOp_in    (ALUOp_ID),
        .pc_out      (ID_EX_pc_r),
        .rd1_out     (ID_EX_rd1_r),
        .rd2_out     (ID_EX_rd2_r),
        .imm_out     (ID_EX_imm_r),
        .rs1_out     (ID_EX_rs1_r),
        .rs2_out     (ID_EX_rs2_r),
        .rd_out      (ID_EX_rd_r),
        .funct3_out  (ID_EX_funct3_r),
        .funct7_5_out(ID_EX_funct7_5_r),
        .RegWrite_out(ID_EX_RegWrite_r),
        .ALUSrc_out  (ID_EX_ALUSrc_r),
        .MemRead_out (ID_EX_MemRead_r),
        .MemWrite_out(ID_EX_MemWrite_r),
        .MemToReg_out(ID_EX_MemToReg_r),
        .Branch_out  (ID_EX_Branch_r),
        .ALUOp_out   (ID_EX_ALUOp_r)
    );

    // ================================================================
    //  STAGE 3 – EXECUTE
    // ================================================================

    ForwardingUnit fwd (
        .EX_MEM_rd       (EX_MEM_rd_r),
        .MEM_WB_rd       (MEM_WB_rd_r),
        .EX_MEM_RegWrite (EX_MEM_RegWrite_r),
        .MEM_WB_RegWrite (MEM_WB_RegWrite_r),
        .ID_EX_rs1       (ID_EX_rs1_r),
        .ID_EX_rs2       (ID_EX_rs2_r),
        .forward_a       (forward_a),
        .forward_b       (forward_b)
    );

    // Forwarding MUXes
    assign alu_in_a = (forward_a == 2'b10) ? EX_MEM_alu_result_r :
                      (forward_a == 2'b01) ? wb_data              : ID_EX_rd1_r;

    assign alu_src_b = (forward_b == 2'b10) ? EX_MEM_alu_result_r :
                       (forward_b == 2'b01) ? wb_data              : ID_EX_rd2_r;

    assign alu_in_b = ID_EX_ALUSrc_r ? ID_EX_imm_r : alu_src_b;

    ALUControl alu_ctrl_unit (
        .alu_op   (ID_EX_ALUOp_r),
        .funct3   (ID_EX_funct3_r),
        .funct7_5 (ID_EX_funct7_5_r),
        .alu_ctrl (alu_ctrl)
    );

    ALU alu (
        .a        (alu_in_a),
        .b        (alu_in_b),
        .alu_ctrl (alu_ctrl),
        .result   (alu_result_EX),
        .zero     (zero_EX)
    );

    assign pc_branch_EX = ID_EX_pc_r + ID_EX_imm_r;

    // EX/MEM register
    EX_MEM_Reg ex_mem_reg (
        .clk           (clk),
        .reset         (reset),
        .pc_branch_in  (pc_branch_EX),
        .alu_result_in (alu_result_EX),
        .rd2_in        (alu_src_b),
        .rd_in         (ID_EX_rd_r),
        .zero_in       (zero_EX),
        .RegWrite_in   (ID_EX_RegWrite_r),
        .MemRead_in    (ID_EX_MemRead_r),
        .MemWrite_in   (ID_EX_MemWrite_r),
        .MemToReg_in   (ID_EX_MemToReg_r),
        .Branch_in     (ID_EX_Branch_r),
        .pc_branch_out (EX_MEM_pc_branch_r),
        .alu_result_out(EX_MEM_alu_result_r),
        .rd2_out       (EX_MEM_rd2_r),
        .rd_out        (EX_MEM_rd_r),
        .zero_out      (EX_MEM_zero_r),
        .RegWrite_out  (EX_MEM_RegWrite_r),
        .MemRead_out   (EX_MEM_MemRead_r),
        .MemWrite_out  (EX_MEM_MemWrite_r),
        .MemToReg_out  (EX_MEM_MemToReg_r),
        .Branch_out    (EX_MEM_Branch_r)
    );

    // ================================================================
    //  STAGE 4 – MEMORY ACCESS
    // ================================================================

    DataMemory dmem (
        .clk        (clk),
        .MemRead    (EX_MEM_MemRead_r),
        .MemWrite   (EX_MEM_MemWrite_r),
        .addr       (EX_MEM_alu_result_r),
        .write_data (EX_MEM_rd2_r),
        .read_data  (mem_read_data_MEM)
    );

    // MEM/WB register
    MEM_WB_Reg mem_wb_reg (
        .clk           (clk),
        .reset         (reset),
        .alu_result_in (EX_MEM_alu_result_r),
        .mem_data_in   (mem_read_data_MEM),
        .rd_in         (EX_MEM_rd_r),
        .RegWrite_in   (EX_MEM_RegWrite_r),
        .MemToReg_in   (EX_MEM_MemToReg_r),
        .alu_result_out(MEM_WB_alu_result_r),
        .mem_data_out  (MEM_WB_mem_data_r),
        .rd_out        (MEM_WB_rd_r),
        .RegWrite_out  (MEM_WB_RegWrite_r),
        .MemToReg_out  (MEM_WB_MemToReg_r)
    );

    // ================================================================
    //  STAGE 5 – WRITE BACK
    // ================================================================

    assign wb_data  = MEM_WB_MemToReg_r ? MEM_WB_mem_data_r
                                         : MEM_WB_alu_result_r;//WB from memory otherwise ALU result
    assign wb_active = MEM_WB_RegWrite_r && (MEM_WB_rd_r != 5'h0);

endmodule
