`include "Define.v"

module RF(
    input clk, rst,
    input regWrite,
    input [`RFIDX_WIDTH-1: 0] A1, A2, A3, // mark A1,A2 -> read ; A3 -> load
    input [`XLEN-1: 0] wd,

    output [`XLEN-1: 0] dt1, dt2,   // info data
    input [4: 0] n
    );

    reg [`XLEN-1: 0] rf [`RFREG_NUM-1: 0];

    integer i;
    always @ (negedge clk or negedge rst) begin
        if(!rst) begin
            for(i=0; i<32; i = i+1)
                rf[i] = 32'b0;
            rf[6] = n;  // info 特化 对于 fib 代码之于 n 的初始化。
        end
        else if(regWrite && A3 != 0) begin  // 写信号 && 排除 x0;
            rf[A3] <= wd;
        end
    end

    assign dt1 = (A1 != 0) ? rf[A1] : 0;
    assign dt2 = (A2 != 0) ? rf[A2] : 0;
endmodule
