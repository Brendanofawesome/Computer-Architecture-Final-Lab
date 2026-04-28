//implements instruction_decode step
import shared_definitions_pkg::*;

module instruction_decode(
        input logic [31:0] instr_i,
        input logic [31:2] pc_q,

        //output wires to ID-EX reg from opcode_decoder
        output logic [4:0] shamt_o,
        output logic [15:0] imm_o,
        output logic [4:0] rs_o,
        output logic [4:0] rt_o,
        output logic [25:0] imm_addr_o,

        //output wires to ID-EX reg from branch_precalc
        output logic [31:2] b_adder_o,

        //output wires to ID-EX reg from ctrl_decoder
        output logic mflo_o,
        output logic            mflo_o,
        output logic            mfhi_o,
        output logic            branch_inv_o,
        output logic            branch_o,
        output logic            jr_o,
        output logic            imm_sel_o,
        output alu_opcodes_e    alu_op_o,
        output logic            reg_write_en_o,
        output logic            jump_trig_o,

        //output wires to ID-EX reg from jal_dst_mux
        output logic [4:0] dst_o
);

        //internal wires
        instruction_function_e  function_w;
        instruction_format_e    format_w;
        logic                   illegal_instr_w;

        logic [4:0]             rs_w, rt_w, rd_w;
        logic [15:0]            imm_w;
        logic [25:0]            imm_addr_w;
        logic [4:0]             shamt_w;

        logic                   is_I_type_w;
        logic                   jal_trig_w;
        logic                   jump_trig_w;
        logic                   jr_w;

        logic [4:0]             i_type_dst_w;   // output of I_type_dst_mux

        opcode_decoder u_opcode_decoder(
                .instr_i (instr_i),

                .function_o (function_w),
                .format_o (format_w),
                .illegal_instr_o (illegal_instr_w),

                .rs_o (rs_w),
                .rt_o (rt_w),
                .rd_o (rd_w),

                .imm_o (imm_w),
                .imm_addr_o (imm_addr_w),
                .shamt_o (shamt_w)
        );

        branch_precalc u_branch_precalc(
                .src1 (pc_q),
                .src2 (imm_w),
                .q (b_adder_o)
        );

        ctrl_decoder u_ctrl_decoder(
                .function_i (function_w),
                .format_i (format_w),

                .mflo_o (mflo_o),
                .mfhi_o (mfhi_o),

                .branch_inv_o (branch_inv_o),
                .branch_o (branch_o),
                .jr_o (jr_o),

                .imm_sel_o (imm_sel_o),
                .alu_op_o (alu_op_o),

                .reg_write_en_o (reg_write_en_o),

                .jump_trig_o (jump_trig_o),
                .is_I_type_o (is_I_type_w),
                .jal_trig_o (jal_trig_w) //signal needs to be added in the ctrl_decoder module
        );

        // i_type_dst_mux output select
        assign i_type_dst_w = is_i_type_w ? rs_w : rd_w;

        // jal_dst_mux outpu select
        assign dst_o = jal_trig_w ? 5'd31 : i_type_dst_w;

        //output assignments 
        assign shamt_o = shamt_w;
        assign imm_o = imm_w;
        assign imm_addr_o = imm_addr_w;
        assign rs_o = rs_w;
        assign rt_o = rt_w;
        assign jr_o = jr_w;
        assign jal_trig_o = jal_trig_w;
        assign jump_trig_o = jump_trig_w;

        // illegal instruction
        assign decode_err_o     = illegal_instr_w;
endmodule 


