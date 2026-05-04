//turns instruction function into control signals

import shared_definitions_pkg::*;

module ctrl_decoder(
    //decoded function signal
    input instruction_function_e function_i,
    input instruction_format_e format_i,

    //EX signals
    output logic mfsel_o, //selects HI/LO reg
    output logic mfrd_o, //read from selection

    output logic branch_inv_o, //invert branch equal
    output logic branch_o, //signals a branch instruction
    output logic jr_o, //signals a jr instruction

    output logic imm_sel_o, //selects immediate data instead of reg2
    output alu_opcodes_e alu_op_o, //selects alu operation

    output divmul_function_e div_mul_op_o, //selects the divmul op
    output logic divmul_start_o,
    output logic divmul_signmode_o,

    //MEM signals
    output logic mem_en_o,          //memory access enable
    output logic mem_dir_o,         //1 = write, 0 = read
    output logic [1:0] mem_type_o,  //00 = byte, 01 = halfword, 10 = word
    output logic mem_se_o,          //sign-extend
    output logic mem_to_reg_o,      //WB mux: 1 = load from memory, 0 = ALU result

    output logic reg_write_en_o, //enables register write

    //ID internal signals
    output logic jump_trig_o, //triggers an unconditional jump
    output logic jal_trig_o, //triggers a JAL

    output logic is_I_type_o //signals an I-type instruction
    );

    //EX-stage jumps
    assign branch_inv_o = function_i == BNE;
    assign branch_o = function_i == BNE || function_i == BEQ;
    assign jr_o = function_i == JR;

    //alu control
    assign imm_sel_o = (format_i == FORMAT_INSTR_I) && !branch_o;
    always_comb begin : ALU_OP_SEL
        unique case(function_i)
            SLL:    alu_op_o = ALU_SLL;
            SRL:    alu_op_o = ALU_SRL;
            SRA:    alu_op_o = ALU_SRA;

            ADD,
            ADDU,
            LB,
            LBU,
            LH,
            LHU,
            LW,
            SB,
            SH,
            SW:     alu_op_o = ALU_ADD;

            SUB,
            SUBU: alu_op_o = ALU_SUB;

            AND:    alu_op_o = ALU_AND;
            OR:     alu_op_o = ALU_OR;
            XOR:    alu_op_o = ALU_XOR;
            NOR:    alu_op_o = ALU_NOR;
            LUI:    alu_op_o = ALU_LU;

            SLT,
            SLTU:   alu_op_o = ALU_SLT;

            default: alu_op_o = ALU_ADD;
        endcase
    end

    //divmul control
    always_comb begin : DIVMUL_CTRL
        div_mul_op_o      = DIVMUL_MULT;
        divmul_start_o    = 0;
        divmul_signmode_o = 0;
        mfsel_o           = 0;
        mfrd_o            = 0;

        case (function_i)
            //divmul unit control
            MULT:
                begin
                    div_mul_op_o = DIVMUL_MULT;
                    divmul_start_o = 1;
                    divmul_signmode_o = 1;
                end
            MULTU:
                begin
                    div_mul_op_o = DIVMUL_MULT;
                    divmul_start_o = 1;
                    divmul_signmode_o = 0;
                end
            DIV:
                begin
                    div_mul_op_o = DIVMUL_DIV;
                    divmul_start_o = 1;
                    divmul_signmode_o = 1;
                end
            DIVU:
                begin
                    div_mul_op_o = DIVMUL_DIV;
                    divmul_start_o = 1;
                    divmul_signmode_o = 0;
                end

            //special register access
            MFHI:
                begin
                    mfsel_o = 0;
                    mfrd_o = 1;
                end
            MFLO:
                begin
                    mfsel_o = 1;
                    mfrd_o = 1;
                end

            default: ;
        endcase
    end

    //memory control
    always_comb begin : MEM_CTRL
        mem_en_o    = 0;
        mem_dir_o   = 0;
        mem_type_o  = 2'b10; //word
        mem_se_o    = 0;
        mem_to_reg_o = 0;

        case (function_i)
            LB:  begin mem_en_o = 1; mem_dir_o = 0; mem_type_o = 2'b00; mem_se_o = 1; mem_to_reg_o = 1; end
            LBU: begin mem_en_o = 1; mem_dir_o = 0; mem_type_o = 2'b00; mem_se_o = 0; mem_to_reg_o = 1; end
            LH:  begin mem_en_o = 1; mem_dir_o = 0; mem_type_o = 2'b01; mem_se_o = 1; mem_to_reg_o = 1; end
            LHU: begin mem_en_o = 1; mem_dir_o = 0; mem_type_o = 2'b01; mem_se_o = 0; mem_to_reg_o = 1; end
            LW:  begin mem_en_o = 1; mem_dir_o = 0; mem_type_o = 2'b10; mem_se_o = 0; mem_to_reg_o = 1; end
            SB:  begin mem_en_o = 1; mem_dir_o = 1; mem_type_o = 2'b00; end
            SH:  begin mem_en_o = 1; mem_dir_o = 1; mem_type_o = 2'b01; end
            SW:  begin mem_en_o = 1; mem_dir_o = 1; mem_type_o = 2'b10; end
            default: ;
        endcase
    end

    //register write enable
    always_comb begin : REG_WR_EN_CTRL
        case (function_i)
            //write to register
            ADD, ADDU,
            AND, OR, XOR, NOR,
            SLL, SRL, SRA,
            SLT, SLTU,
            LUI,
            LB, LBU, LH, LHU, LW,
            MFHI, MFLO,
            JAL:    reg_write_en_o = 1;

            //everything else 
            default: reg_write_en_o = 0;
        endcase
    end

endmodule
