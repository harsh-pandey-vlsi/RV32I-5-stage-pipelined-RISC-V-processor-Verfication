module id_ex (
    input clk,
    input rst,
    input flush,

    // Data
    input  [31:0] pc_in,
    input  [31:0] rd1_in,
    input  [31:0] rd2_in,
    input  [31:0] imm_in,
    input  [4:0]  rs1_in,
    input  [4:0]  rs2_in,
    input  [4:0]  rd_in,
    input  [2:0]  funct3_in,
    input  [6:0]  funct7_in,

    // Control
    input         RegWrite_in,
    input         MemRead_in,
    input         MemWrite_in,
    input         MemToReg_in,
    input         ALUSrc_in,
    input         Branch_in,
    input         Jump_in,
    input  [1:0]  ALUOp_in,

    // Outputs
    output reg [31:0] pc_out,
    output reg [31:0] rd1_out,
    output reg [31:0] rd2_out,
    output reg [31:0] imm_out,
    output reg [4:0]  rs1_out,
    output reg [4:0]  rs2_out,
    output reg [4:0]  rd_out,
    output reg [2:0]  funct3_out,
    output reg [6:0]  funct7_out,

    output reg        RegWrite_out,
    output reg        MemRead_out,
    output reg        MemWrite_out,
    output reg        MemToReg_out,
    output reg        ALUSrc_out,
    output reg        Branch_out,
    output reg        Jump_out,
    output reg [1:0]  ALUOp_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out        <= 0;
            rd1_out       <= 0;
            rd2_out       <= 0;
            imm_out       <= 0;
            rs1_out       <= 0;
            rs2_out       <= 0;
            rd_out        <= 0;
            funct3_out    <= 0;
            funct7_out    <= 0;
            RegWrite_out  <= 0;
            MemRead_out   <= 0;
            MemWrite_out  <= 0;
            MemToReg_out  <= 0;
            ALUSrc_out    <= 0;
            Branch_out    <= 0;
            Jump_out      <= 0;
            ALUOp_out     <= 0;
        end
        else if (flush) begin
            RegWrite_out <= 0;
            MemRead_out  <= 0;
            MemWrite_out <= 0;
            MemToReg_out <= 0;
            ALUSrc_out   <= 0;
            Branch_out   <= 0;
            Jump_out     <= 0;
            ALUOp_out    <= 0;
        end else begin
            pc_out        <= pc_in;
            rd1_out       <= rd1_in;
            rd2_out       <= rd2_in;
            imm_out       <= imm_in;
            rs1_out       <= rs1_in;
            rs2_out       <= rs2_in;
            rd_out        <= rd_in;
            funct3_out    <= funct3_in;
            funct7_out    <= funct7_in;
            RegWrite_out  <= RegWrite_in;
            MemRead_out   <= MemRead_in;
            MemWrite_out  <= MemWrite_in;
            MemToReg_out  <= MemToReg_in;
            ALUSrc_out    <= ALUSrc_in;
            Branch_out    <= Branch_in;
            Jump_out      <= Jump_in;
            ALUOp_out     <= ALUOp_in;
        end
    end

endmodule

