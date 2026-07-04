module hazard_detection_unit(
    input id_ex_MemRead,
    input [4:0] id_ex_rd,
    input [4:0] if_id_rs1,
    input [4:0] if_id_rs2,

    output reg PCWrite,
    output reg IF_ID_Write,
    output reg ControlMux
);

always @(*) begin
    if(id_ex_MemRead && ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2)) && (id_ex_rd != 5'd0))
    begin
        PCWrite = 1'b0;
        IF_ID_Write = 1'b0;
        ControlMux = 1'b1;
    end
    else begin
        PCWrite = 1'b1;
        IF_ID_Write = 1'b1;
        ControlMux = 1'b0;
    end
end

endmodule

