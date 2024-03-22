module test_2(clk, rstn, sw_i, disp_seg_o, disp_an_o);
    input clk;
    input rstn;
    input [15:0] sw_i;
    output [7:0] disp_seg_o, disp_an_o;
    
    reg [31:0] clk_div;
    wire Clk_CPU;

// CLK 分频
always @ (posedge clk or negedge rstn)
    begin
        if(!rstn)
            clk_div <= 0;
        else
            clk_div <= clk_div + 1'b1;
    end
assign Clk_CPU = (sw_i[15]) ? clk_div[28] : clk_div[25];

reg [63:0] display_data;
reg [5:0] led_data_addr;
reg [63:0] led_disp_data;

// SHOW - LED_DATA
parameter LED_DATA_NUM = 48;
reg [63:0] LED_DATA[47:0];
initial 
    begin
        LED_DATA[0] = 64'hFFFFFFFEFEFEFEFE;
        LED_DATA[1] = 64'hFFFEFEFEFEFEFFFF;
        LED_DATA[2] = 64'hDEFEFEFEFFFFFFFF;
        LED_DATA[3] = 64'hCEFEFEFFFFFFFFFF;
        LED_DATA[4] = 64'hC2FFFFFFFFFFFFFF;
        LED_DATA[5] = 64'hC1FEFFFFFFFFFFFF;
        LED_DATA[6] = 64'hF1FCFFFFFFFFFFFF;
        LED_DATA[7] = 64'hFDF8F7FFFFFFFFFF;
        LED_DATA[8] = 64'hFFF8F3FFFFFFFFFF;
        LED_DATA[9] = 64'hFFFBF1FEFFFFFFFF;
        LED_DATA[10] = 64'hFFFFF9F8FFFFFFFF;
        LED_DATA[11] = 64'hFFFFFDF8F7FFFFFF;
        LED_DATA[12] = 64'hFFFFFFF9F1FFFFFF;
        LED_DATA[13] = 64'hFFFFFFFFF1FCFFFF;
        LED_DATA[14] = 64'hFFFFFFFFF9F8FFFF;
        LED_DATA[15] = 64'hFFFFFFFFFFF8F3FF;
        LED_DATA[16] = 64'hFFFFFFFFFFFBF1FE;
        LED_DATA[17] = 64'hFFFFFFFFFFFFF9BC;
        LED_DATA[18] = 64'hFFFFFFFFFFFFBDBC;
        LED_DATA[19] = 64'hFFFFFFFFBFBFBFBC;
        LED_DATA[20] = 64'hFFFFBFBFBFBFBFFF;
        LED_DATA[21] = 64'hFFBFBFBFBFBFFFFF;
        LED_DATA[22] = 64'hAFBFBFBFFFFFFFFF;
        LED_DATA[23] = 64'h2737FFFFFFFFFFFF;
        LED_DATA[24] = 64'h277777FFFFFFFFFF;
        LED_DATA[25] = 64'h7777777777FFFFFF;
        LED_DATA[26] = 64'hFFFF7777777777FF;
        LED_DATA[27] = 64'hFFFFFF7777777777;
        LED_DATA[28] = 64'hFFFFFFFFFF777771;
        LED_DATA[29] = 64'hFFFFFFFFFFFF7770;
        LED_DATA[30] = 64'hFFFFFFFFFFFFFFC8;
        LED_DATA[31] = 64'hFFFFFFFFFFFFE7CE;
        LED_DATA[32] = 64'hFFFFFFFFFFFFC7CF;
        LED_DATA[33] = 64'hFFFFFFFFFFDEC7FF;
        LED_DATA[34] = 64'hFFFFFFFFF7CEDFFF;
        LED_DATA[35] = 64'hFFFFFFFFC7CFFFFF;
        LED_DATA[36] = 64'hFFFFFFFEC7EFFFFF;
        LED_DATA[37] = 64'hFFFFFFCECFFFFFFF;
        LED_DATA[38] = 64'hFFFFDECEFFFFFFFF;
        LED_DATA[39] = 64'hFFFFC7CFFFFFFFFF;
        LED_DATA[40] = 64'hFFDEC7FFFFFFFFFF;
        LED_DATA[41] = 64'hF7CEDFFFFFFFFFFF;
        LED_DATA[42] = 64'hA7CFFFFFFFFFFFFF;
        LED_DATA[43] = 64'hA7AFFFFFFFFFFFFF;
        LED_DATA[44] = 64'hAFBFBFBFFFFFFFFF;
        LED_DATA[45] = 64'hBFBFBFBFBFFFFFFF;
        LED_DATA[46] = 64'hFFFFBFBFBFBFBFFF;
        LED_DATA[47] = 64'hFFFFFFFFBFBFBFBD;
    end
