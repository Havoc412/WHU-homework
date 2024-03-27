`include "Define.v"

module Ctrl(
    input [6: 0] opcode,
    input [2: 0] funct3,
    input [6: 0] funct7,
    input [`RFIDX_WIDTH-1: 0] rd, rs1,
    input [11: 0] imm,
    input zero, lt, 
    
    output regWrite, memWrite, memToReg, // question memToReg?
    output[1: 0] lwhb, swhb, // type of read && store
    output iType, jal, jalr, b_unsigned, l_unsigned, pcSrc, aluSrc,
    output [4: 0] extCtrl,
    output reg [3: 0] aluCtrl, // question reg ?
    output [1: 0] aluSrc_a,
    output aluSrc_b 
    );

    // 1.1
    wire lui = (opcode == `U_LUI);
    wire auipc = (opcode == `U_AUIPC);
    wire jal = (opcode == `J_JAL);
    wire jalr = (opcode == `J_JALR);

    // 1.2
    wire branch = (opcode == `B_TYPE);
    wire load = (opcode == `L_TYPE);
    wire store = (opcode == `S_TYPE);
    wire addri = (opcode == `I_TYPE);
    wire addrr = (opcode == `R_TYPE);

    // 2.
        // question 关于布线的 复杂度 和 效率。
    wire beq = branch & (funct3 == `FUNCT3_BEQ);
    wire bne = branch & (funct3 == `FUNCT3_BNE);
    wire blt = branch & (funct3 == `FUNCT3_BLT);
    wire bge = branch & (funct3 == `FUNCT3_BGE);
    wire bltu = branch & (funct3 == `FUNCT3_BLTU);
    wire bgeu = branch & (funct3 == `FUNCT3_BGEU);

    wire lb = load & (funct3 == `FUNCT3_LB);
    wire lh = load & (funct3 == `FUNCT3_LH);
    wire lw = load & (funct3 == `FUNCT3_LW);

    wire sb = store & (funct3 == `FUNCT3_SB);
    wire sh = store & (funct3 == `FUNCT3_SH);
    wire sw=  store & (funct3 == `FUNCT3_SW);

    

endmodule