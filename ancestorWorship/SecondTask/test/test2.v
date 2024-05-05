module adder(X, Y, Cin, Cout, S);

	input [0:1] X;
	input [0:1] Y;
	input Cin;
	output reg [0:1]S;
	output reg Cout;

	always @(X , Y , Cin) begin
   		 {Cout , S} = X + Y + Cin;
	end
endmodule

module testBench();
    reg [0:1] A , B;
    reg Cin;
    output [0:1]S;
    output Cout;
    
    adder U(
    .X(A),
    .Y(B),
    .Cin(Cin),
    .Cout(Cout),
    .S(S)
    );
    
    initial begin
        A = 0;
        B = 2;
        Cin = 1;
        // #10 A = 1; // 这个 #XX 是延时 XXs 之后，才会改变
        #10 Cin = 1;
        #10 B = 0;
        #20 A = 3;
        #30 Cin = 0;
        #40 B = 3;
        #50 Cin = 1;
    end
    
    initial begin
        $monitor($time,"part:%b  %b", S, Cout);
        #70
        $finish;
    end
/*iverilog */
    initial
    begin            
        $dumpfile("wave.vcd");        //生成的vcd文件名称
        $dumpvars(0, testBench);    //tb模块名称
    end
/*iverilog */

endmodule
