`include "Define.v"

// info 单周期应该用不到这个。
// question 好像是存储 指令 用的模块。 -> 确实。
module IM(
    input [`ADDR_WIDTH-1: 0] addr,
    
    output [`XLEN-1: 0] dt // question ?
    );

    reg [`INSTR_WIDTH-1: 0] RAM [`IMEM_NUM-1: 0];   // question ?
    assign dt = RAM[addr[11: 2]];  // instruction size aligned
endmodule

module DM(
    input clk, rst,
    input memWrite, 
    // input sw_1, // test debug, 不过我一步步执行，也不用不太到。    
    input [`XLEN-1: 0]  wd,
    input [`DMEM_WIDTH-1: 0] addr,
    input [`SL_WIDTH-1: 0] lwhb, swhb,

    output reg [`XLEN-1: 0] dt,

    input [`INSTR_NUM-1: 0] pc // test
    );

    reg [`DMEM_WIDTH: 0] dmem [`DMEM_NUM: 0];

    // 处理 store
    integer i;
    always @ (negedge clk or negedge rst) begin
        if(!rst)
            for(i=0; i<`DMEM_NUM; i = i+1)
                dmem[i] = 8'b0;
        else
        if(memWrite) begin
            case(swhb)
                `SL_B: dmem[addr] <= wd[7: 0];
                `SL_H: begin
                    dmem[addr] <= wd[7: 0];
                    dmem[addr+1] <= wd[15: 8];
                end
                `SL_W: begin
                    dmem[addr] <= wd[7: 0]; // 小端存储
                    dmem[addr+1] <= wd[15: 8];
                    dmem[addr+2] <= wd[23: 16];
                    dmem[addr+3] <= wd[31: 24];
                end
            endcase
            $display("pc = %h: dataaddr = %h, memdata = %h", pc, addr, wd);
        end
    end

    // 配合 load, 适用于 单周期
    // todo 处理 unsigned && signed ?
    always @(*) begin
        case(lwhb)
            `SL_B: dt <= dmem[addr];
            `SL_H: dt <= { dmem[addr+1], dmem[addr]};
            `SL_W: dt <= { dmem[addr+3], dmem[addr+2], dmem[addr+1], dmem[addr]};
        endcase
    end

endmodule