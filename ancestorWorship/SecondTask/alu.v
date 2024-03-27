`include "Define.v"

module alu(
    input signed [`XLEN-1: 0] A, B,
    input [4: 0] shamt, // question 有必要单独处理吗？
    input [4: 0] aluCtrl,

    output reg [`XLEN-1: 0] aluout,
    output overflow,
    output zero, // 相当于ZF，方便bne，beq的判断;
    output lt,  // question 
	output ge // question
    );

    // wire unsigned = 1'b1;  // todo 


    // `define ALUOp_add 5'b00001
    // `define ALUOp_sub 5'b00000

    // `define ALUOp_slli 5'b00010
    // `define ALUOp_srli 5'b00011

    // integer n, up2;

    // // 不需要 clk
    // always @ (*) begin
    //     case(ALUOp)
    //         `ALUOp_add: C = A + B;
    //         `ALUOp_sub: C = A - B;
    //         `ALUOp_slli: C = A << B;
    //         `ALUOp_srli: C = A >> B;
    //     endcase
    //     Zero = (C == 0)? 1 : 0;
    // end
endmodule