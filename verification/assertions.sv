property p_x0_never_written;
    @(posedge clk) (dut.rf.regs[0] == 32'd0);
endproperty
A1_x0_never_written : assert property (p_x0_never_written) else $error("[A1 FAIL]");

property p_ex_fwd_rs1;
    @(posedge clk) disable iff (rst)
    ( dut.ex_mem_RegWrite && dut.ex_mem_rd != 5'd0 && dut.ex_mem_rd == dut.id_ex_rs1 )
    |-> (dut.forwardA == 2'b10);
endproperty
A2_ex_fwd_rs1 : assert property (p_ex_fwd_rs1) else $error("[A2 FAIL]");

property p_ex_fwd_rs2;
    @(posedge clk) disable iff (rst)
    ( dut.ex_mem_RegWrite && dut.ex_mem_rd != 5'd0 && dut.ex_mem_rd == dut.id_ex_rs2 )
    |-> (dut.forwardB == 2'b10);
endproperty
A3_ex_fwd_rs2 : assert property (p_ex_fwd_rs2) else $error("[A3 FAIL]");

property p_mem_fwd_rs1;
    @(posedge clk) disable iff (rst)
    ( dut.mem_wb_RegWrite && dut.mem_wb_rd != 5'd0 && dut.mem_wb_rd == dut.id_ex_rs1 &&
      !(dut.ex_mem_RegWrite && (dut.ex_mem_rd == dut.id_ex_rs1)) )
    |-> (dut.forwardA == 2'b01);
endproperty
A4_mem_fwd_rs1 : assert property (p_mem_fwd_rs1) else $error("[A4 FAIL]");

property p_load_use_stall;
    @(posedge clk) disable iff (rst)
    dut.id_ex_MemRead |-> (!dut.PCWrite && !dut.IF_ID_Write);
endproperty
A5_load_use_stall : assert property (p_load_use_stall) else $error("[A5 FAIL]");

property p_pc_plus4;
    @(posedge clk) disable iff (rst)
    (dut.PCWrite && !dut.flush && dut.opcode != 7'b1101111 && dut.opcode != 7'b1100111)
    |=> (dut.pc == ($past(dut.pc) + 32'd4));
endproperty
A6_pc_plus4 : assert property (p_pc_plus4) else $error("[A6 FAIL]");

property p_reset_pc_zero;
    @(posedge clk) rst |=> (dut.pc == 32'h0000_0000);
endproperty
A7_reset_pc_zero : assert property (p_reset_pc_zero) else $error("[A7 FAIL]");
