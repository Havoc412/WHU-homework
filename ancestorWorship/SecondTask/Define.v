// 1. base Type -> OpCode
`define I_TYPE 7'b0010011   // imm

`define B_TYPE 7'b1100011   // 条件跳转
`define L_TYPE 7'b0000011   // Load
`define S_TYPE 7'b0100011   // store
`define R_TYPE 7'b0110011   // read

`define U_LUI   7'b0110111  // imm -> rd
`define U_AUIPC 7'b0010111  // imm + PC -> rd

`define J_JAL   7'b1101111  // imm20(expand signed + <<1) + PC / nextPC -> rd
`define J_JALR  7'b1100111  // imm12 + rs1 (end 0) / nextPC -> rd

// 2. func3
    // tag B_TYPE
// `define  

