module datapath_mem (
    input logic clk,
    input logic rst_n,


    input logic         reg_wr_en_i,
    input logic [4:0]   reg_dst_i,
    input logic [31:0]  ALU_data_i,
    input logic [31:0]  reg_d2,

    input logic         mem_se,
    input logic [1:0]   mem_type,
    input logic         mem_dir,
    input logic         mem_en,
    input logic         mem_to_reg,

    output logic        reg_wr_en,
    output logic [4:0]  reg_dst,
    output logic [31:0] reg_wr_data,

    memory_bus_if.Controller mem_bus,
    output logic [31:2] mem_address_o
);

    //register passthrough signals
    logic           reg_wr_en_reg;
    logic [4:0]     reg_dst_reg;
    logic [31:0]    ALU_data_reg;
    logic           mem_to_reg_reg;
    always_ff @( posedge clk ) begin : EX_MEM_REG
        if (!rst_n) begin
            reg_wr_en_reg <= '0;
            reg_dst_reg <= '0;
            ALU_data_reg <= '0;
            mem_to_reg_reg <= '0;
        end else begin
            reg_wr_en_reg <= reg_wr_en_i;
            reg_dst_reg <= reg_dst_i;
            ALU_data_reg <= ALU_data_i;
            mem_to_reg_reg <= mem_to_reg;
        end
    end

    //passthrough
    assign reg_wr_en = reg_wr_en_reg;
    assign reg_dst   = reg_dst_reg;

    //note that some signals are already registered by the memory units
    // => we passthrough directly to avoid extra cycle latency

    logic [31:0] mem_data_o;

    memory_controller mem_controller(
        .clk(clk),
        .rst_n(rst_n),

        .address_i (ALU_data_i),
        .data_i (reg_d2),

        .sign_extend_i(mem_se),
        .data_type_i(mem_type),
        .data_dir_i(mem_dir),
        .en_i(mem_en),

        .data_o(mem_data_o),
        .membus_o(mem_bus),
        .address_o(mem_address_o)
    );

    mux2to1 #(.WIDTH(32)) mem_mux(
        .a(ALU_data_reg),
        .b(mem_data_o),
        .sel(mem_to_reg_reg),
        .y(reg_wr_data)
    );
endmodule
