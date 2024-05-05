`include "Define.v"
`include "LittleFunct.v"
`include "ALU.v"
`include "regFile.v"
`include "immGen.v"
`include "seg7x16.v"
`include "pcCtrl.v"
`include "forwardUnit.v"

module datapath (
    input clk, rstn, BTNC,
    // IF
    input [`INSTR_SIZE-1: 0] instrF,
    output [`INSTR_SIZE-1: 0] pcF,
    // MEM
    input [`XLEN-1: 0] readDataM,
    output [`DMEM_WIDTH-1: 0] adderM, // info mem adder
    output [`XLEN-1: 0] writeDataM,
    output [`SL_WIDTH-1: 0] lwhbM, swhbM, 
    output memWriteM,

    // from ctrl
    input [5: 0] extCtrlD,
    input itype, jalD, jalrD, bunisignedD, lunsignedD,
    input [`BRANCH_CTRL_WIDTH-1: 0] pcBranchSrcD,
    input [`ALU_CTRL_WIDTH-1: 0] aluCtrlD,
    input [1: 0] aluSrcAD, // info 用不到了。
    input aluSrcBD,
    input memWriteD,
    input [`SL_WIDTH-1: 0] lwhbD, swhbD,
    input memToRegD, regWriteD,

    // to ctrl
    output [6: 0] opD,
    output [2: 0] funct3D,
    output [6: 0] funct7D,
    output [11: 0] immD,
    output zeroD, ltD,

    // test show
    output reg [`XLEN-1: 0] reg_data,
    output [7: 0] disp_seg_o, disp_an_o,
    input [15: 0] sw_i,
    input CLK_SEG, CLK_TEST,
    input [`XLEN-1: 0] dm_data
    );

    // tag next PC logic
        // ID
    wire [`INSTR_SIZE-1: 0] nextPcF;

    wire stall; // info 处理 load 数据冒险
    hazard U_hazerd(
        clk, rstn,
        instrF[19: 15], instrF[24: 20], rdD, memToRegD,
        stall
    );

    // info branch 的 优先级 应该高于 jal，（当前为jal，而上一条为branch之时）
    pcenr pcFnext(
        clk, rstn, BTNC,
        ~stall, sw_i[1], 
        nextPcF, pcF
    );

    // tag pc 跳转的集中处理核心moudlu
    pcBranch U_pc_branch(
        // IF
        pcF, stall,
        // ID
        pcD, immOutD, rs1DataE,
        jalD, jalrE,
        // EX
        pcBranchSrcE, zeroE, bltE, bgeE,
        pcE, immOutE,
        // next pc
        nextPcF,
        // flush
        flushD, flushE
    );

    // mark IF/ID pipeline registers -------------------------------------
    wire [`INSTR_SIZE-1: 0] instrD;
    wire [`ADDR_SIZE-1: 0] pcD;
    wire flushD; // info 无条件跳转；但应该在这一后期 ID 执行完之时，才把下一轮传来的 pcF 处理掉。

    floprc #(`INSTR_SIZE) pr1D(clk, rstn, flushD, instrF, instrD); // instr
    floprc #(`ADDR_SIZE) pr2D(clk, rstn, flushD, pcF, pcD); // pc

    // Decode instr
    wire [`RFIDX_WIDTH-1: 0] rdD, rs1D,  rs2D;
    assign opD = instrD[6: 0];
    assign rdD = instrD[11: 7];
    assign funct3D = instrD[14: 12];
    assign rs1D = instrD[19: 15];
    assign rs2D = instrD[24: 20];
    assign funct7D = instrD[31: 25];

    // imm gen
    wire [`XLEN-1: 0] immOutD, shftimmD; // question
    immGen U_imm_gen(
        .clk(clk), 

        .iimm_shamt(rs2D), // info imm_shamt 和 rs2 的位置设计相同。
        .iimm(instrD[31: 20]),
        .simm({instrD[31: 25], instrD[11: 7]}),
        .bimm({instrD[31], instrD[7], instrD[30: 25], instrD[11: 8]}),
        .uimm(instrD[31: 12]),
        .jimm_jal({instrD[31], instrD[19: 12], instrD[20], instrD[30: 21]}),

        .extCtrl(extCtrlD),

        .immout(immOutD)
    );

    // register file
    wire [`XLEN-1: 0] rs1DataD, rs2DataD, writeDataW; 
    wire [`RFIDX_WIDTH-1: 0] writeAddrW; // info 后者是 WB 回传的数据

	// tag RF rf(clk, rs1D, rs2D, rdata1D, rdata2D, regwriteW, waddrW, wdataW, pcW);
    RF U_RF(
        .clk(clk),  .rst(rstn),
        .regWrite(regWriteW),

        .A3(writeAddrW),   // 写入寄存器号
        .wd(writeDataW),   // 写入的数值

        .A1(rs1D), .A2(rs2D),
        .dt1(rs1DataD), .dt2(rs2DataD),

        .n(sw_i[10: 6])
    );
    // test RF show
    parameter RF_ST = 5;
    parameter RF_END = 10;   // info 展示 x5 ~ RF_END-1
    reg [`RFIDX_WIDTH-1: 0] reg_addr;
    always @ (posedge CLK_TEST or negedge rstn) begin
        if(!rstn)
            reg_addr = RF_ST;
        else begin
            reg_data = {reg_addr, U_RF.rf[reg_addr][27: 0]};   // 序号前置
            // reg_data = {reg_addr, pcF[5: 2], U_RF.rf[reg_addr][27-4: 0]};   // info 查看 RF 写入的时机
            // reg_data = {U_RF.rf[reg_addr][31: 8], reg_addr[3: 0], U_RF.rf[reg_addr][3: 0]};   // mark 序号中间
            if(!sw_i[2])
                reg_addr = reg_addr + 1;
            if(reg_addr == RF_END)
                reg_addr = RF_ST;
            if(sw_i[4])
                reg_addr = 1;
        end 
    end

    wire JALD;
    assign JALD = jalD | jalrD; // info J指令，后续只是为了 RF 的写回，jal 和 jalr 效果一样。

    // mark ID / EX ----------------------------------------
    wire regWriteE, memWriteE, memToRegE, aluSrcBE, JALE, jalrE; // info 再次添加单独的 jalrE，因为数据冒险的关系。
    wire [`BRANCH_CTRL_WIDTH-1: 0] pcBranchSrcE;
    wire [`SL_WIDTH-1: 0] lwhbE, swhbE;
    wire [1: 0] aluSrcAE;
    wire [3: 0] aluCtrlE;   // todo
    wire flushE, zeroE, bltE, bgeE;
    // assign flushE = branchE; // info 

    floprc #(19) regE(clk, rstn, flushE, // info flush pop
        {regWriteD, memWriteD, memToRegD, aluSrcAD, aluSrcBD, aluCtrlD, JALD, jalrD, pcBranchSrcD, lwhbD, swhbD},
        {regWriteE, memWriteE, memToRegE, aluSrcAE, aluSrcBE, aluCtrlE, JALE, jalrE, pcBranchSrcE, lwhbE, swhbE});
    
    wire [`XLEN-1: 0] srcA1E, srcB1E, immOutE, srcAE, srcBE, aluOutE;
    wire [`XLEN-1: 0] rs1DataE, rs2DataE; // info rsXDataE 是处理了前递的正确的 rsX
    wire [`RFIDX_WIDTH-1: 0] rdE, rs1E, rs2E;
    wire [`ADDR_SIZE-1: 0] pcE; //, pcPlus4E;

    floprc #(`XLEN) pr1E(clk, rstn, flushE, rs1DataD, srcA1E);
    floprc #(`XLEN) pr2E(clk, rstn, flushE, rs2DataD, srcB1E);
    floprc #(`XLEN) pr3E(clk, rstn, flushE, immOutD, immOutE);
    floprc #(`RFIDX_WIDTH) pr5E(clk, rstn, flushE, rdD, rdE);
    floprc #(`RFIDX_WIDTH) pr6E(clk, rstn, flushE, rs1D, rs1E);
    floprc #(`RFIDX_WIDTH) pr7E(clk, rstn, flushE, rs2D, rs2E);
    floprc #(`ADDR_SIZE) pr8E(clk, rstn, flushE, pcD, pcE);

    // mark forward part
    wire [`FORWARD_WIDTH-1: 0] forward_a, forward_b;
    ForwardingUnit U_forward(
        rs1E, rs2E,
        rdM, rdW,
        regWriteM, regWriteW,

        forward_a, forward_b
    );


    // tag mux
    mux3 #(`XLEN) srcAmux(srcA1E, writeDataW, aluOutM, forward_a, srcAE);
    mux4 #(`XLEN) srcBmux(srcB1E, writeDataW, aluOutM, immOutE, {aluSrcBE, forward_b}, srcBE);

    // GET real rsX data for sw && jalr
    assign rs1DataE = srcAE;
    mux3 #(`XLEN) srcRS2mux(srcB1E, writeDataW, aluOutM, forward_b, rs2DataE);

    // tag ALU
    ALU U_ALU (
        .a(srcAE), .b(srcBE), 
        .aluCtrl(aluCtrlE),
        .aluout(aluOutE),

        .zero(zeroE), .lt(bltE), .ge(bgeE)
    );
    // test ALU SHOW
    reg [`XLEN-1: 0] alu_data;
    reg [2: 0] alu_addr;
    parameter ALU_NUM = 7;
    always @ (posedge CLK_TEST or negedge rstn) begin
        if(!rstn)
            alu_addr = 3'b0;
        else if(sw_i[12]) begin
            // re
            if(alu_addr == ALU_NUM)
                alu_addr = 3'b0;
            // normal
            case(alu_addr)
                3'h0: alu_data = {4'b0001, srcAE[27: 0]};
                3'h1: alu_data = {4'b0010, srcBE[27: 0]};
                3'h2: alu_data = {4'b0011, aluOutE[27: 0]};
                3'h3: alu_data = {4'b0100, {(`XLEN-4-1){1'b0}}, zeroE};
                // src alu B
                3'h4: alu_data = {4'h5, {(`XLEN-4-1){1'b0}}, aluSrcBE};
                3'h5: alu_data = {4'h6, srcB1E[27: 0]};
                3'h6: alu_data = {4'h7, immOutE[27: 0]};
                3'h7: alu_data = {4'h7, {(`XLEN-4-4){1'b0}}, aluCtrlE};
                default: 
                    alu_data = 32'hFFFFFFFF;
            endcase
            alu_addr = alu_addr + 1'b1;
        end
    end

    // mark EX / MEM ------------------------------
    wire regWriteM, memToRegM, JALM;
    wire flushM = 0;
    wire [`XLEN-1: 0] aluOutM;
    floprc #(8) regM(clk, rstn, flushM,
        {regWriteE, memWriteE, memToRegE, JALE, lwhbE, swhbE},
        {regWriteM, memWriteM, memToRegM, JALM, lwhbM, swhbM});

    // data
    wire [`ADDR_SIZE-1: 0] pcM, pcPlus4M;
    wire [`RFIDX_WIDTH-1: 0] rdM;
    floprc #(`XLEN) pr1M(clk, rstn, flushE, aluOutE, aluOutM);
    floprc #(`RFIDX_WIDTH) pr2M(clk, rstn, flushE, rdE, rdM);
    floprc #(`INSTR_SIZE) pr3M(clk, rstn, flushE, pcE, pcM);

    // info 记录 rs2，用于 sw 写入 MEM。// info 处理 load 冒险, 
    floprc #(`XLEN) pr4M(clk, rstn, flushE, rs2DataE, writeDataM);
    assign adderM = aluOutM[`DMEM_WIDTH-1: 0]; // info writeDataM 用于 Mem，writeDataW 用于 RF
    

    // mark MEM / WB ------------------------------------
    wire regWriteW, memToRegW, JALW;
    wire flushW = 0;
    floprc #(3) regW(clk, rstn, flushW, {regWriteM, memToRegM, JALM}, {regWriteW, memToRegW, JALW});

    // data
    wire [`XLEN-1: 0] aluOutW, readDataW;
    wire [`ADDR_SIZE-1: 0] pcW;
    wire [`RFIDX_WIDTH-1: 0] rdW;

    floprc #(`XLEN) pr1W(clk, rstn, flushW, aluOutM, aluOutW);
    floprc #(`XLEN) pr2W(clk, rstn, flushW, readDataM, readDataW);
    floprc #(`RFIDX_WIDTH) pr3W(clk, rstn, flushW, rdM, rdW);
    floprc #(`ADDR_SIZE) pr4W(clk, rstn, flushW, pcM, pcW);

    // write back
    assign writeDataW = memToRegW ? readDataW : JALW ? (pcW + 4) : aluOutW;  // info 不用一直传递 32位 pcPlus4 的版本
    assign writeAddrW = rdW;

    // mark test show seg7x16
    reg [`XLEN-1: 0] display_data;
    always@(sw_i) begin
      case(sw_i[14: 11])
        4'b1000: display_data = { pcF[7: 0], instrF[23: 0]};
        4'b0100: display_data = reg_data;
        4'b0010: display_data = alu_data;
        4'b0001: display_data = dm_data;
        default:
            display_data = {pcF[9: 2], nextPcF[9: 2], pcD[9: 2], pcE[9: 2]};
        endcase
    end

    // test for show
    seg7x16 u_seg7x16(
        .clk(CLK_SEG),
        .rstn(rstn),
        .i_data(display_data),
        
        .o_seg(disp_seg_o),
        .o_sel(disp_an_o)
    );

endmodule