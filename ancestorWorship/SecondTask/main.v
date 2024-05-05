`include "Define.v"
`include "dataMem.v"
`include "seg7x16.v"
`include "LittleFunct.v"
`include "dataPath.v"
`include "pcCtrl.v"

`define SW_NUM 16
`define CLK_WIDTH 32

module main(
    input clk, rstn, BTNC, // info 设计单步调试的概念。
    input [`SW_NUM-1: 0] sw_i,

    output [7: 0] disp_seg_o, disp_an_o // 传输转化之后的 7段码 到 FPGA 上。
    );

    // tag CLK 分频
    reg [`CLK_WIDTH-1: 0] clk_div;
    wire CLK_CPU;
    always @ (posedge clk or negedge rstn) begin
        if(!rstn)
            clk_div <= 0;
        else
            clk_div <= clk_div + 1'b1;
    end
    assign CLK_CPU = (sw_i[15]) ? clk_div[26] : clk_div[22];    // info 加个速
    assign CLK_TEST = clk_div[25]; // info 用于检查状态。

    // tag ROM - instr memory
    wire [`XLEN-1: 0] pcF;
    wire [`INSTR_SIZE-1: 0] instr;
    wire [5: 0] romAddr;
    // reg [5: 0] romAddr;

    // info 将 pc 处理为 romaddr， 然后再调用 IP核
    pcHandleForIP #(`XLEN, 6) pcToIP(pcF, romAddr); // test
    dist_mem_gen_0 U_IM(
        .a(romAddr),
        .spo(instr)
    );

    // tag data memory
    wire memWrite;
    wire [`SL_WIDTH-1: 0] lwhb, swhb;
    wire [`XLEN-1: 0] writeData, readData;
    wire [`DMEM_WIDTH-1: 0] addr;

    DM U_DM(CLK_CPU, rstn, memWrite, lwhb, swhb, addr, writeData, readData);
    // test DM show
    reg [9: 0] dm_addr = 10'h3f8;
    reg [`XLEN-1: 0] dm_data;
    parameter DM_DATA_SHOW = 1000;
    always @ (posedge CLK_TEST or negedge rstn) begin
        if(!rstn)
            dm_addr = 10'h3f8;
        else begin
            dm_data = {dm_addr[7: 0], {(`XLEN-20-6){1'b0}}, romAddr, 4'h0, U_DM.dmem[dm_addr]};
        end
    end

    // tag riscV
    wire [31: 0] reg_data;
    havRiscV U_risc(
        CLK_CPU, rstn, BTNC,
        instr, readData,
        // output
        pcF, memWrite, lwhb, swhb, addr, writeData, 
        // test
        reg_data, disp_seg_o, disp_an_o, sw_i, clk, CLK_TEST, dm_data
    );// info 此时 最快的 clk 用于 seg7x16 的显示，后续命名为 CLK_SEG。

endmodule

module havRiscV (
    input clk, rstn, BTNC,
    input [`INSTR_SIZE-1: 0] instr,
    input [`XLEN-1: 0] readData,

    output [`XLEN-1: 0] pcF,
    // ctrl sign
    output memWrite,
    output [`SL_WIDTH-1: 0] lwhb, swhb,
    output [`DMEM_WIDTH-1: 0] dmAddr,
    output [`XLEN-1: 0] writeData,

    // info for test
    output [`XLEN-1: 0] rfData,
    output [7: 0] disp_seg_o, disp_an_o,
    input [15: 0] sw_i,
    input CLK_SEG, CLK_TEST,
    input [`XLEN-1: 0] dm_data
    );

    wire [6: 0] opcodeD;
    wire [2: 0] funct3D;
    wire [6: 0] funct7D;
    wire [11: 0] immD;
    // wire zeroD, ltD;
    wire [5: 0] immCtrlD;
    wire itypeD, jalD, jalrD;
    wire [`BRANCH_CTRL_WIDTH-1: 0] pcsrcD; // info 用于处理 Btype 的指令。
    wire [3: 0] aluCtrlD;
    wire aluSrcAD, aluSrcBD;
    // wire lunsignedD, bunsignedD;
    wire [1: 0] swhbD, lwhbD;
    wire memToRegD, regWriteD, memWriteD;

    Ctrl controll(
        .opcode(opcodeD), .funct7(funct7D), .funct3(funct3D), 

        .regWrite(regWriteD), .memWrite(memWriteD), .memToReg(memToRegD),
        .extCtrl(immCtrlD), .aluCtrl(aluCtrlD),

        .lwhb(lwhbD), .swhb(swhbD),
        .aluSrc_b(aluSrcBD), 
        
        .pcBranchSrc(pcsrcD),

        .Jal(jalD), .Jalr(jalrD)  // info 大写 J，做 Ctrl.v 内部区分
    );

    datapath dp(
        clk, rstn, BTNC,
        // IF
        instr, pcF,
        // MEM
        readData, dmAddr, writeData, lwhb, swhb, memWrite,
        // info from ctrl
        immCtrlD, itypeD, jalD, jalrD, bunsignedD, lunsignedD,
            // Src
        pcsrcD, aluCtrlD, aluSrcAD, aluSrcBD,
        memWriteD, lwhbD, swhbD, 
        memToRegD, regWriteD,
        // to Ctrl
        opcodeD, funct3D, funct7D, immD, zeroD, ltD,
        // test for show
        rfData, disp_seg_o, disp_an_o, sw_i, CLK_SEG, CLK_TEST, dm_data
    );
    
endmodule