always @ (posedge Clk_CPU or negedge rstn)
    if(!rstn)
        begin
            led_data_addr = 6'd0;
            led_disp_data = 64'b1;
        end
    else
        if(sw_i[0] == 1'b1)
            begin
                if (led_data_addr == LED_DATA_NUM)  // 重置
                    begin
                        led_data_addr = 6'd0;
                        led_disp_data = 64'b1;
                    end
                led_disp_data = LED_DATA[led_data_addr];
                led_data_addr = led_data_addr + 1'b1;
            end
        else
            led_data_addr = led_data_addr;

// ROM 实例化
wire [31:0] instr;
parameter IM_CODE_NUM = 12;
reg [3:0] rom_addr;

dist_mem_gen_0 U_IM(
    .a(rom_addr),
    .spo(instr)
);

// rom-addr 遍历 相当于 PC += 4
always @ (posedge Clk_CPU or negedge rstn) begin
    if(!rstn)
        rom_addr = 4'b0;
    else
        if(sw_i[1] == 1'b0)     // 模拟PC默认自增
            begin
                if(rom_addr == IM_CODE_NUM) //暂时强制只跑一遍
                    rom_addr = 4'b0;
                else
                    rom_addr = rom_addr + 1'b1;
            end
        else
            rom_addr = rom_addr;
end

// Instr 拆分
wire [6: 0] Op = instr[6: 0];
wire [2: 0] Funct3 = instr[14: 12];
wire [6: 0] Funct7 = instr[31: 25];

// registers
wire [4: 0] rd = instr[11: 7];
wire [4: 0] rs1 = instr[19: 15];
wire [4: 0] rs2 = instr[24: 20];

// Ctrl - sign
wire RegWrite, MemWrite, ALUSrc;
wire [1: 0] WDSrc;
wire [4: 0] ALUOp;
wire [5: 0] EXTOp;  // 暂时还不是特别理解 -> 不同的立即数扩展方式
wire [2: 0] DMType;

// RF 实例化
wire [31: 0] RD1, RD2;
reg [31: 0] WD;   // 用于 Wire - RF
wire [31: 0] B;

RF U_RF(
    .clk(Clk_CPU),  .rst(rstn),
    .RFWr(RegWrite),

    .A3(rd),   // 写入寄存器号
    .WD(WD),    // 写入的数值

    .A1(rs1), .A2(rs2),
    .RD1(RD1), .RD2(RD2)
);

// SHOW - 每次拿出来一位 RF
parameter RF_NUM = 8;
reg [31:0] reg_data; // RD1, RD2;
reg [5:0] reg_addr;
always @ (posedge Clk_CPU or negedge rstn) begin
    if(!rstn)
        reg_addr = 5'b0;
    // 这里只做显示用，之于指令的执行意义不大。
    else if(sw_i[13] == 1'b1) begin
        if(reg_addr == RF_NUM)
            reg_addr = 5'b0;
        reg_data = {reg_addr, U_RF.rf[reg_addr][27: 0]};   // 不知道是不是折合位数的时候出现问题
        reg_addr = reg_addr + 1'b1;
    end
    else
        reg_addr = reg_addr;
end

// ALU 实例化
wire Zero; 
wire [31: 0] alu_out;

alu U_alu(.A(RD1), .B(B), .ALUOp(ALUOp),
    .Zero(Zero), .C(alu_out)
);

// SHOW - 也只是展示用，实际计算无用
reg [31: 0] alu_data;
reg [2: 0] alu_addr;
parameter ALU_NUM = 4;
always @ (posedge Clk_CPU or negedge rstn) begin
    if(!rstn)
        alu_addr = 3'b0;
    else if(sw_i[12]) begin
        // re
        if(alu_addr == ALU_NUM)
            alu_addr = 3'b0;
        // normal
        case(alu_addr)
            3'b000: alu_data = RD1;
            3'b001: alu_data = B;
            3'b010: alu_data = alu_out;
            3'b011: alu_data = Zero;
            default: 
                alu_data = 32'hFFFFFFFF;
        endcase
        alu_addr = alu_addr + 1'b1;
    end
end

// imm 实例化
wire [31: 0] immout;
// 目前只对应部分的指令
EXT U_EXT(
    .clk(Clk_CPU), 
    .iimm_shamt(rs2),
    .iimm(instr[31: 20]),
    .simm({instr[31: 25], instr[11: 7]}),
    .bimm({instr[31], sw_i[7], instr[30: 25], instr[11: 8]}),
    .EXTOp(EXTOp),

    .immout(immout)
);

// DM 模块
reg [2: 0] DMTy;
wire [31: 0] din, dout;
// dout 的作用？

DM U_DM (
    .clk(Clk_CPU),  .rst(rstn),
    .DMWr(MemWrite), .sw_1(sw_i[1]),
    .addr(alu_out[5: 0]), .din(RD2),

    .DMType(DMTy), .dout(dout)
);

// alu - mux    只有rs2需要多选
assign B = (ALUSrc) ? immout : RD2;

// RF - mux
`define WDSel_FromALU 2'b00
`define WDSel_FromMEM 2'b01
`define WDSel_FromPC 2'b10

always @ (*) begin
    case(WDSrc)
        `WDSel_FromALU: WD <= alu_out;
		`WDSel_FromMEM: WD <= dout;
		//`WDSel_FromPC: WD<=PC_out+4;
    endcase
end

// ALU - 扩w展 - ORI
// always @ (*) begin
//     // read or write
//     // if(sw_i[2] == 1) begin  // 有一定作用
//     //     // A = {{28{sw_i[10]}}, sw_i[10: 7]};
//     //     B = {{29{sw_i[7]}}, sw_i[7: 5]};
//     // end
//     begin  // 读取
//         A = RD1;
//         B = RD2;
//     end
// end

// Ctrl 实例化
Ctrl U_Ctrl (
    .Op(Op), .Funct7(Funct7), .Funct3(Funct3), .Zero(Zero), 

    .RegWrite(RegWrite), .MemWrite(MemWrite),
    .EXTOp(EXTOp), .ALUOp(ALUOp),
    .ALUSrc(ALUSrc), .WDSrc(WDSrc), .DMType(DMType)
);

// SHOW - DM 数据展示
reg [3: 0] dm_addr;
reg [31: 0] dm_data;
parameter DM_DATA_SHOW = 8;
always @ (posedge Clk_CPU or negedge rstn) begin
    if(!rstn)
        dm_addr = 5'b0;
    else if(sw_i[11]) begin
        if(dm_addr == DM_DATA_SHOW)
            dm_addr = 5'b0;
        dm_data = {dm_addr, 4'b000, U_DM.dmem[dm_addr]};
        dm_addr = dm_addr + 1'b1;
    end
end

// seg7x16 - display 显示LED使用
seg7x16 u_seg7x16(
    .clk(clk),
    .rstn(rstn),
    .i_data(display_data),
    .disp_mode(sw_i[0]),
    .o_seg(disp_seg_o),
    .o_sel(disp_an_o)
);



// SHOW - TEST
wire clk_test;
assign clk_test = clk_div[25];reg [31: 0] test_data;
reg [4: 0] test_addr;
parameter TEST_NUM = 9;
// always @(posedge Clk_CPU) begin // 没法并行处理，会出 BUG。
//     test_addr = 1'b0;
// end
always @ (posedge clk_test or negedge rstn) begin
    if(!rstn)
        test_addr = 3'b0;
    else if(sw_i[14]) begin
        // re
        if(test_addr == TEST_NUM)
            test_addr = 5'b0;
        // normal
        case(test_addr)
            5'b00000: test_data = {(rom_addr + 1'b1), 4'b0000, 19'b0001000000000000000, RegWrite};
            5'b00001: test_data = {(rom_addr + 1'b1), 4'b0000, 16'b0010000000000000, rs1[3: 0]};
            5'b00010: test_data = {(rom_addr + 1'b1), 4'b0000, 16'b0011000000000000, rd[3: 0]};
            5'b00011: test_data = {(rom_addr + 1'b1), 4'b0000, 14'b01000000000000, 2'b00, WDSrc};
            5'b00100: test_data = {(rom_addr + 1'b1), 4'b0000, 4'b0101, immout[19: 0]};
            5'b00101: test_data = {{rom_addr + 1'b1}, 4'b0110, 3'b000, ALUOp};
            5'b00110: test_data = {{rom_addr + 1'b1}, 4'b0111, 2'b00, EXTOp};
            5'b00111: test_data = {{rom_addr + 1'b1}, 4'b0000, 4'b1000, dout[19: 0]};
            default: 
                test_data = 32'hFFFFFFFF;
        endcase
        test_addr = test_addr + 1'b1;
    end
end

always @ (sw_i)
    if(sw_i[0] == 0)
        begin
            case(sw_i[14:11])
                4'b1000: display_data = test_data;
                4'b0100: display_data = reg_data;
                4'b0010: display_data = alu_data;
                4'b0001: display_data = dm_data;
                default:
                    display_data = instr;
            endcase
        end
    else
        begin
            display_data = led_disp_data;
        end
endmodule        