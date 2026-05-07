// instruction fetch

module datapath_if #(
    parameter int IMEM_ADDR_BITS = 10,
    parameter string IMEM_INIT_FILE = "mipsblink.hex"
)(
    input  logic [31:2] address_i,
    output logic [31:0] instr_o
);

    localparam int IMEM_DEPTH = 1 << IMEM_ADDR_BITS;

    // 32-bit instruction ROM.  The old code used 6-bit words, so almost every
    // fetched instruction was truncated to {26'b0, funct}, which made the CPU
    // behave like it was executing mostly zeros/NOPs and let synthesis remove it.
    logic [31:0] imem [0:IMEM_DEPTH-1];

    initial begin
        for (int i = 0; i < IMEM_DEPTH; i++) begin
            imem[i] = 32'h0000_0000;
        end
        $readmemh(IMEM_INIT_FILE, imem);
    end

    logic address_in_range;
    generate
        if (IMEM_ADDR_BITS < 30) begin : g_address_range_check
            assign address_in_range = (address_i[31:IMEM_ADDR_BITS+2] == '0);
        end else begin : g_no_address_range_check
            assign address_in_range = 1'b1;
        end
    endgenerate

    assign instr_o = address_in_range ? imem[address_i[IMEM_ADDR_BITS+1:2]] : 32'h0000_0000;
endmodule
