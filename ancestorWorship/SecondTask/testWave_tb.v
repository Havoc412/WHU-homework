//~ `New testbench
`timescale  1ns / 1ps
`include "testWave.v"

module tb_Wave;

// Wave Parameters
parameter PERIOD  = 10;


// Wave Inputs
reg   a                                    = 0 ;
reg   b                                    = 0 ;
reg   c                                    = 0 ;

// Wave Outputs

Wave  u_Wave (
    .a                       ( a   ),
    .b                       ( b   ),
    .c                       ( c   )
);

initial
begin
    $dumpfile("testWave.vcd");
    $dumpvars;
    #300 $finish;
end

endmodule