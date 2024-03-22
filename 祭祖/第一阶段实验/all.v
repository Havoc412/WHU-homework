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
reg [2: 0] DMType;
wire [31: 0] din, dout;
// dout 的作用？

DM U_DM (
    .clk(Clk_CPU),  .rst(rstn),
    .DMWr(MemWrite), .sw_1(sw_i[1]),
    .addr(alu_out[5: 0]), .din(RD2),

    .DMType(DMType), .dout(dout)
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

module RF(
    input clk,
    input rst,
    input RFWr,
    input [4:0] A1, A2, A3,
    input [31:0] WD,

    output [31:0] RD1, RD2
);

reg [31:0] rf [31:0];
integer i;
always @ (negedge clk or negedge rst) begin
    if(!rst) begin
        for(i=0; i<32; i = i+1)
            rf[i] = 32'b0;
    end
    else
    // 写信号 && 排除0号寄存器
    if(RFWr && A3 != 0) begin
        rf[A3] <= WD;
    end
end

// // Reset
// always @ (negedge rst) begin
//     if(!rst) begin
//         for(i=0; i<32; i = i+1)
//             rf[i] = 32'b0;
//     end
// end

 assign RD1 = (A1 != 0) ? rf[A1] : 0;
 assign RD2 = (A2 != 0) ? rf[A2] : 0;

endmodule

module DM(
    input clk, input rst,

    input DMWr, input sw_1,

    input [5: 0] addr,
    input [31: 0] din,

    input [2: 0] DMType,
    output [31: 0] dout
);
// sw_1 目前我想的定义是 调式信号； 这个 reg 可能会有问题

reg [7: 0] dmem [127: 0];
parameter DM_length = 128;

// tips: define - used for test 
// `define dm_word 2'b00
// `define dm_halfword 2'b01
// // `define dm_halfword_unsigned 3'b010
// `define dm_byte 2'b11
// // `define dm_byte_unsigned 3'b100

// formal 
`define dm_word 3'b000
`define dm_halfword 3'b001
`define dm_halfword_unsigned 3'b010
`define dm_byte 3'b011
`define dm_byte_unsigned 3'b100

// 这里处理写入
integer i;
always @ (negedge clk or negedge rst) begin
    if(!rst)
        for(i=0; i<128; i = i+1)
            dmem[i] = 8'b0;
    else
    if(DMWr && !sw_1) begin
        case(DMType)
            `dm_byte: dmem[addr] <= din[7: 0];
            `dm_halfword: begin
                dmem[addr] <= din[7: 0];
                dmem[addr+1] <= din[15: 8];
            end
            `dm_word: begin
                dmem[addr] <= din[7: 0];
                dmem[addr+1] <= din[15: 8];
                dmem[addr+2] <= din[23: 16];
                dmem[addr+3] <= din[31: 24];
            end
        endcase
    end
end

// Reset
// integer i;
// always @ (negedge rst) begin
//     if(!rst)
//         for(i=0; i<128; i = i+1)
//             dmem[i] = 8'b0;
// end

// 配合 load ？ 适用于 单周期
assign dout = {dmem[addr+3], dmem[addr+2], dmem[addr+1], dmem[addr]};

endmodule

module Ctrl(
    input [6: 0] Op,
    input [6: 0] Funct7,
    input [2: 0] Funct3,
    input Zero,
    
    output RegWrite,
    output MemWrite,
    output [5: 0] EXTOp, // 操作指令生成常数扩展操作 // control signal to signed extension
    output [4: 0] ALUOp, 
    output ALUSrc,
    output [1: 0] WDSrc,
    output [2: 0] DMType
);

// INIT
// R
wire rtype = ~Op[6]&Op[5]&Op[4]&~Op[3]&~Op[2]&Op[1]&Op[0];   //0110011
wire i_add = rtype&~Funct7[6]&~Funct7[5]&~Funct7[4]&~Funct7[3]&~Funct7[2]&~Funct7[1]&~Funct7[0]&~Funct3[2]&~Funct3[1]&~Funct3[0];  // add 0000000 000
wire i_sub = rtype&~Funct7[6]&Funct7[5]&~Funct7[4]&~Funct7[3]&~Funct7[2]&~Funct7[1]&~Funct7[0]&~Funct3[2]&~Funct3[1]&~Funct3[0]; // sub 0100000 000

// I_L
wire itype_l  = ~Op[6]&~Op[5]&~Op[4]&~Op[3]&~Op[2]&Op[1]&Op[0]; //0000011
wire i_lb=itype_l&~Funct3[2]& ~Funct3[1]& ~Funct3[0]; //lb 000
wire i_lh=itype_l&~Funct3[2]& ~Funct3[1]& Funct3[0];  //lh 001
wire i_lw=itype_l&~Funct3[2]& Funct3[1]& ~Funct3[0];  //lw 010

// I_I
wire itype_r  = ~Op[6]&~Op[5]&Op[4]&~Op[3]&~Op[2]&Op[1]&Op[0]; //0010011
wire i_addi  =  itype_r& ~Funct3[2]& ~Funct3[1]& ~Funct3[0]; // addi 000 func3

wire i_slli = itype_r & ~Funct3[2] & ~Funct3[1] & Funct3[0] & ~Funct7[0] & ~Funct7[1] & ~Funct7[2] & ~Funct7[3] & ~Funct7[4] & ~Funct7[5] & ~Funct7[6];
wire i_srli = itype_r & Funct3[2] & ~Funct3[1] & Funct3[0] & ~Funct7[0] & ~Funct7[1] & ~Funct7[2] & ~Funct7[3] & ~Funct7[4] & ~Funct7[5] & ~Funct7[6];

// S format
wire stype  =  ~Op[6] & Op[5] & ~Op[4] & ~Op[3] & ~Op[2] & Op[1] & Op[0];//0100011
wire i_sw   = stype & ~Funct3[2] & Funct3[1] & ~Funct3[0]; // sw 010
wire i_sb = stype & ~Funct3[2]& ~Funct3[1]&~Funct3[0];
wire i_sh = stype & ~Funct3[2]&~Funct3[1]&Funct3[0];

// Second
// Write && MUX
assign RegWrite = rtype | itype_l | itype_r;
assign MemWrite = stype;
assign ALUSrc = itype_r | itype_l | stype;
//mem2reg=wdsel ,WDSel_FromALU 2'b00  WDSel_FromMEM 2'b01
assign WDSrc[0] = itype_l;
assign WDSrc[1] = 1'b0;

// ALUOP
// Tips:
// `define ALUOp_add 5'b00000
// `define ALUOp_sub 5'b00001
// `define ALUOp_slli 5'b00010
// `define ALUOp_srli 5'b00011
assign ALUOp[0] = i_add | i_addi | stype | itype_l | i_srli;
assign ALUOp[1] = i_slli | i_srli; // itype_r & ~i_addi;    // 

// assign EXTOp[0] =  stype;
// assign EXTOp[1] =  itype_l | itype_r ; 
assign EXTOp[5]    =    i_slli | i_srli; // | i_srai
assign EXTOp[4]    =    (itype_l | itype_r) & ~i_slli &  ~i_srli; // & ~i_slli & ~i_srai & ~i_srli;  
assign EXTOp[3]    =    stype; 
// assign EXTOp[2]    =    sbtype; 
// assign EXTOp[1]    =    i_lui | i_auipc;   
// assign EXTOp[0]    =    i_jal;  

// DataMem
// dm_word 3'b000
//dm_halfword 3'b001
//dm_halfword_unsigned 3'b010
//dm_byte 3'b011
//dm_byte_unsigned 3'b100
// assign DMType[2] = i_lbu;
assign DMType[1] = i_lb | i_sb; // | i_lhu; // �? | 的话，那就应该可以先忽略
assign DMType[0] = i_lh | i_sh | i_lb | i_sb;

endmodule

module EXT( 
    input clk,
    input [4:0] iimm_shamt,
    input [11:0]	iimm, //instr[31:20], 12 bits
    input [11:0]	simm, //instr[31:25, 11:7], 12 bits
    input [11:0]	bimm, //instrD[31],instrD[7], instrD[30:25], instrD[11:8], 12 bits
    input [19:0]	uimm,
    input [19:0]	jimm,
    input [5:0]	 EXTOp,
    output reg [31:0] immout
);

//EXT CTRL itype, stype, btype, utype, jtype
`define EXT_CTRL_ITYPE_SHAMT 6'b100000
`define EXT_CTRL_ITYPE	6'b010000
`define EXT_CTRL_STYPE	6'b001000
`define EXT_CTRL_BTYPE	6'b000100
`define EXT_CTRL_UTYPE	6'b000010
`define EXT_CTRL_JTYPE	6'b000001

always @ (*) begin
    case (EXTOp)
		`EXT_CTRL_ITYPE_SHAMT:   immout<={27'b0,iimm_shamt[4:0]};
		`EXT_CTRL_ITYPE:    immout<={ {20{ iimm[11]}},iimm[11:0]};
		`EXT_CTRL_STYPE:	immout<={ {20{ simm[11]}},simm[11:0]};
		`EXT_CTRL_BTYPE:    immout<={ {19{ bimm[11]}},bimm[11:0], 1'b0} ;
		`EXT_CTRL_UTYPE:	immout <= {uimm[19:0], 12'b0}; 
		`EXT_CTRL_JTYPE:	immout<={{11{ jimm[19]}},jimm[19:0],1'b0};
		default:  immout <= 32'b0;
	 endcase
end

endmodule

module seg7x16(
    input clk,
    input rstn,
    // 特殊的图�???/文本模式
    input disp_mode,

    input [63:0] i_data,
    output [7:0] o_seg,
    output [7:0] o_sel
);

reg [14:0] cnt;
wire seg7_clk;
// 分频 模块
always @ (posedge clk, negedge rstn)
    if(!rstn)
        cnt <= 0;
    else
        cnt <= cnt + 1'b1;
assign seg7_clk = cnt[14];

// 8->1
reg [2:0] seg7_addr;    // 8->1
always @ (posedge seg7_clk, negedge rstn)
    if(!rstn)
        seg7_addr <= 1'b0;
    else
        seg7_addr <= seg7_addr + 1'b1;

// 使能信号，选中目标LED
reg [7:0] o_sel_r;
always @ (*)
    case(seg7_addr)
        7: o_sel_r = 8'b01111111;
        6: o_sel_r = 8'b10111111;
        5: o_sel_r = 8'b11011111;
        4: o_sel_r = 8'b11101111;
        3: o_sel_r = 8'b11110111;
        2: o_sel_r = 8'b11111011;
        1: o_sel_r = 8'b11111101;
        0: o_sel_r = 8'b11111110;
    endcase

reg [63:0] i_data_store;
always @ (posedge clk, negedge rstn)
    if(!rstn)
        i_data_store <= 1'b0;
    else
        i_data_store <= i_data;

// 分段拆分data -> 8
reg [7:0] seg_data_r;
always @ (*)
    if(disp_mode == 1'b0)
        begin
            case(seg7_addr)
                0: seg_data_r = i_data_store[3:0];
                1: seg_data_r = i_data_store[7:4];
                2: seg_data_r = i_data_store[11:8];
                3: seg_data_r = i_data_store[15:12];
                4: seg_data_r = i_data_store[19:16];
                5: seg_data_r = i_data_store[23:20];
                6: seg_data_r = i_data_store[27:24];
                7: seg_data_r = i_data_store[31:28];
            endcase
        end
    else
        begin
            case(seg7_addr)
                0: seg_data_r = i_data_store[7:0];
                1: seg_data_r = i_data_store[15:8];
                2: seg_data_r = i_data_store[23:16];
                3: seg_data_r = i_data_store[31:24];
                4: seg_data_r = i_data_store[39:32];
                5: seg_data_r = i_data_store[47:40];
                6: seg_data_r = i_data_store[55:48];
                7: seg_data_r = i_data_store[63:56];
            endcase
        end

// 16进制 7段数码管设置 1->7段码
reg [7:0] o_seg_r;
always @ (posedge clk, negedge rstn)
    if(!rstn)
        o_seg_r <= 8'hff;   // 默认全黑 
    else
        if(disp_mode == 1'b0)
            begin
                case(seg_data_r)
                        4'h0: o_seg_r <= 8'hC0;
                        4'h1: o_seg_r <= 8'hF9;
                        4'h2: o_seg_r <= 8'hA4;
                        4'h3: o_seg_r <= 8'hB0;
                        4'h4: o_seg_r <= 8'h99;
                        4'h5: o_seg_r <= 8'h92;
                        4'h6: o_seg_r <= 8'h82;
                        4'h7: o_seg_r <= 8'hF8;
                        4'h8: o_seg_r <= 8'h80;
                        4'h9: o_seg_r <= 8'h90;
                        4'hA: o_seg_r <= 8'h88;
                        4'hB: o_seg_r <= 8'h83;
                        4'hC: o_seg_r <= 8'hC6;
                        4'hD: o_seg_r <= 8'hA1;
                        4'hE: o_seg_r <= 8'h86;
                        4'hF: o_seg_r <= 8'h8E;
                default:
                    o_seg_r <= 8'hFF;
                endcase
            end
        else
            begin
                o_seg_r <= seg_data_r;
            end
 
assign o_sel = o_sel_r;
assign o_seg = o_seg_r;

endmodule