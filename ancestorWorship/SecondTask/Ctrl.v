`include "Define.v"

module Ctrl(
    input [6: 0] opcode,
    input [2: 0] funct3,
    input [6: 0] funct7,
    input [`RFIDX_WIDTH-1: 0] rd, rs1,
    input [11: 0] imm,
    // input zero, lt,  // question zero 作为 ALU 的输出，em，如何作为 Ctrl 的输入...
    
    output regWrite, memWrite, memToReg, // question memToReg?
    output [1: 0] lwhb, swhb, // type of read && store
    output iType, Jal, Jalr, b_unsigned, l_unsigned, // info 为了区分，我使用了大写的 J。
               
    output [5: 0] extCtrl,
    output reg [3: 0] aluCtrl, // reg -> 用 always 赋值, // question 不确定有无 BUG,
    output reg [`BRANCH_CTRL_WIDTH-1: 0] pcBranchSrc,   // info 因为有 jal 的存在，所以 0 代表 pc+4，1 代表 pc ~ bType 
    output [1: 0] rfSrc_wd,
    // output [1: 0] aluSrc_a, // question
    output aluSrc_b // info 判断 alu2 <- immOut，优先级高于 forward
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
    wire addrr = (opcode == `R_TYPE); // info 无需 imm

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
    wire sw = store & (funct3 == `FUNCT3_SW);

    wire addi = addri & (funct3 == `FUNCT3_ADDI);
    wire slti = addri & (funct3 == `FUNCT3_SLTI);
    wire sltiu = addri & (funct3 == `FUNCT3_SLTIU);
    wire xori = addri & (funct3 == `FUNCT3_XORI);
    wire ori = addri & (funct3 == `FUNCT3_ORI);
    wire andi = addri & (funct3 == `FUNCT3_ANDI);
    wire slli = addri & (funct3 == `FUNCT3_SLLI) & (funct7 == `FUNCT7_SLLI);
    wire srli = addri & (funct3 == `FUNCT3_SRLI) & (funct7 == `FUNCT7_SRLI);
    wire srai = addri & (funct3 == `FUNCT3_SRAI) & (funct7 == `FUNCT7_SRAI);

    wire add = addrr & (funct3 == `FUNCT3_ADD) & (funct7 == `FUNCT7_ADD);
    wire sub = addrr & (funct3 == `FUNCT3_SUB) & (funct7 == `FUNCT7_SUB);
    wire sll = addrr & (funct3 == `FUNCT3_SLL);
    wire slt = addrr & (funct3 == `FUNCT3_SLT);
    wire sltu = addrr & (funct3 == `FUNCT3_SLTU);
    wire srl = addrr & (funct3 == `FUNCT3_SRL) & (funct7 == `FUNCT7_SRL);
    wire sra = addrr & (funct3 == `FUNCT3_SRA) & (funct7 == `FUNCT7_SRA);
    wire orr = addrr & (funct3 == `FUNCT3_OR);
    wire xorr = addrr & (funct3 == `FUNCT3_XOR);
    wire andr = addrr & (funct3 == `FUNCT3_AND);

    // 3.
        // tag NOP
    wire rv32_rs1_x0 = (rs1 == 5'b00000);
    wire rv32_rd_x0 = (rd == 5'b00000);
    wire rv32_nop = addi & rv32_rs1_x0 & rv32_rd_x0 & (imm == 12'b0); //addi x0, x0, 0 is nop

        // tag Opcode
    wire shamt = slli | srli | srai;
    // info shamt 属于 itype 的 分支
    wire itype = addri | load ;     // info load 和 immALU 相同。
    assign iType = addri | jalr;   // info 添加 jalr ！

    wire stype = store;
    wire btype = branch;
    wire utype = lui | auipc;
    wire jtype = jal | jalr;  // 两者不同，无用。 -> rfSrc 有用

    // 4. 
    assign extCtrl = {shamt, itype & ~shamt , stype, btype, utype, jal};

    assign Jal = jal;
    assign Jalr = jalr;
    assign b_unsigned = 0;
    assign l_unsigned = 0;

    assign memWrite = stype;
    assign regWrite = lui | auipc | itype | jal | addrr; // mark 只是部分的指令。 // todo
    assign memToReg = load; // question itype 也包括了 load，不确定会不会有BUG。

        // tag src
    // assign pcBranchSrc = btype; // todo ...
    // assign aluSrc_a = lui ? 2'b01 : (auipc ? 2'b10 : 2'b00); // 6, miao // todo
    assign rfSrc_wd = { jtype, load }; // bug wait test // info ori: assign rfSrc_wd = { utype | jtype, load};
    assign aluSrc_b = lui | auipc | itype | stype; // todo 关于 Itype 指令，暂时只考虑了 addi，如果需要其他的再添加。
    assign lwhb = lb ? `SL_B : (lh ? `SL_H : (lw ? `SL_W : `SL_ZERO));
    assign swhb = sb ? `SL_B : (sh ? `SL_H : (sw ? `SL_W : `SL_ZERO));

        // tag aluCtrl // todo more...
    always @(*) begin 
        pcBranchSrc <= `BRANCH_CTRL_ZERO; // info 取消后效性。
        case(opcode)
            `U_LUI: aluCtrl <= `ALU_CTRL_ADD;
            `U_AUIPC: aluCtrl <= `ALU_CTRL_ADD;
            `I_TYPE: 
                if(addi)
                    aluCtrl <= `ALU_CTRL_ADD;
                else if(slli)
                    aluCtrl <= `ALU_CTRL_SLL;
                else if(srli)
                    aluCtrl <= `ALU_CTRL_SRL;
                else if(andi)
                    aluCtrl <= `ALU_CTRL_AND;
                else
                    aluCtrl <= `ALU_CTRL_ZERO;
            `R_TYPE: 
                if(sub)
                    aluCtrl <= `ALU_CTRL_SUB;
                else if(add)
                    aluCtrl <= `ALU_CTRL_ADD;
                else if(orr)
                    aluCtrl <= `ALU_CTRL_OR;
                else if(xorr)
                    aluCtrl <= `ALU_CTRL_XOR;
                else if(sll)
                    aluCtrl <= `ALU_CTRL_SLL;
                else if(sra)
                    aluCtrl <= `ALU_CTRL_SRA;
                else if(srl)
                    aluCtrl <= `ALU_CTRL_SRL;
                else if(andr)
                    aluCtrl <= `ALU_CTRL_AND;
                else
                    aluCtrl <= `ALU_CTRL_ZERO;
            `B_TYPE: begin // todo 因为 B 指令全覆盖了，所以可以考虑直接用 FUNCT3
                aluCtrl <= `ALU_CTRL_SUB;   // info 全员做减法，然后使用 zero，嗯，有效。
                if(beq)
                    pcBranchSrc <= `BRANCH_CTRL_BEQ;
                else if(bne)
                    pcBranchSrc <= `BRANCH_CTRL_BNE;
                else if(blt)
                    pcBranchSrc <= `BRANCH_CTRL_BLT;
                else if(bge)
                    pcBranchSrc <= `BRANCH_CTRL_BGE;
                else if(bltu)
                    pcBranchSrc <= `BRANCH_CTRL_BLTU;
                else if(bgeu)
                    pcBranchSrc <= `BRANCH_CTRL_BGEU;
                else
                    pcBranchSrc <= `BRANCH_CTRL_ZERO;
            end
            `S_TYPE: aluCtrl <= `ALU_CTRL_ADD; // info store 和 load 都是单纯的 ALU-ADD 计算目标地址。
            `L_TYPE: aluCtrl <= `ALU_CTRL_ADD;
                
            default: aluCtrl <= `ALU_CTRL_ZERO;
        endcase
    end

endmodule