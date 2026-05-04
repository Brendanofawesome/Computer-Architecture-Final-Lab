//instruction fetch

module datapath_if(
    input [31:2] address_i,
    output [31:2] instr_o
);

reg [5:0] imem [32];

initial begin
    $readmemh("mipstest.bin", imem);
end

assign instr_o = imem[address_i];

endmodule
