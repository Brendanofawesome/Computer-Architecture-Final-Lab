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
    output logic        zero_o
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
            ALU_LU:     data_o = {data2_i[15:0], 16'b0};
            ALU_SLT:    data_o = {{31'b0}, ($signed(data1_i) < $signed(data2_i))};
            ALU_SLTU:   data_o = {{31'b0}, ($unsigned(data1_i) < $unsigned(data2_i))};
            default:    data_o = 0;
        endcase
    end

    assign zero_o = (data_o == 32'b0);
endmodule
