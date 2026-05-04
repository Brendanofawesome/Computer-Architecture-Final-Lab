//defines the list of shared definitions that can be used by all modules

package shared_definitions_pkg;
    ////////////////
    // ENUM TYPES //
    ////////////////

    //instruction format codes
    typedef enum {FORMAT_INSTR_I, FORMAT_INSTR_J, FORMAT_INSTR_R} instruction_format_e;

    //ALU opcodes
    typedef enum {
        ALU_SLL, ALU_SRL, ALU_SRA,                  //shifts
        ALU_ADD, ALU_SLT, ALU_SLTU, ALU_SUB,        //arithmetics
        ALU_AND, ALU_OR, ALU_XOR, ALU_NOR, ALU_LU   //logic
    } alu_opcodes_e;

    //instruction functions
    typedef enum {
    ADD, ADDU, MULT, MULTU, DIV, DIVU,  //Arithmetic
    SUB, SUBU,                          //Subtractions
    AND, OR, XOR, NOR,                  //Logical
    SLL, SRL, SRA,                      //Shifts
    LB, LBU, LH, LHU, LW,               //Mem Load
    SB, SH, SW,                         //Mem Store
    LUI, MFHI, MFLO, MTHI, MTLO,        //Transfer
    BEQ, BNE,                           //Branch
    SLT, SLTU,                          //Comparison
    J, JR, JAL                          //Jump
    } instruction_function_e;

    //multdiv functions
    typedef enum {DIVMUL_MULT, DIVMUL_DIV} divmul_function_e;
endpackage
