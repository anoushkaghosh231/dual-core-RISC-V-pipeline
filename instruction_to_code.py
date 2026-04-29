def reg_num(r):
    # Convert "x5" → 5
    #print("hi",int(r.replace("x", "")))
    return int(r.replace("x", ""))

def assemble(line):
    tokens = line.replace(",", "").split()
    #print("o",tokens)
    if not tokens:
        return 0x00000013  # NOP

    mnemonic = tokens[0]

    # ADDI (I-type)
    if mnemonic == "addi":
        rd = reg_num(tokens[1])
        rs1 = reg_num(tokens[2])
        imm = int(tokens[3])
        opcode = 0b0010011
        funct3 = 0b000
        instr = ((imm & 0xfff) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode
        return instr

    # ADD / SUB / AND / OR / XOR / SLL / SRL (R-type)
    elif mnemonic in ["add", "sub", "and", "or", "xor", "sll", "srl"]:
        rd = reg_num(tokens[1])
        rs1 = reg_num(tokens[2])
        rs2 = reg_num(tokens[3])
        opcode = 0b0110011
        funct3_map = {
            "add": 0b000, "sub": 0b000,
            "and": 0b111, "or": 0b110,
            "xor": 0b100, "sll": 0b001,
            "srl": 0b101
        }
        funct7_map = {
            "add": 0b0000000, "sub": 0b0100000,
            "and": 0b0000000, "or": 0b0000000,
            "xor": 0b0000000, "sll": 0b0000000,
            "srl": 0b0000000
        }
        funct3 = funct3_map[mnemonic]
        funct7 = funct7_map[mnemonic]
        instr = (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode
        return instr

    # SW (S-type)
    elif mnemonic == "sw":
        rs2 = reg_num(tokens[1])
        imm, rs1 = tokens[2].split("(")
        rs1 = reg_num(rs1[:-1])  # remove ')'
        imm = int(imm)
        opcode = 0b0100011
        funct3 = 0b010
        imm11_5 = (imm >> 5) & 0x7f
        imm4_0 = imm & 0x1f
        instr = (imm11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm4_0 << 7) | opcode
        return instr

    # LW (I-type load)
    elif mnemonic == "lw":
        rd = reg_num(tokens[1])
        imm, rs1 = tokens[2].split("(")
        rs1 = reg_num(rs1[:-1])
        imm = int(imm)
        opcode = 0b0000011
        funct3 = 0b010
        instr = ((imm & 0xfff) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode
        return instr

    # BEQ (B-type)
    elif mnemonic == "beq":
        rs1 = reg_num(tokens[1])
        rs2 = reg_num(tokens[2])
        imm = int(tokens[3])
        opcode = 0b1100011
        funct3 = 0b000
        imm12 = (imm >> 12) & 0x1
        imm10_5 = (imm >> 5) & 0x3f
        imm4_1 = (imm >> 1) & 0xf
        imm11 = (imm >> 11) & 0x1
        instr = (imm12 << 31) | (imm11 << 7) | (imm10_5 << 25) | (imm4_1 << 8) | \
                (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | opcode
        return instr

    # Default → NOP
    else:
        return 0x00000013

program = [
    "addi x1, x0, 5",
    "addi x2, x0, 10",
    "add x3, x1, x2",
    "sub x4, x1, x2",
    "and x5, x1, x2",
    "or x6, x1, x2",
    "sw x3, 0(x0)",
    "lw x7, 0(x0)",
    "add x8, x7, x1",
    "beq x1, x1, 8",
    "addi x9, x0, 99",
    "addi x10, x0, 42",
    "sll x11, x1, x2",
    "srl x12, x1, x2",
    "xor x13, x1, x2"
]

for instr in program:
    print(instr, "→", hex(assemble(instr)))

hex_codes = [hex(assemble(instr)) for instr in program]

with open("program.mem", "w") as f:
    for code in hex_codes:
        f.write(code[2:] + "\n")  # strip '0x'