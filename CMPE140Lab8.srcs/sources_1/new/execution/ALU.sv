//implements the MIPS ALU
//  unit is entirely combinatorial

import shared_definitions_pkg::*; //opcodes

module ALU(
    //control
    input alu_opcodes_e opcode_i,
    input logic [4:0] shamt_i,

    //data input
    input logic [31:0] data1_i,
    input logic [31:0] data2_i,

    //data output
    output logic [31:0] data_o
    );

    always_comb begin : ALU_DECODE
        unique case(opcode_i)
            ALU_SLL:    data_o = data2_i << shamt_i;
            ALU_SRL:    data_o = data2_i >> shamt_i;
            ALU_SRA:    data_o = data1_i >>> shamt_i;
            ALU_ADD:    data_o = data1_i + data2_i;
            ALU_AND:    data_o = data1_i & data2_i;
            ALU_OR:     data_o = data1_i | data2_i;
            ALU_XOR:    data_o = data1_i ^ data2_i;
            ALU_NOR:    data_o = ~(data1_i | data2_i);
            ALU_LU:     data_o = data2_i << 16 | data1_i[15:0];
            ALU_SLT:    data_o = {{31{1'b0}}, ($signed(data1_i) < $signed(data2_i))};
            ALU_SLTU:   data_o = {{31{1'b0}}, ($unsigned(data1_i) < $unsigned(data2_i))};
        endcase
    end
endmodule
