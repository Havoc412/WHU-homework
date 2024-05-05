`include "Define.v"

// tag 数据定向处理单元
module ForwardingUnit (
    input [`RFIDX_WIDTH: 0] rs1, rs2, // info EX
    input [`RFIDX_WIDTH: 0] rdM, rdW,
    input regWriteM, regWriteW,
     
    output [`FORWARD_WIDTH: 0] forward_a,
    output [`FORWARD_WIDTH: 0] forward_b
);

  assign forward_a = ((regWriteM) && (rdM != 5'b0) && (rdM == rs1)) ? `FORWARD_EX :
                    ((regWriteW) && (rdW != 5'b0) && (rs1 == rdW)) ? `FORWARD_MEM : `FORWARD_ZERO ;
                    
  assign forward_b = ((regWriteM) && (rdM != 5'b0) && (rs2 == rdM)) ?  `FORWARD_EX : 
                    ((regWriteW) && (rdW != 5'b0) && (rs2 == rdW)) ?  `FORWARD_MEM : `FORWARD_ZERO ;

endmodule
