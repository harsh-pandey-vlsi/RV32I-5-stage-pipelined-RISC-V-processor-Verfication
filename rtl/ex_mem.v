module ex_mem (
    input clk,
    input rst,

    input  [31:0] alu_result_in,
    input         zero_in,
    input  [31:0] rd2_in,
    input  [4:0]  rd_in,

    input         RegWrite_in,
    input         MemRead_in,
    input         MemWrite_in,
    input         MemToReg_in,
    input         Branch_in,
    input         Jump_in,

    output reg [31:0] alu_result_out,
    output reg        zero_out,
    output reg [31:0] rd2_out,
    output reg [4:0]  rd_out,

    output reg        RegWrite_out,
    output reg        MemRead_out,
    output reg        MemWrite_out,
    output reg        MemToReg_out,
    output reg        Branch_out,
    output reg        Jump_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_result_out <= 0;
            zero_out       <= 0;
            rd2_out        <= 0;
            rd_out         <= 0;
            RegWrite_out   <= 0;
            MemRead_out    <= 0;
            MemWrite_out   <= 0;
            MemToReg_out   <= 0;
            Branch_out     <= 0;
            Jump_out       <= 0;
        end else begin
            alu_result_out <= alu_result_in;
            zero_out       <= zero_in;
            rd2_out        <= rd2_in;
            rd_out         <= rd_in;
            RegWrite_out   <= RegWrite_in;
            MemRead_out    <= MemRead_in;
            MemWrite_out   <= MemWrite_in;
            MemToReg_out   <= MemToReg_in;
            Branch_out     <= Branch_in;
            Jump_out       <= Jump_in;
        end
    end

endmodule

