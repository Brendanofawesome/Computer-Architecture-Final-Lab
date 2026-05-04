//datapath for the write_back stage

module datapath_wb(
    input clk,
    input rst_n,

    input logic reg_wr_en,
    input logic [4:0] reg_dst,

    input logic [31:0] data,

    output logic reg_wr_en_passback,
    output logic [4:0] reg_dst_passback,
    output logic [31:0] data_passback
);

//registers
always_ff @( posedge clk ) begin : EX_MEM_REG
    if(!rst_n) begin
        reg_wr_en_passback <= 0;
        reg_dst_passback <= '0;
        data_passback <= '0;
    end else begin
        reg_wr_en_passback <= reg_wr_en;
        reg_dst_passback <= reg_dst;
        data_passback <= data;
    end
end

endmodule
