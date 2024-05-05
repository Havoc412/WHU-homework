`include "Define.v"
`include "LittleFunct.v"
`include "ALU.v"
`include "regFile.v"

module datapath(
    input clk, rstn,
    
    input [`INSTR_SIZE-1: 0] instrF,
    output [`INSTR_WIDTH-1: 0] pcF,

    input [`XLEN-1: 0] readDateM,
    output [`XLEN-1: 0]  aluoutM,
    output [`XLEN-1: 0] writeDataM,
    output memWriteM,
    output [`INSTR_WIDTH-1: 0] pcM,

    output [`INSTR_WIDTH-1: 0] pcW,

    // from ctrl
    input [4: 0] immCtrlD,
    input itype, jalD, jalrD, bunisignedD, pcSrcD,
    input [3: 0] aluCtrlD,
    input [1: 0] aluSrcAD,
    input aluSrcBD,
    input memWriteD, lunsignedD,
    input [1: 0] lwhbD, swhbD,
    input memToRegD, regWriteD,

    // to ctrl
    output [6: 0] opD,
    output [2: 0] funct3D,
    output [6: 0] funct7D,
    output [4: 0] rdD, rs1D,
    output [11: 0] immD,
    output  zeroD, ltD  
    );

    // tag next PC logic
    wire [`INSTR_WIDTH-1: 0] pcplus4D, nextPcF, pcBranchD, pcAdder2aD, pcAdder2bD, pcBranch0D;
    // question pcBranch0D 是来干什么的，tag 0 ?
    mux2 #(`INSTR_WIDTH) pcSrcMux(pcplus4D, pcBranchD, pcSrcD, nextPcF);

    // Fetch stage logic
    

    // tag IF/ID pipeline registers ----------------------------------------------
    wire [`INSTR_SIZE-1: 0] instrD;
    wire [`INSTR_WIDTH-1: 0] pcD, pcPlus4D;
    wire flushD = 0; // todo... 数据冒险需要处理的问题

    floprc #(`INSTR_SIZE) pr1D(clk, rstn, flushD, instrF, instrD); // question
    floprc #(`INSTR_SIZE) pr2D(clk, rstn, flushD, instrF, instrD); // question
    floprc #(`INSTR_SIZE) pr3D(clk, rstn, flushD, instrF, instrD); // question

    // Decode stage logic

endmodule