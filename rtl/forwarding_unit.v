module forwarding_unit(
    input [4:0]id_ex_rs1,
    input [4:0]id_ex_rs2,
    input [4:0]ex_mem_rd,
    input ex_mem_RegWrite,
    input [4:0]mem_wb_rd,
    input mem_wb_RegWrite,

    output reg [1:0]forwardA,
    output reg [1:0]forwardB

);
always @(*) begin
forwardA=2'b00;
forwardB=2'b00;

if(ex_mem_RegWrite && (ex_mem_rd!=5'd0) && (ex_mem_rd==id_ex_rs1))
forwardA=2'b10;

if(ex_mem_RegWrite && (ex_mem_rd!=5'd0) && (ex_mem_rd==id_ex_rs2))
forwardB=2'b10;

if(mem_wb_RegWrite && (mem_wb_rd != 5'd0) && !(ex_mem_RegWrite &&
(ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs1)) &&
(mem_wb_rd == id_ex_rs1))
forwardA = 2'b01;

if(mem_wb_RegWrite && (mem_wb_rd != 5'd0) && !(ex_mem_RegWrite &&
(ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs2)) &&
(mem_wb_rd == id_ex_rs2))
forwardB = 2'b01;

end

endmodule


