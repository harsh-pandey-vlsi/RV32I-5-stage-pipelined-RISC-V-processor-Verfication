module if_id (
    input         clk,
    input         rst,
    input         flush,

    input  [31:0] pc_in,
    input  [31:0] instr_in,

    input write_en,

    output reg [31:0] pc_out,
    output reg [31:0] instr_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out    <= 32'b0;
            instr_out <= 32'b0;
        end 
        else if(flush) begin
            pc_out    <= 32'b0;
            instr_out <= 32'h00000013;
        end else if(write_en) begin
            pc_out    <= pc_in;
            instr_out <= instr_in;
        end
    end

endmodule

