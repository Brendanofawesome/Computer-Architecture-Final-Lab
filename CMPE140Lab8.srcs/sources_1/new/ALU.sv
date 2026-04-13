//implements the MIPS ALU
//  unit is entirely combinatorial

import shared_definitions_pkg::alu_opcodes_e; //opcodes

module ALU(
    //control
    input alu_opcodes_e opcode_i,
    input logic [4:0] shamt_i,

    //data input
    input logic [31:0] data1_i,
    input logic [31:0] data2_i,

    //data output
    output logic [31:0] data_o,
    output logic [31:0] data_hi_o,
    output logic zero_o
    );

    //constant zero assignment
    assign zero_o = !(|data_o);

    always_comb begin : ALU_DECODE
        unique case(opcode_i)
            ALU_SLL:    data_o = data2_i << shamt_i;
            ALU_SRL:    data_o = data2_i >> shamt_i;
            ALU_SRA:    data_o = data1_i >>> shamt_i;
            ALU_ADD:    data_o = data1_i + data2_i;
            ALU_ADDU:   data_o = data1_i + data2_i;
            ALU_SUB:    data_o = $signed(data1_i) - $signed(data2_i);
            ALU_SUBU:   data_o = data1_i - data2_i;
            ALU_AND:    data_o = data1_i & data2_i;
            ALU_OR:     data_o = data1_i | data2_i;
            ALU_XOR:    data_o = data1_i ^ data2_i;
            ALU_NOR:    data_o = ~(data1_i | data2_i);
            ALU_LU:     data_o = data2_i << 16 | data1_i[15:0];
        endcase
    end
endmodule
