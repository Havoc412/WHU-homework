module alu(
    input signed [31:0] A, B,
    input [4:0] ALUOp,
    output reg signed [31:0] C,
    output reg [7:0] Zero // 用于bne，beq的判断, 但是为什么是 8 位？
    );

    // parameter ALUOp_add = 2'b00;
    // parameter ALUOp_sub = 2'b01;
    // paramater 好像无法作为 case 的关键字
    `define ALUOp_add 5'b00001
    `define ALUOp_sub 5'b00000

    `define ALUOp_slli 5'b00010
    `define ALUOp_srli 5'b00011

    integer n, up2;

    // 不需要 clk
    always @ (*) begin
        case(ALUOp)
            `ALUOp_add: C = A + B;
            `ALUOp_sub: C = A - B;
            `ALUOp_slli: C = A << B;
            `ALUOp_srli: C = A >> B;
        endcase
        Zero = (C == 0)? 1 : 0;
    end
endmodule