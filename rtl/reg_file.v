module reg_file (
    input clk, we,
    input [4:0]rs1, 
    input [4:0]rs2, 
    input [4:0]rd,
    input [31:0]wd, 
    output [31:0]rd1, 
    output [31:0]rd2
);
reg [31:0] regs [0:31];

    integer i;

    // Optional initialization (simulation only)
    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'b0;
    end

    // Write logic
    always @(posedge clk) begin
        if (we && (rd != 5'd0))
            regs[rd] <= wd;
    end

    // Read logic (combinational, with write-first bypass)
    assign rd1 = (rs1 == 5'd0) ? 32'b0 :
                 (we && (rd != 5'd0) && (rd == rs1)) ? wd : regs[rs1];

    assign rd2 = (rs2 == 5'd0) ? 32'b0 :
                 (we && (rd != 5'd0) && (rd == rs2)) ? wd : regs[rs2];

endmodule
