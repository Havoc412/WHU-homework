`include "Define.v"
`include "LittleFunct.v"

// tag addr_adder
module pcenr (
    input clk, rstn, BTNC,
    input en, stop,
    input [`XLEN-1: 0] d,
    output reg [`XLEN-1: 0] q
    );

    always @(posedge clk or negedge rstn or negedge BTNC) begin
        if(!rstn)
            q <= `ADDR_SIZE'h0;
        else if(stop & !BTNC)
            q <= q;
        else if (en)
            q <= d;
        else    // info 代替了 stop 的作用，相当于 NOP。
            q <= q;
    end
    
endmodule

// 处理一般 pc 的加法操作
module addr_adder (
    input [`ADDR_SIZE-1: 0] a, b,
    output [`ADDR_SIZE-1: 0] y
    );

    assign y = a + b;
    
endmodule

// info 为配合 IP核 使用，将 一般以 4 为基本单位的 PC，处理为 IP核 可以使用的 index。
module pcHandleForIP #(parameter INSTR_WIDTH = 8, parameter ADDR_WIDTH = 6) (
        input [INSTR_WIDTH-1: 0] pc,
        output [ADDR_WIDTH-1: 0] romAddr 
    );

    assign romAddr = pc >> 2;
    
endmodule

// info core 核心信号的处理
module pcBranch (
    // IF
    input [`INSTR_SIZE-1: 0] pcF,
    input stall,
    // ID
    input [`INSTR_SIZE-1: 0] pcD,
    input [`XLEN-1: 0] immOutD, rs1DataE, // info jalr 需要在 EX 阶段处理数据冒险
    input jalD, jalrE,
    // EX
    input [`BRANCH_CTRL_WIDTH-1: 0] pcBranchSrcE, 
    input zeroE, ltE, geE,
    // output branchE,
    input [`INSTR_SIZE-1: 0] pcE, 
    input [`XLEN-1: 0] immOutE,
    // END: next pc
    output [`INSTR_SIZE-1: 0] nextPcF,
    // flush
    output flushD, flushE 
);
    // IF
    wire [`INSTR_SIZE-1: 0] pcPlus4F;
    addr_adder pcAdder1(pcF, `ADDR_SIZE'b100, pcPlus4F); // pcPlus4F = pcF + 4

    // ID for jal && EX for jalr
    wire [`INSTR_SIZE-1: 0] pcJalD, pcJarE;
    addr_adder pcAdder2(pcD, immOutD, pcJalD);
    addr_adder pcAdder3(rs1DataE, immOutE, pcJarE);

    // EX
    wire [`INSTR_SIZE-1: 0] pcBranchE;
    wire branchE, beq, bne, blt, bge;
    assign beq = (pcBranchSrcE == `BRANCH_CTRL_BEQ) & zeroE;
    assign bne = (pcBranchSrcE == `BRANCH_CTRL_BNE) & ~zeroE;
    assign blt = (pcBranchSrcE == `BRANCH_CTRL_BLT | pcBranchSrcE == `BRANCH_CTRL_BLTU) & ltE;
    assign bge = (pcBranchSrcE == `BRANCH_CTRL_BGE | pcBranchSrcE == `BRANCH_CTRL_BGEU) & geE;
    assign branchE = beq | bne | blt | bge;
                    
    addr_adder pcBranch_E(pcE, immOutE, pcBranchE);

    // next PC
    mux4 #(`INSTR_SIZE) pcBranchSrcMux(pcPlus4F, pcJalD, pcJarE, pcBranchE,  { branchE, jalrE, jalD }, nextPcF);

    // flush
    assign flushD = jalD | jalrE | stall | branchE;
    assign flushE = branchE | jalrE;

endmodule

// tag 阻塞
module hazard (
    input clk, rstn,
    input [`RFIDX_WIDTH: 0] rs1D, rs2D, rdE,
    input memReadE, // 遇到 load 类型时，stall 一个周期，然后 forward 就可以正常运行。

    output reg stall 
);
    // info 注意这个刷新时机
    always @(negedge clk) begin
        stall <= memReadE & ((rdE == rs1D) | (rdE == rs2D));
    end
    
endmodule
