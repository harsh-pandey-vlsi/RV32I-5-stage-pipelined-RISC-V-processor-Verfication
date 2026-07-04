module alu_control (
    input      [1:0] ALUOp,
    input      [2:0] funct3,
    input      [6:0] funct7,
    output reg [3:0] ALUControl
);

    always @(*) begin

        case (ALUOp)

            // Load/Store
            2'b00: begin
                ALUControl = 4'b0000; // ADD
            end

            // Branch
            2'b01: begin
                ALUControl = 4'b0001; // SUB
            end

            // R-Type / I-Type 
            2'b10: begin
                case (funct3)

                    3'b000: begin
                        if (funct7 == 7'b0100000)
                            ALUControl = 4'b0001; // SUB
                        else
                            ALUControl = 4'b0000; // ADD
                    end

                    3'b001: ALUControl = 4'b0111; //SLL
                    3'b010: ALUControl = 4'b0101; // SLT
                    3'b011: ALUControl = 4'b0110; // SLTU
                    3'b100: ALUControl = 4'b0100; // XOR
                    
                    3'b101: begin
                        if (funct7 == 7'b0100000)
                            ALUControl = 4'b1001; //SRA
                        else
                            ALUControl = 4'b1000; //SRL
                    end

                    3'b110: ALUControl = 4'b0011;  //OR
                    3'b111: ALUControl = 4'b0010;  //AND

                    default: ALUControl = 4'b0000;

                endcase
            end

            default: begin
                ALUControl = 4'b0000;
            end

        endcase

    end

endmodule

