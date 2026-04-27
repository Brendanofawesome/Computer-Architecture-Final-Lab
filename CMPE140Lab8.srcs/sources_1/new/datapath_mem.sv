module datapath_mem (
    input logic         reg_wr_en_i,
    input logic [4:0]   reg_dst_i,
    input logic [31:0]  ALU_data_i,
    input logic [31:0]  reg_d2,
    input logic         mem_se,
    input logic         mem_type,
    input logic         mem_dir,
    input logic         mem_en,

    output logic        reg_wr_en,
    output logic [4:0]  reg_dst,
    output logic [31:0] ALU_data,
    output logic [31:0] mem_data,
    output logic [31:0] mem_bus_o     
);

    assign reg_wr_en = reg_wr_en_i;
    assign reg_dst = reg_dst_i;
    assign ALU_data = ALU_data_i;

endmodule