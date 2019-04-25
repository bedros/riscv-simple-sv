// RISC-V SiMPLE SV -- data path
// BSD 3-Clause License
// (c) 2017-2019, Arthur Matos, Marcus Vinicius Lamar, Universidade de Brasília,
//                Marek Materzok, University of Wrocław


`ifndef CONFIG_AND_CONSTANTS
    `include "config.sv"
`endif

module singlecycle_datapath (
    input  clock,
    input  reset,

    input  [31:0] data_mem_data_fetched,
    output [31:0] data_mem_address,
    output [31:0] data_mem_write_data,

    input  [31:0] immediate,
    input  [4:0]  inst_rd,
    input  [4:0]  inst_rs1,
    input  [4:0]  inst_rs2,
    output [31:0] pc,

    output alu_result_equal_zero,
    
    // control signals
    input pc_write_enable,
    input regfile_write_enable,
    input alu_operand_a_select,
    input alu_operand_b_select,
    input [2:0] reg_writeback_select,
    input [1:0] next_pc_select,
    input [4:0] alu_function
);

    // register file inputs and outputs
    logic [31:0] rd_data;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    
    // program counter signals
    logic [31:0] pc_plus_4;
    logic [31:0] pc_plus_immediate;
    logic [31:0] next_pc;
    
    // ALU signals
    logic [31:0] alu_operand_a;
    logic [31:0] alu_operand_b;
    logic [31:0] alu_result;
    
    // memory signals
    assign data_mem_address     = alu_result;
    assign data_mem_write_data  = rs2_data;
    
    adder #(
        .WIDTH(32)
    ) adder_pc_plus_4 (
        .operand_a      (32'h00000004),
        .operand_b      (pc),
        .result         (pc_plus_4)
    );
    
    adder #(
       .WIDTH(32)
    ) adder_pc_plus_immediate (
        .operand_a      (pc),
        .operand_b      (immediate),
        .result         (pc_plus_immediate)
    );
    
    alu alu(
        .alu_function       (alu_function),
        .operand_a          (alu_operand_a),
        .operand_b          (alu_operand_b),
        .result             (alu_result),
        .result_equal_zero  (alu_result_equal_zero)
    );
    
    multiplexer4 #(
        .WIDTH(32)
    ) mux_next_pc_select (
        .in0 (pc_plus_4),
        .in1 (pc_plus_immediate),
        .in2 ({alu_result[31:1], 1'b0}),
        .in3 (32'b0),
        .sel (next_pc_select),
        .out (next_pc)
    );
    
    multiplexer2 #(
        .WIDTH(32)
    ) mux_operand_a (
        .in0 (rs1_data),
        .in1 (pc),
        .sel (alu_operand_a_select),
        .out (alu_operand_a)
    );
    
    multiplexer2 #(
        .WIDTH(32)
    ) mux_operand_b (
        .in0 (rs2_data),
        .in1 (immediate),
        .sel (alu_operand_b_select),
        .out (alu_operand_b)
    );
    
    multiplexer8 #(
        .WIDTH(32)
    ) mux_reg_writeback (
        .in0 (alu_result),
        .in1 (data_mem_data_fetched),
        .in2 (pc_plus_4),
        .in3 (immediate),
        .in4 (32'b0),
        .in5 (32'b0),
        .in6 (32'b0),
        .in7 (32'b0),
        .sel (reg_writeback_select),
        .out (rd_data)
    );
    
    program_counter program_counter(
        .clock              (clock),
        .reset              (reset),
        .write_enable       (pc_write_enable),
        .next_pc            (next_pc),
        .pc                 (pc)
    );
    
    regfile regfile(
        .clock              (clock),
        .reset              (reset),
        .write_enable       (regfile_write_enable),
        .rd_address         (inst_rd),
        .rs1_address        (inst_rs1),
        .rs2_address        (inst_rs2),
        .rd_data            (rd_data),
        .rs1_data           (rs1_data),
        .rs2_data           (rs2_data)
    );

endmodule

