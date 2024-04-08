`include "Define.v"

module ALU(
    input [`XLEN-1: 0] a, b,
    input [4: 0] shamt, // question 有必要单独处理吗？
    input [3: 0] aluCtrl,

    output reg [`XLEN-1: 0] aluout,
    output overflow,
    output zero, // 相当于ZF，方便bne，beq的判断;
    output lt,   // question 
	output ge    // question
    );

    // info unsigned 为 key...
    wire unSigned = (aluCtrl == `ALU_CTRL_ADDU) | (aluCtrl == `ALU_CTRL_SUBU) | (aluCtrl == `ALU_CTRL_SLTU);

    // info differentiate SUB and AND by aluCtrl[3]
    wire [`XLEN-1: 0] bb = aluCtrl[3] ? ~b : b;
    
    // 拓宽，以防溢出 // question 【+aluCtrl[3]】 ?
    wire [`XLEN-1: 0] sum = (unSigned & ({1'b0, a} + {1'b0, bb} + aluCtrl[3])) | (~unSigned & ({a[`XLEN-1], a} + {bb[`XLEN-1], bb} + aluCtrl[3]));

    always @(*) begin
        case(aluCtrl)
            `ALU_CTRL_MOVEA: aluout <= a;
            `ALU_CTRL_ADD:   aluout <= sum[`XLEN-1: 0];
            `ALU_CTRL_ADDU:  aluout <= sum[`XLEN-1: 0];
            `ALU_CTRL_SUB:   aluout <= a - b;

            `ALU_CTRL_SLL:   aluout <= a << b;

            `ALU_CTRL_LUI:   aluout <= sum[`XLEN-1: 0]; //a = 0, b = immout
		    `ALU_CTRL_AUIPC: aluout <= sum[`XLEN-1: 0]; //a = pc, b = immout
		    default: 	     aluout <= `XLEN'b0; 
        endcase
    end

    assign overflow = sum[`XLEN-1] ^ sum[`XLEN];    // question
    // info 这三个都是用于 Btype 的，通过判断符号位的大小。
    assign zero = (aluout == `XLEN'b0);
    assign lt = aluout[`XLEN-1];
    assign ge = ~aluout[`XLEN-1];
endmodule