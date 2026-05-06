
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

    // Initialize registers to 0
    initial begin
        for (int i = 0; i < 32; i++) registers[i] = 32'b0;
    end

    // Synchronous write
    always_ff @(posedge clk) begin
        if (write_en_i && (write_addr_i != 5'b0)) begin
            registers[write_addr_i] <= write_data_i;
        end
    end

    // Asynchronous read
    // If RAW, return the new value. Reads of $0 always return 0.
    always_comb begin
        if (read_addr1_i == 5'b0)
            d1_o = 32'b0;
        else if (write_en_i && (write_addr_i != 5'b0) && (write_addr_i == read_addr1_i))
            d1_o = write_data_i;
        else
            d1_o = registers[read_addr1_i];

        if (read_addr2_i == 5'b0)
            d2_o = 32'b0;
        else if (write_en_i && (write_addr_i != 5'b0) && (write_addr_i == read_addr2_i))
            d2_o = write_data_i;
        else
            d2_o = registers[read_addr2_i];
    end

endmodule
