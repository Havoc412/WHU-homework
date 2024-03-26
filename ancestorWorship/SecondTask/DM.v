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