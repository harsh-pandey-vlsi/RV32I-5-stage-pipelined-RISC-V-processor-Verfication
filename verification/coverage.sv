covergroup cg_opcode @(posedge clk);
    cp_opcode : coverpoint dut.opcode {
        bins r_type = {7'b011_0011};
        bins i_alu  = {7'b001_0011};
        bins load   = {7'b000_0011};
        bins store  = {7'b010_0011};
        bins branch = {7'b110_0011};
        bins lui    = {7'b011_0111};
        bins auipc  = {7'b001_0111};
        bins nop_or_other = default;
    }
endgroup

covergroup cg_forwarding @(posedge clk);
    cp_fwdA : coverpoint dut.forwardA { bins no_fwd={2'b00}; bins mem_to_ex={2'b01}; bins ex_to_ex={2'b10}; }
    cp_fwdB : coverpoint dut.forwardB { bins no_fwd={2'b00}; bins mem_to_ex={2'b01}; bins ex_to_ex={2'b10}; }
    cp_fwd_cross : cross cp_fwdA, cp_fwdB;
endgroup

covergroup cg_pipeline_ctrl @(posedge clk);
    cp_stall : coverpoint dut.PCWrite { bins stalled = {1'b0}; bins running = {1'b1}; }
    cp_flush : coverpoint dut.flush   { bins branch_taken = {1'b1}; bins no_branch = {1'b0}; }
endgroup

covergroup cg_alu_ops @(posedge clk);
    cp_aluop : coverpoint dut.ALUControl {
        bins op_add={4'b0000}; bins op_sub={4'b0001}; bins op_and={4'b0010}; bins op_or={4'b0011};
        bins op_xor={4'b0100}; bins op_slt={4'b0101}; bins op_sltu={4'b0110}; bins op_sll={4'b0111};
        bins op_srl={4'b1000}; bins op_sra={4'b1001};
    }
endgroup

cg_opcode        cov_opcode;
cg_forwarding    cov_fwd;
cg_pipeline_ctrl cov_ctrl;
cg_alu_ops       cov_alu;

initial begin
    cov_opcode = new(); cov_fwd = new(); cov_ctrl = new(); cov_alu = new();
end
