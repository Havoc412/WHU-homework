// 0. ISA
`define ADDR_LEN  32

`define XLEN 32
`define XLEN_WIDTH 5

`define RFREG_NUM 32
`define RFIDX_WIDTH 5


// 1. base Type -> OpCode
`define I_TYPE  7'b0010011   // imm - ALU

`define B_TYPE  7'b1100011   // compare
`define L_TYPE  7'b0000011   // Load
`define S_TYPE  7'b0100011   // store
`define R_TYPE  7'b0110011   // common alu

`define U_LUI   7'b0110111  // imm -> rd
`define U_AUIPC 7'b0010111  // imm + PC -> rd

`define J_JAL   7'b1101111  // imm20(expand signed 符号扩展 && <<1) + PC / nextPC -> rd
                            // mark imm 错位的设计
`define J_JALR  7'b1100111  // imm12 + rs1 (end 0) / nextPC -> rd


// 2.1 func3
    // tag B_TYPE
`define FUNCT3_BEQ  3'b000    // if rs1 == rs2, then PC += imm12 << 1
`define FUNCT3_BNE  3'b001    // if rs1 != rs2, then PC += imm12 << 1
`define FUNCT3_BLT  3'b100    // if rs1 < rs2, then PC += imm12 << 1
`define FUNCT3_BGE  3'b101    // if rs1 >= rs2, then PC += imm12 << 1
    // mark 以上为 有符号数，以下为 无符号数
`define FUNCT3_BLTU 3'b110   // if rs1 < rs2, then PC += imm12 << 1
`define FUNCT3_BGEU 3'b111   // if rs1 >= rs2, then PC += imm12 << 1

    // tag L_TYPE (also like I_TYPE)
`define FUNCT3_LB  3'b000     // 1 B;  rs1 + imm12 -> rd
`define FUNCT3_LH  3'b000     // 2 B;  rs1 + imm12 -> rd
`define FUNCT3_LW  3'b010     // 4 B;  rs1 + imm12 -> rd
    // mark 以上为 有符号数，以下为 无符号数
`define FUNCT3_LBU 3'b100    // ..
`define FUNCT3_LHU 3'b101

    // tag S_TYPE
`define FUNCT3_SB 3'b000     // 1 B;    rs2(Lowest 1B) -> rs1 + imm12
`define FUNCT3_SH 3'b001     // 2 B;    rs2(lowest 2B) -> rs1 + imm12
`define FUNCT3_SW 3'b010     // 4 B;    rs2(all) -> rs1 + imm12

    // tag I_TYPE
`define FUNCT3_ADDI  3'b000   // rs1 + imm12 -> rd    // 忽略溢出
        // 立即数 - 比较
`define FUNCT3_SLTI  3'b010   // rd = rs1(signed) < imm12 ? 1 : 0    
`define FUNCT3_SLTIU 3'b011   // rd = rs1(unsigned) < imm12 ? 1: 0

`define FUNCT3_XORI 3'b100   // rs1 ^ imm12 -> rd
`define FUNCT3_ORI  3'b110   // rs1 | imm12 -> rd
`define FUNCT3_ANI  3'b111   // rs1 & imm12 -> rd
`define FUNCT3_SLLI 3'b001   // rs1 << imm5 -> rd
`define FUNCT3_SRLI 3'b101   // rs1 >> imm5 -> rd, 逻辑右移，空位补 0
                            // mark 依靠 FUNCT7 区分
`define FUNCT3_SRAI 3'b101   // rs1 >> imm5 -> rd


// 3. FUNCT7
    // tag I_TYPE - shamt 类型
`define FUNCT7_SLLI 7'b00000000
`define FUNCT7_SRLI 7'b00000000
`define FUNCT7_SRAI 7'b01000000

    // tag R_TYPE 
`define FUNCT7_ADD 7'b0000000
`define FUNCT7_SUB 7'b0100000

`define FUNCT7_SRL 7'b0000000
`define FUNCT7_SRA 7'b0100000
// `define FUNCT7_SLL 7'b0000000 // 还有其他几个，暂时用不到。


// 2.2 FUNCT3
    // tag R_TYPE
`define FUNCT3_ADD  3'b000   // rd = rs1 + rs2
`define FUNCT3_SUB  3'b000   // rd = rs1 - rs2  // ps. 忽略溢出

`define FUNCT3_SLL  3'b001   // rd = rs1 << rs2[4:0]
`define FUNCT3_SLT  3'b010   // rd = rs1 < rs2 ? 1: 0
`define FUNCT3_SLTU 3'b011   // rd = (unsigned) rs1 < rs2 ? 1: 0
`define FUNCT3_SRL  3'b101   // rd = rs1 >> rs2[4:0]     // Logic: 空位补 0
`define FUNCT3_SRA  3'b101   // rd = rs1 >> rs2[4:0]

`define FUNCT3_XOR  3'b100   // rd = rs1 ^ rs2
`define FUNCT3_OR   3'b110   // rd = rs1 | rs2
`define FUNCT3_AND  3'b111   // rd = rs1 & rs2




