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