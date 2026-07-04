module control_unit (
    input  [6:0] opcode,

    output reg        RegWrite,
    output reg        MemRead,
    output reg        MemWrite,
    output reg        MemToReg,
    output reg        ALUSrc,
    output reg        Branch,
    output reg        Jump,
    output reg [1:0]  ALUOp
);

    always @(*) begin

        // Default safe values
        RegWrite = 1'b0;
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        MemToReg = 1'b0;
        ALUSrc   = 1'b0;
        Branch   = 1'b0;
        Jump     = 1'b0;
        ALUOp    = 2'b00;

        case (opcode)

            // R-Type
            7'b0110011: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b0;
                ALUOp    = 2'b10;
            end

            // I-Type 
            7'b0010011: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 2'b10;
            end

            // LOAD
            7'b0000011: begin
                RegWrite = 1'b1;
                MemRead  = 1'b1;
                MemToReg = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 2'b00;
            end

            // STORE
            7'b0100011: begin
                MemWrite = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 2'b00;
            end

            // Branch
            7'b1100011: begin
                Branch = 1'b1;
                ALUOp  = 2'b01;
            end

            // JAL
            7'b1101111: begin
                RegWrite = 1'b1;
                Jump     = 1'b1;
            end

            // JALR
            7'b1100111: begin
                RegWrite = 1'b1;
                Jump     = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 2'b00;
            end

            // LUI
            7'b0110111: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
            end

            // AUIPC
            7'b0010111: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 2'b00;
            end

            //SYSTEM/CSR
            7'b1110011: begin
                RegWrite = 1'b0;
            end

            default: begin
                // Illegal instruction → remain safe
                RegWrite = 1'b0;
                MemRead  = 1'b0;
                MemWrite = 1'b0;
                MemToReg = 1'b0;
                ALUSrc   = 1'b0;
                Branch   = 1'b0;
                Jump     = 1'b0;
                ALUOp    = 2'b00;
            end

        endcase
    end

endmodule

