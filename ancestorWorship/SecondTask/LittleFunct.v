`include "Define.v"

// tag flop
module floprc #(parameter WIDTH = 8) (
        input clk, rstn, clear, // question clear's source
        input [WIDTH-1: 0] d,
        output reg [WIDTH-1: 0] q
    );

    always @(posedge clk or negedge rstn) begin
        if(!rstn)        q<=0;
        else if(clear)  q<=0;
        else            q<=d;
    end

endmodule

module flopenrc #(parameter WIDTH = 8) (
        input clk, rstn, en, clear,
        input [WIDTH-1: 0] d,
        output reg [WIDTH-1: 0] q
    );

    always @(posedge clk or negedge rstn) begin
        if(!rstn)        q<=0;
        else if(clear)  q<=0;
        else if(en)     q<=d;
    end

endmodule

module flopenr #(parameter WIDTH = 8) (
        input clk, rstn, en,
        input [WIDTH-1: 0] d,
        output reg [WIDTH-1: 0] q
    );
    
    always @(posedge clk or negedge rstn) begin
        if(!rstn)    q<=0;
        else if(en) q<=d;
    end
    
endmodule


// tag 二路多选器，src ? T -> d1, F -> d0; (ps. 感觉在 poop 注释.doge)
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

// info 设计就是如此，虽然 2bit 足够 4选，但是语法上这样更方便表达。（反正能 run）
module mux4 #(parameter WIDTH = 8) (
        input [WIDTH-1: 0] d0, d1, d2, d3, // info 排在后者优先级更高。
        input [2: 0] src,
        output [WIDTH-1: 0] out
    );

    assign out = src[2] ? d3 : (src[1] ? d2 : (src[0] ? d1 : d0));
endmodule