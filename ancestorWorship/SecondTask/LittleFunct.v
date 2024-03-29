`include "Define.v"

// info 二路多选器，src ? T -> d1, F -> d0; (ps. 感觉在 poop注释.doge)
module mux2 #(parameter WIDTH = 8) (
    input [WIDTH-1: 0] d0, d1,
    input src,
    output [WIDTH-1: 0] out
    );

    assign out = src ? d1 : d0;
endmodule

module mux3 #(parameter WIDTH = 8) (
    input [WIDTH-1: 0] d0, d1, d2,
    input [1: 0] src,
    output [WIDTH-1: 0] out
    );

    assign out = src[1] ? d2 : (src[0] ? d1 : d0);  // info 注意 define 和 d0~2 之间的对应。（ps. 不然等着 debug 不出来吧...）
endmodule
