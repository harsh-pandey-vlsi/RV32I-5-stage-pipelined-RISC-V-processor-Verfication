`timescale 1ns/1ps
module riscv_pipeline (
    input clk,
    input rst
);

    // =========================
    // Global Wires (declare once)
    // =========================

    wire [31:0] pc, pc_next, instr;

    wire [31:0] if_id_pc, if_id_instr;

    wire [31:0] id_ex_pc, id_ex_rd1, id_ex_rd2, id_ex_imm;
    wire [4:0]  id_ex_rs1, id_ex_rs2, id_ex_rd;
    wire [2:0]  id_ex_funct3;
    wire [6:0]  id_ex_funct7;
    wire        id_ex_RegWrite, id_ex_MemRead, id_ex_MemWrite;
    wire        id_ex_MemToReg, id_ex_ALUSrc;
    wire        id_ex_Branch, id_ex_Jump;
    wire [1:0]  id_ex_ALUOp;

    wire [31:0] ex_mem_alu_result, ex_mem_rd2;
    wire [4:0]  ex_mem_rd;
    wire        ex_mem_RegWrite, ex_mem_MemRead;
    wire        ex_mem_MemWrite, ex_mem_MemToReg;

    wire [31:0] mem_wb_mem_data, mem_wb_alu_result;
    wire [4:0]  mem_wb_rd;
    wire        mem_wb_RegWrite, mem_wb_MemToReg;

    wire [31:0] write_back_data;

    wire [1:0] forwardA;
    wire [1:0] forwardB;

    wire PCWrite;
    wire IF_ID_Write;
    wire ControlMux;

    wire branch_taken;
    wire [31:0] branch_target;
    wire flush;
   

    // =========================
    // IF STAGE
    // =========================

    pc pc_inst (
        .clk(clk),
        .rst(rst),
        .PCWrite(PCWrite),
        .pc_next(pc_next),
        .pc(pc)
    );

    instr_mem imem (
        .addr(pc),
        .instr(instr)
    );

    assign pc_next = flush ? branch_target : pc + 4;

    if_id if_id_reg (
        .clk(clk),
        .rst(rst),
        .flush(flush),
        .write_en(IF_ID_Write),
        .pc_in(pc),
        .instr_in(instr),
        .pc_out(if_id_pc),
        .instr_out(if_id_instr)
    );

    // =========================
    // ID STAGE
    // =========================

    wire [6:0] opcode = if_id_instr[6:0];
    wire [4:0] rs1 = if_id_instr[19:15];
    wire [4:0] rs2 = if_id_instr[24:20];
    wire [4:0] rd  = if_id_instr[11:7];
    wire [2:0] funct3 = if_id_instr[14:12];
    wire [6:0] funct7 = if_id_instr[31:25];

    wire RegWrite, MemRead, MemWrite, MemToReg;
    wire ALUSrc, Branch, Jump;
    wire [1:0] ALUOp;

    hazard_detection_unit hdu(

    .id_ex_MemRead(id_ex_MemRead),
    .id_ex_rd(id_ex_rd),

    .if_id_rs1(rs1),
    .if_id_rs2(rs2),

    .PCWrite(PCWrite),
    .IF_ID_Write(IF_ID_Write),
    .ControlMux(ControlMux)

    );

    control_unit ctrl (
        .opcode(opcode),
        .RegWrite(RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .MemToReg(MemToReg),
        .ALUSrc(ALUSrc),
        .Branch(Branch),
        .Jump(Jump),
        .ALUOp(ALUOp)
    );

    wire [31:0] rd1, rd2;

    reg_file rf (
        .clk(clk),
        .we(mem_wb_RegWrite),
        .rs1(rs1),
        .rs2(rs2),
        .rd(mem_wb_rd),
        .wd(write_back_data),
        .rd1(rd1),
        .rd2(rd2)
    );

    wire [31:0] imm_out;

    imm_gen imm (
        .instr(if_id_instr),
        .imm_out(imm_out)
    );

    //Bubble Injection

    wire RegWrite_safe;
    wire MemRead_safe;
    wire MemWrite_safe;
    wire MemToReg_safe;
    wire ALUSrc_safe;
    wire Branch_safe;
    wire Jump_safe;
    wire [1:0] ALUOp_safe;

    assign RegWrite_safe =
        ControlMux ? 1'b0 : RegWrite;

    assign MemRead_safe =
        ControlMux ? 1'b0 : MemRead;

    assign MemWrite_safe =
        ControlMux ? 1'b0 : MemWrite;

    assign MemToReg_safe =
        ControlMux ? 1'b0 : MemToReg;

    assign ALUSrc_safe =
        ControlMux ? 1'b0 : ALUSrc;

    assign Branch_safe =
        ControlMux ? 1'b0 : Branch;

    assign Jump_safe =
        ControlMux ? 1'b0 : Jump;

    assign ALUOp_safe =
        ControlMux ? 2'b00 : ALUOp;

    id_ex id_ex_reg (
        .clk(clk),
        .rst(rst),
        .flush(flush),
        .pc_in(if_id_pc),
        .rd1_in(rd1),
        .rd2_in(rd2),
        .imm_in(imm_out),
        .rs1_in(rs1),
        .rs2_in(rs2),
        .rd_in(rd),
        .funct3_in(funct3),
        .funct7_in(funct7),
        .RegWrite_in(RegWrite_safe),
        .MemRead_in(MemRead_safe),
        .MemWrite_in(MemWrite_safe),
        .MemToReg_in(MemToReg_safe),
        .ALUSrc_in(ALUSrc_safe),
        .Branch_in(Branch_safe),
        .Jump_in(Jump_safe),
        .ALUOp_in(ALUOp_safe),
        .pc_out(id_ex_pc),
        .rd1_out(id_ex_rd1),
        .rd2_out(id_ex_rd2),
        .imm_out(id_ex_imm),
        .rs1_out(id_ex_rs1),
        .rs2_out(id_ex_rs2),
        .rd_out(id_ex_rd),
        .funct3_out(id_ex_funct3),
        .funct7_out(id_ex_funct7),
        .RegWrite_out(id_ex_RegWrite),
        .MemRead_out(id_ex_MemRead),
        .MemWrite_out(id_ex_MemWrite),
        .MemToReg_out(id_ex_MemToReg),
        .ALUSrc_out(id_ex_ALUSrc),
        .Branch_out(id_ex_Branch),
        .Jump_out(id_ex_Jump),
        .ALUOp_out(id_ex_ALUOp)
    );

    wire [31:0] alu_result;
    wire        zero;

    // =========================
    // EX STAGE
    // =========================
    
    forwarding_unit u_forwarding(

    .id_ex_rs1(id_ex_rs1),
    .id_ex_rs2(id_ex_rs2),

    .ex_mem_rd(ex_mem_rd),
    .ex_mem_RegWrite(ex_mem_RegWrite),

    .mem_wb_rd(mem_wb_rd),
    .mem_wb_RegWrite(mem_wb_RegWrite),

    .forwardA(forwardA),
    .forwardB(forwardB)

    );


    wire [3:0] ALUControl;

    alu_control alu_ctrl (
        .ALUOp(id_ex_ALUOp),
        .funct3(id_ex_funct3),
        .funct7(id_ex_funct7),
        .ALUControl(ALUControl)
    );

    reg [31:0] alu_srcA;
    reg [31:0] alu_srcB;

    always @(*) begin
    case(forwardA)

        2'b00:
            alu_srcA = id_ex_rd1;

        2'b01:
            alu_srcA = write_back_data;

        2'b10:
            alu_srcA = ex_mem_alu_result;

        default:
            alu_srcA = id_ex_rd1;

    endcase
end
    always @(*) begin
    case(forwardB)

        2'b00:
            alu_srcB = id_ex_rd2;

        2'b01:
            alu_srcB = write_back_data;

        2'b10:
            alu_srcB = ex_mem_alu_result;

        default:
            alu_srcB = id_ex_rd2;

    endcase
end

    wire [31:0] alu_in2;

    assign alu_in2=(id_ex_ALUSrc) ? id_ex_imm:alu_srcB;

    alu alu_inst (
        .a(alu_srcA),
        .b(alu_in2),
        .alu_ctrl(ALUControl),
        .result(alu_result),
        .zero(zero)
    );

    ex_mem ex_mem_reg (
        .clk(clk),
        .rst(rst),
        .alu_result_in(alu_result),
        .zero_in(zero),
        .rd2_in(alu_srcB),
        .rd_in(id_ex_rd),
        .RegWrite_in(id_ex_RegWrite),
        .MemRead_in(id_ex_MemRead),
        .MemWrite_in(id_ex_MemWrite),
        .MemToReg_in(id_ex_MemToReg),
        .Branch_in(id_ex_Branch),
        .Jump_in(id_ex_Jump),
        .alu_result_out(ex_mem_alu_result),
        .zero_out(),
        .rd2_out(ex_mem_rd2),
        .rd_out(ex_mem_rd),
        .RegWrite_out(ex_mem_RegWrite),
        .MemRead_out(ex_mem_MemRead),
        .MemWrite_out(ex_mem_MemWrite),
        .MemToReg_out(ex_mem_MemToReg),
        .Branch_out(),
        .Jump_out()
    );

    assign branch_target = id_ex_pc + id_ex_imm;

    branch_unit br_unit(

    .rs1(alu_srcA),
    .rs2(alu_srcB),

    .funct3(id_ex_funct3),

    .branch_taken(branch_taken)

    );

    
    assign flush = id_ex_Branch && branch_taken;

    // =========================
    // MEM STAGE
    // =========================

    wire [31:0] mem_read_data;

    data_mem dmem (
        .clk(clk),
        .MemRead(ex_mem_MemRead),
        .MemWrite(ex_mem_MemWrite),
        .addr(ex_mem_alu_result),
        .write_data(ex_mem_rd2),
        .read_data(mem_read_data)
    );

    mem_wb mem_wb_reg (
        .clk(clk),
        .rst(rst),
        .mem_data_in(mem_read_data),
        .alu_result_in(ex_mem_alu_result),
        .rd_in(ex_mem_rd),
        .RegWrite_in(ex_mem_RegWrite),
        .MemToReg_in(ex_mem_MemToReg),
        .mem_data_out(mem_wb_mem_data),
        .alu_result_out(mem_wb_alu_result),
        .rd_out(mem_wb_rd),
        .RegWrite_out(mem_wb_RegWrite),
        .MemToReg_out(mem_wb_MemToReg)
    );

    // =========================
    // WB STAGE
    // =========================

    assign write_back_data =
        (mem_wb_MemToReg) ?
            mem_wb_mem_data :
            mem_wb_alu_result;

    
endmodule
