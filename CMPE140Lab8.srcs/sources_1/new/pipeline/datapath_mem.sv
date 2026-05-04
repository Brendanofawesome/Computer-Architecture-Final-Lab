module datapath_mem (
    input logic clk,
    input logic rst_n,


    input logic         reg_wr_en_i,
    input logic [4:0]   reg_dst_i,
    input logic [31:0]  ALU_data_i,
    input logic [31:0]  reg_d2,

    input logic         mem_se,
    input logic         mem_type,
    input logic         mem_dir,
    input logic         mem_en,
    input logic         mem_to_reg,

    output logic        reg_wr_en,
    output logic [4:0]  reg_dst,
    output logic [31:0] reg_wr_data,

    memory_bus_if.Peripheral mem_bus,
    output logic [31:2] mem_address_o
);

    //register control signals
    logic         reg_wr_en_mem;
    logic [4:0]   reg_dst_mem;
    logic [31:0]  ALU_data_mem;
    logic [31:0]  reg_d2_mem;
    logic         mem_se_mem;
    logic         mem_type_mem;
    logic         mem_dir_mem;
    logic         mem_en_mem;
    logic         mem_to_reg_mem;

    always_ff @( posedge clk ) begin : EX_MEM_REG
        if (!rst_n) begin
            reg_wr_en_mem <= 1'b0;
            reg_dst_mem <= '0;
            ALU_data_mem <= '0;
            reg_d2_mem <= '0;
            mem_se_mem <= 1'b0;
            mem_type_mem <= 1'b0;
            mem_dir_mem <= 1'b0;
            mem_en_mem <= 1'b0;
            mem_to_reg_mem <= 1'b0;
        end else begin
            reg_wr_en_mem <= reg_wr_en_i;
            reg_dst_mem <= reg_dst_i;
            ALU_data_mem <= ALU_data_i;
            reg_d2_mem <= reg_d2;
            mem_se_mem <= mem_se;
            mem_type_mem <= mem_type;
            mem_dir_mem <= mem_dir;
            mem_en_mem <= mem_en;
            mem_to_reg_mem <= mem_to_reg;
        end
    end

    logic [31:0] mem_data_o;

    memory_controller mem_controller(
        .address_i (ALU_data_mem),
        .data_i (reg_d2_mem),

        .sign_extend_i(mem_se_mem),
        .data_type_i(mem_type_mem),
        .data_dir_i(mem_dir_mem),
        .en_i(mem_en_mem),

        .data_o(mem_data_o),
        .membus_o(mem_bus),
        .address_o(mem_address_o)
    );

    mux2to1 #(.WIDTH(32)) mem_mux(
        .a(ALU_data_mem),
        .b(mem_controller.data_out),
        .sel(mem_to_reg_mem),
        .y(reg_wr_data)
    );


    //passthrough
    assign reg_wr_en = reg_wr_en_mem;
    assign reg_dst    = reg_dst_mem;
endmodule
