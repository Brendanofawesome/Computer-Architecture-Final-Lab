//turns instruction function into control signals

import shared_definitions_pkg::*;

module ctrl_decoder(
    //decoded function signal
    input instruction_function_e function_i,
    input instruction_format_e format_i,

    //EX signals
    output logic mflo_o, //signals mflo instruction
    output logic mfhi_o, //signals mfhi instruction

    output logic branch_inv_o, //invert branch equal
    output logic branch_o, //signals a branch instruction
    output logic jr_o, //signals a jr instruction

    output logic imm_sel_o, //selects immediate data instead of reg2
    output alu_opcodes_e alu_op_o, //selects alu operation

    output logic reg_write_en_o, //enables register write

    //ID internal signals
    output logic jump_trig_o, //triggers an unconditional jump
    output logic is_I_type_o //rs is destination in I_type
    );

    //Special Register Access
    assign mflo_o = function_i == MFLO;
    assign mfhi_o = function_i == MFHI;

    //EX-stage jumps
    assign branch_inv_o = function_i == BNE;
    assign branch_o = function_i == BNE || function_i == BEQ;
    assign jr_o = function_i == JR;

    //alu control
    assign imm_sel_o = format_i == FORMAT_INSTR_I;
    always_comb begin : ALU_OP_SEL
        case(function_i)
        endcase
    end


endmodule
