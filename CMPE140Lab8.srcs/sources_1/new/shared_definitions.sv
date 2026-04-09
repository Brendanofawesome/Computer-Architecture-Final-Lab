//defines the list of shared definitions that can be used by all modules

package shared_definitions_pkg;
    ////////////////
    // ENUM TYPES //
    ////////////////

    //instruction format codes
    typedef enum {INSTR_I_FORMAT, INSTR_J_FORMAT, INSTR_R_FORMAT} instruction_format_e;

    //instruction functions
    typedef enum {
    ADD, ADDU, MULT, DIV,               //Arithmetic
    AND, OR, XOR, NOR,                  //Logical
    SLL, SRL, SRA,                      //Shifts
    LB, LBU, LH, LHU, LW,               //Mem Load
    SB, SH, SW,                         //Mem Store
    LUI, MFHI, MFLO, MTHI, MTLO,        //Transfer
    BEQ, BNE,                           //Branch
    SLT, SLTI,                          //Comparison
    J, JR, JAL                          //Jump
    } instruction_function_e;

    //multdiv functions
    typedef enum {divmul_MULT, divmul_DIV} divmul_function_e;
endpackage
