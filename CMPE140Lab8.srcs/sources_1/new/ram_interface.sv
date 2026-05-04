module ram_interface #(parameter int WIDTH = 8)(
    input logic clk,
    input logic rst_n,

    memory_bus_if.Peripheral bus,
    input logic [WIDTH-1:2] address
    );

    localparam int DEPTH = 1 << (WIDTH - 2);
    logic [31:0] memory [0:DEPTH-1] = '{default:0};

    //handle writes
    always_ff @(posedge clk) begin
        if(bus.select && rst_n) begin
            if(bus.write_enable[0]) memory[address][7:0] <= bus.data_in[7:0];
            if(bus.write_enable[1]) memory[address][15:8] <= bus.data_in[15:8];
            if(bus.write_enable[2]) memory[address][23:16] <= bus.data_in[23:16];
            if(bus.write_enable[3]) memory[address][31:24] <= bus.data_in[31:24];
        end
    end

    //handle reads
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            bus.data_out <= '0;
        end else if(bus.select) begin
            bus.data_out <= memory[address];
        end
    end
endmodule
