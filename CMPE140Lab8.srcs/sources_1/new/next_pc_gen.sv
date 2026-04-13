//calculates the next PC based on jump flags
//  module is completely combinatorial


module next_pc_gen(
    //unconditional absolute jump to immediate
    input logic [25:0] imm_addr_i,
    input logic id_jump_i,

    //ex stage jump trigger
    input logic ex_j_type_i, //1 == offset type, 0 == register type
    input logic ex_jump_i,

    //conditional jump to offset address
    input logic [31:2] bta_i,

    //jump to absolute register address
    input logic [31:0] ra_i,

    //PC
    input logic [31:0] PC_i,
    output logic [31:0] nPC_o
    );

    /////////////////////
    // next PC sources //
    /////////////////////
        logic [31:2] PC_plus_4;
        logic [31:2] PC_j_type_address;
        logic [31:2] PC_register_address;
        logic [31:2] PC_branch_address;

    /////////////////////////////
    // shift next PC in output //
    /////////////////////////////
    logic [31:2] selected_nPC;
    assign nPC_o = {selected_nPC, 2'b00};

    ///////////////////////////
    // select next PC source //
    ///////////////////////////
        always_comb begin : PC_Priority
            if (ex_jump_i == 1)
                selected_nPC = ex_j_type_i ? PC_branch_address : PC_register_address;
            else if (id_jump_i == 1)
                selected_nPC = PC_j_type_address;
            else
                selected_nPC = PC_plus_4;
        end

    //////////////////////
    // calculate PC + 4 //
    //////////////////////
        assign PC_plus_4 = PC_i[31:2] + 1;

    ///////////////////////////
    // calculate J-type addr //
    ///////////////////////////
        //*NOTE*    the PC used here is PC+4 relative to the j-type
        //          instruction's address because it is one stage
        //          further in the pipeline
        assign PC_j_type_address = {PC_i[31:28], imm_addr_i};

    ////////////////////////////////
    // calculate register address //
    ////////////////////////////////
        assign PC_register_address = ra_i[31:2];

    //////////////////////////////
    // calculate branch address //
    //////////////////////////////
        assign PC_branch_address = bta_i;
endmodule
