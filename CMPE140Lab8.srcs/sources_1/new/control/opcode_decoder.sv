//determines the requested function of an instruction and splits arguments

//this module is entirely combinatorial

import shared_definitions_pkg::*; //import instruction types and functions

typedef enum bit [5:0] {
    //supported opcodes
    OPCODE_J        = 6'h2,
    OPCODE_JAL      = 6'h3,
    OPCODE_BEQ      = 6'h4,
    OPCODE_BNE      = 6'h5,
    OPCODE_ADDI     = 6'h8,
    OPCODE_ADDIU    = 6'h9,
    OPCODE_SLTI     = 6'h0A,
    OPCODE_SLTIU    = 6'h0B,
    OPCODE_ANDI     = 6'h0C,
    OPCODE_ORI      = 6'h0D,
    OPCODE_XORI     = 6'h0E,
    OPCODE_LUI      = 6'h0F,
    OPCODE_LB       = 6'h20,
    OPCODE_LH       = 6'h21,
    OPCODE_LW       = 6'h23,
    OPCODE_LBU      = 6'h24,
    OPCODE_LHU      = 6'h25,
    OPCODE_SB       = 6'h28,
    OPCODE_SH       = 6'h29,
    OPCODE_SW       = 6'h2B,

    //unsupported opcodes
    OPCODE_BLEZ     = 6'h6,
    OPCODE_BGTZ     = 6'h7,
    OPCODE_MFC0     = 6'h10
} opcodes_e;

typedef enum bit [5:0] {
    //supported functions
    FUNCT_SLL   = 6'h00,
    FUNCT_SRL   = 6'h02,
    FUNCT_SRA   = 6'h03,
    FUNCT_JR    = 6'h08,
    FUNCT_MFHI  = 6'h10,
    FUNCT_MFLO  = 6'h12,
    FUNCT_MULT  = 6'h18,
    FUNCT_MULTU = 6'h19,
    FUNCT_DIV   = 6'h1A,
    FUNCT_DIVU  = 6'h1B,
    FUNCT_ADD   = 6'h20,
    FUNCT_ADDU  = 6'h21,
    FUNCT_SUB   = 6'h22,
    FUNCT_SUBU  = 6'h23,
    FUNCT_AND   = 6'h24,
    FUNCT_OR    = 6'h25,
    FUNCT_XOR   = 6'h26,
    FUNCT_NOR   = 6'h27,
    FUCNT_SLT   = 6'h2A,
    FUNCT_SLTU  = 6'h2B,

    //unsupported functions
    FUNCT_JALR  = 6'h09
} functs_e;

module opcode_decoder(
    input logic [31:0]              instr_i,

    //shared control outputs
    output instruction_function_e   function_o,
    output instruction_format_e     format_o,
    output logic                    illegal_instr_o,

    //register fields
    output logic [4:0]              rs_o,       //I+R-type
    output logic [4:0]              rt_o,       //I+R-type
    output logic [4:0]              rd_o,       //  R-type

    //special fields
    output logic [15:0]             imm_o,      //  I-type
    output logic [25:0]             imm_addr_o, //  J-type
    output logic [4:0]              shamt_o     //  R-type
    );

    /////////////////////
    // SPLIT BITFIELDS //
    /////////////////////
        //assign register field outputs
        assign rs_o = instr_i[25:21];
        assign rt_o = instr_i[20:16];
        assign rd_o = instr_i[15:11];

        //assign special field outputs
        assign imm_o      = instr_i[15:0];
        assign imm_addr_o = instr_i[25:0];
        assign shamt_o    = instr_i[10:6];

        //assign internal fields
        wire [5:0] opcode, funct;
        assign opcode   = instr_i[31:26];
        assign funct    = instr_i[5:0];

    //////////////////////////////////
    // DETERMINE INSTRUCTION FORMAT //
    //////////////////////////////////
        always_comb begin : ID_FMT
            unique case(opcode)
                6'h00:          format_o = FORMAT_INSTR_R;
                6'h02, 6'h03:   format_o = FORMAT_INSTR_J;
                default:        format_o = FORMAT_INSTR_I;
            endcase
        end

    ////////////////////////////////////
    // DETERMINE INSTRUCTION FUNCTION //
    ////////////////////////////////////
        always_comb begin : ID_FNC
            // Defaults prevent inferred latches on unsupported/illegal encodings.
            illegal_instr_o = 1'b0;
            function_o = ADD;

            if(format_o == FORMAT_INSTR_R) begin
                unique case(funct)
                    FUNCT_SLL:  function_o = SLL;
                    FUNCT_SRL:  function_o = SRL;
                    FUNCT_SRA:  function_o = SRA;
                    FUNCT_JR:   function_o = JR;
                    FUNCT_MFHI: function_o = MFHI;
                    FUNCT_MFLO: function_o = MFLO;
                    FUNCT_MULT: function_o = MULT;
                    FUNCT_MULTU:function_o = MULTU;
                    FUNCT_DIV:  function_o = DIV;
                    FUNCT_DIVU: function_o = DIVU;
                    FUNCT_ADD : function_o = ADD;
                    FUNCT_ADDU: function_o = ADDU;
                    FUNCT_SUB : function_o = SUB;
                    FUNCT_SUBU: function_o = SUBU;
                    FUNCT_AND:  function_o = AND;
                    FUNCT_OR :  function_o = OR;
                    FUNCT_XOR:  function_o = XOR;
                    FUNCT_NOR:  function_o = NOR;
                    FUCNT_SLT:  function_o = SLT;
                    FUNCT_SLTU: function_o = SLTU;

                    default: begin
                        illegal_instr_o = '1;
                    end
                endcase
            end else if(format_o == FORMAT_INSTR_J) begin
                unique case(opcode)
                    6'h02:      function_o = J;
                    6'h03:      function_o = JAL;
                    default:    illegal_instr_o = 1'b1;
                endcase
            end else begin //I-type
                unique case(opcode)
                    OPCODE_BEQ:     function_o = BEQ;
                    OPCODE_BNE:     function_o = BNE;
                    OPCODE_ADDI:    function_o = ADD;
                    OPCODE_ADDIU:   function_o = ADDU;
                    OPCODE_SLTI:    function_o = SLT;
                    OPCODE_SLTIU:   function_o = SLTU;
                    OPCODE_ANDI:    function_o = AND;
                    OPCODE_ORI:     function_o = OR;
                    OPCODE_XORI:    function_o = XOR;
                    OPCODE_LUI:     function_o = LUI;
                    OPCODE_LB:      function_o = LB;
                    OPCODE_LH:      function_o = LH;
                    OPCODE_LW:      function_o = LW;
                    OPCODE_LBU:     function_o = LBU;
                    OPCODE_LHU:     function_o = LHU;
                    OPCODE_SB:      function_o = SB;
                    OPCODE_SH:      function_o = SH;
                    OPCODE_SW:      function_o = SW;

                    default:        illegal_instr_o = '1;
                endcase
            end
        end
endmodule
