module memory_controller(
    input logic [31:0] address_i,
    input logic [31:0] data_i,
    input logic        sign_extend_i,
    input logic        data_type_i,
    input logic        data_dir_i,
    input logic        en_i,

    output logic [31:0] data_o,
    output logic [31:0] membus
    );

endmodule