`include "Define.v"
`include "ALU.v"
`include "Ctrl.v"
`include "EXT.v"
`include "Mem.v"
`include "RF.v"
`include "seg7x16.v"
`include "LittleFunct.v"

`define SW_NUM 16
`define CLK_WIDTH 32

module main(
    input clk, rstn, 
    input [`SW_NUM-1: 0] sw_i, 
    
    output [7: 0] disp_seg_o, disp_an_o
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
    assign CLK_CPU = (sw_i[15]) ? clk_div[28] : clk_div[25];

    // tag ROM 实例化
    wire [`XLEN-1: 0] instr;
    reg [`INSTR_WIDTH-1: 0] romAddr;
    dist_mem_gen_0 U_IM(
        .a(romAddr),
        .spo(instr)
    );

    // test rom-addr 遍历 相当于 PC += 4
    always @ (posedge CLK_CPU or negedge rstn) begin
        if(!rstn)
            romAddr = 4'b0;
        else
            if(sw_i[1] == 1'b0) begin      // info 模拟PC默认自增
                if(romAddr == `INSTR_NUM)  // info 暂时强制只跑一遍
                    romAddr = 4'b0;
                else
                    romAddr = romAddr + 1'b1;
            end else
                romAddr = romAddr;
    end

    // tag Instr 拆分
    wire [6: 0] opcode = instr[6: 0];
    wire [2: 0] funct3 = instr[14: 12];
    wire [6: 0] funct7 = instr[31: 25];

    // registers
    wire [4: 0] rd = instr[11: 7];
    wire [4: 0] rs1 = instr[19: 15];
    wire [4: 0] rs2 = instr[24: 20];

    // tag Ctrl - wire !!!!
    wire regWrite, memWrite;
    wire [3: 0] aluCtrl;
    wire [6: 0] extCtrl;
    wire [1: 0] lwhb, swhb;

    wire [1: 0] rfSrc_wd;
    wire aluSrc_b;

    wire zero;

    // tag Ctrl 实例化
    Ctrl U_Ctrl (
        .opcode(opcode), .funct7(funct7), .funct3(funct3), 

        .regWrite(regWrite), .memWrite(memWrite),
        .extCtrl(extCtrl), .aluCtrl(aluCtrl),

        .lwhb(lwhb), .swhb(swhb),
        .aluSrc_b(aluSrc_b), .rfSrc_wd(rfSrc_wd),
        // .ALUSrc(ALUSrc), .WDSrc(WDSrc), .DMType(DMType),

        .zero(zero)
    );

    // tag imm 实例化
    wire [`XLEN-1: 0] imm_out;
    // 目前只对应部分的指令 -> 目前对应大部分常用指令
    EXT U_EXT(
        .clk(CLK_CPU), 

        .iimm_shamt(rs2), // info imm_shamt 和 rs2 的位置设计相同。
        .iimm(instr[31: 20]),
        .simm({instr[31: 25], instr[11: 7]}),
        .bimm({instr[31], instr[7], instr[30: 25], instr[11: 8]}),
        .uimm(instr[31: 12]),
        .jimm_jal({instr[31], instr[19: 12], instr[20], instr[30: 21]}),

        .extCtrl(extCtrl),

        .immout(imm_out)
    );

    // tag RF 实例化
    wire [`XLEN-1: 0] dt1, dt2;
    wire [`XLEN-1: 0] b; // info ALU 选中的 dt2，
    wire [`XLEN-1: 0] wd;   // 用于 Wire - RF   // update 因为用 mux3-output, 那么无法用 reg 存储。
    RF U_RF(
        .clk(CLK_CPU),  .rst(rstn),
        .regWrite(regWrite),

        .A3(rd),   // 写入寄存器号
        .wd(wd),   // 写入的数值

        .A1(rs1), .A2(rs2),
        .dt1(dt1), .dt2(dt2)
    );

    // RF - MUX    // info coe 架构上，只需要 romAddr + 1。
    mux3 #(`XLEN) rfMux (.d0(alu_out), .d1(dm_out), .d2(romAddr+1), .src(rfSrc_wd), .out(wd));

    // test SHOW - 每次拿出来一位 RF
    parameter RF_ST = 5;
    parameter RF_END = 8;   // info 展示 x5 ~ x8
    reg [`XLEN-1: 0] reg_data; // dt1, dt2;
    reg [`RFIDX_WIDTH-1: 0] reg_addr;
    always @ (posedge CLK_CPU or negedge rstn) begin
        if(!rstn)
            reg_addr = RF_ST;
        else if(sw_i[13] == 1'b1) begin // 这里只做显示用，之于指令的执行意义不大。
            reg_data = {reg_addr, U_RF.rf[reg_addr][27: 0]};   // 不知道是不是折合位数的时候出现问题
            reg_addr = reg_addr + 1;
            if(reg_addr == RF_END)
                reg_addr = RF_ST;
        end else
            reg_addr = reg_addr;
    end

    // tag ALU 实例化
    wire [`XLEN-1: 0] alu_out;
    ALU U_ALU (
        .a(dt1), .b(b), 
        .aluCtrl(aluCtrl),
        .aluout(alu_out),

        .zero(zero)
    );

        // ALU - MUX
    mux2 #(`XLEN) aluMux (.d0(dt2), .d1(imm_out), .src(aluSrc_b), .out(b));

    // test SHOW - 也只是展示用，实际计算无用
    reg [`XLEN-1: 0] alu_data;
    reg [2: 0] alu_addr;
    parameter ALU_NUM = 4;
    always @ (posedge CLK_CPU or negedge rstn) begin
        if(!rstn)
            alu_addr = 3'b0;
        else if(sw_i[12]) begin
            // re
            if(alu_addr == ALU_NUM)
                alu_addr = 3'b0;
            // normal
            case(alu_addr)
                3'b000: alu_data = {4'b0001, dt1[27: 0]};
                3'b001: alu_data = {4'b0010, b[27: 0]};
                3'b010: alu_data = {4'b0011, alu_out[27: 0]};
                3'b011: alu_data = {4'b0100, {(`XLEN-4-1){1'b0}}, zero};
                default: 
                    alu_data = 32'hFFFFFFFF;
            endcase
            alu_addr = alu_addr + 1'b1;
        end
    end

    // tag DM 模块
    // reg [2: 0] DMTy;
    wire [`XLEN-1: 0] dm_in, dm_out;    // info 注意 多选器的配合。
    DM U_DM (
        .clk(CLK_CPU),  .rst(rstn),

        .memWrite(memWrite),            // test .sw_1(sw_i[1]),
        .addr(alu_out), .wd(dm_in),
        .lwhb(lwhb), .swhb(swhb),
        
        .dt(dm_out)
    );

    // test SHOW - DM 数据展示
    reg [3: 0] dm_addr;
    reg [`XLEN-1: 0] dm_data;
    parameter DM_DATA_SHOW = 8;
    always @ (posedge CLK_CPU or negedge rstn) begin
        if(!rstn)
            dm_addr = 5'b0;
        else if(sw_i[11]) begin
            if(dm_addr == DM_DATA_SHOW)
                dm_addr = 5'b0;
            dm_data = {dm_addr, {(`XLEN-4-8){1'b0}}, U_DM.dmem[dm_addr]};
            dm_addr = dm_addr + 1'b1;
        end
    end

    // tag TEST - SHOW // todo wait update
    wire clk_test;
    assign clk_test = clk_div[25];
    reg [`XLEN-1: 0] test_data;

    `define TEST_NUM 8
    reg [2: 0] test_addr;
    parameter TEST_NUM = 7;
    always@(posedge clk_test or negedge rstn) begin
        if(!rstn)
            test_addr = 3'b0;
        else if(sw_i[14]) begin                
            // re
            if(test_addr == TEST_NUM)
                test_addr = 5'b0;
            // normal
            case(test_addr)
                `TEST_NUM'b00000: test_data = {(romAddr + 1'b1), 4'h1, {(`XLEN-8-1){1'b0}}, regWrite};
                `TEST_NUM'b00001: test_data = {(romAddr + 1'b1), 4'h2, {(`XLEN-8-4){1'b0}}, rs1[3: 0]};
                `TEST_NUM'b00010: test_data = {(romAddr + 1'b1), 4'h3, {(`XLEN-8-4){1'b0}}, rd[3: 0]};
                `TEST_NUM'b00011: test_data = {(romAddr + 1'b1), 4'h4, {(`XLEN-8-2){1'b0}}, rfSrc_wd};
                // 5.
                `TEST_NUM'b00100: test_data = {(romAddr + 1'b1), 4'h5, imm_out[23: 0]};
                `TEST_NUM'b00101: test_data = {{romAddr + 1'b1}, 4'h6, {(`XLEN-8-4){1'b0}}, aluCtrl};
                `TEST_NUM'b00110: test_data = {{romAddr + 1'b1}, 4'h7, alu_out[23: 0]};
                `TEST_NUM'b00111: test_data = {{romAddr + 1'b1}, 4'h8, 4'b0000, 4'b1000, dm_out[19: 0]};
                default: 
                    test_data = 32'hFFFFFFFF;
            endcase

            if(!sw_i[2])    // test 置 1 时手动断点。
                test_addr = test_addr + 1'b1; 
            else
                test_addr = test_addr;
        end
    end

    // tag switch - ctrl

    reg [`XLEN-1: 0] display_data;

    always@(sw_i) begin
      case(sw_i[14:11])
        4'b1000: display_data = test_data;
        4'b0100: display_data = reg_data;
        4'b0010: display_data = alu_data;
        4'b0001: display_data = dm_data;
        default:
            display_data = instr;
    endcase
    end

    // tag seg7x16 - display 显示LED使用
    seg7x16 u_seg7x16(
        .clk(clk),
        .rstn(rstn),
        .i_data(display_data),
        .disp_mode(sw_i[0]),
        .o_seg(disp_seg_o),
        .o_sel(disp_an_o)
    );
endmodule        