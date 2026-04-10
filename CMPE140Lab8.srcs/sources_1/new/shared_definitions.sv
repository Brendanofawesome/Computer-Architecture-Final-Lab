//defines the list of shared definitions that can be used by all modules

package shared_definitions_pkg;
    ////////////////
    // ENUM TYPES //
    ////////////////

    //instruction format codes
    typedef enum {INSTR_I_FORMAT, INSTR_J_FORMAT, INSTR_R_FORMAT} instruction_format_e;

    //ALU opcodes
    typedef enum {
        ALU_SLL, ALU_SRL, ALU_SRA,                  //shifts
        ALU_ADD, ALU_ADDU, ALU_SUB, ALU_SUBU,       //arithmetics
        ALU_AND, ALU_OR, ALU_XOR, ALU_NOR, ALU_LU   //logic
    } alu_opcodes_e;
endpackage
