`include "Define.v"

// info 单周期应该用不到这个。
// 好像是存储 指令 用的模块。 -> 确实。// 不过我用 IP 核就是了。
module IM(
    input [`ADDR_WIDTH-1: 0] addr,
    
    output [`XLEN-1: 0] dt // question ?
    );

    reg [`INSTR_WIDTH-1: 0] RAM [`IMEM_NUM-1: 0];   // question ?
    assign dt = RAM[addr[11: 2]];  // instruction size aligned
endmodule

module DM(
    // ctrl sign
    input clk, rstn,
    input memWrite, 
    input [`SL_WIDTH-1: 0] lwhb, swhb,

    // data change
    input [`DMEM_WIDTH-1: 0] addr,
    input [`XLEN-1: 0]  wd,

    output reg [`XLEN-1: 0] dt
    );

    reg [`DMEM_WIDTH-1: 0] dmem [`DMEM_NUM-1: 0];

    // 处理 store
    integer i;
    always @ (negedge clk or negedge rstn) begin
        if(!rstn) begin
            for(i=0; i<`DMEM_NUM; i = i+1)
                dmem[i] = 8'b0;
            dmem[0] = 4; // test 检查一下 能否读到。
        end
        else if(memWrite) begin
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
        end
    end

    // 配合 load, 适用于 单周期
    // todo 处理 unsigned && signed ?
    always @(*) begin
        case(lwhb)
            `SL_B: dt <= dmem[addr];
            `SL_H: dt <= { dmem[addr+1], dmem[addr]};
            `SL_W: dt <= { dmem[addr+3], dmem[addr+2], dmem[addr+1], dmem[addr]};
            default :
                dt <= `XLEN'b0;
        endcase
    end

endmodule