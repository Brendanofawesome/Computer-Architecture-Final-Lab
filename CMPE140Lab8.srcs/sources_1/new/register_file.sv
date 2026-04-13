
import shared_definitions_pkg::*;

module register_file (
    input  logic        clk,
    input  logic [4:0]  read_addr1_i,   // rs[4:0]
    input  logic [4:0]  read_addr2_i,   // rt[4:0]
    input  logic [31:0] write_data_i,   // from WB_PASSBACK
    input  logic [4:0]  write_addr_i,   // from WB_PASSBACK
    input  logic        write_en_i,     // from WB_PASSBACK
    output logic [31:0] d1_o,           // read data 1
    output logic [31:0] d2_o            // read data 2
);

    // 32 registers, each 32 bits wide
    logic [31:0] registers [31:0];

    // Initialize $zero to always be 0
    initial begin
        registers[0] = 32'b0;
    end

    // Synchronous write
    always_ff @(posedge clk) begin
        if (write_en_i && write_addr_i != 5'b0) begin
            registers[write_addr_i] <= write_data_i;
        end
    end

    // Asynchronous read
    assign d1_o = registers[read_addr1_i];
    assign d2_o = registers[read_addr2_i];

endmodule