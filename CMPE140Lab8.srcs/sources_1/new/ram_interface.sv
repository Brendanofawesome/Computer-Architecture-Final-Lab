module ram_interface #(parameter int WIDTH = 8)(
    input logic clk,
    input logic rst_n,

    memory_bus_if.Peripheral bus,
    input logic [WIDTH-1:2] address
    );

    localparam int DEPTH = 1 << (WIDTH - 2);
    logic [31:0] memory [DEPTH-1];

    //handle writes
    always_ff @(posedge clk) begin
        if(bus.select && bus.write_enable && rst_n) begin
            memory[address] <= bus.data_in;
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
