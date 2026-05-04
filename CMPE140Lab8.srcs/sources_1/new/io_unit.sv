module io_unit(
    input logic clk,
    input logic rst_n,

    memory_bus_if.Peripheral bus,
    input logic [1:0] address,

    input logic [31:0] input_pins,
    output logic [31:0] output_pins,
    output logic [31:0] oe
    );

    logic [31:0] input_registers;
    logic [31:0] output_registers;
    logic [31:0] gpio_direction;
    assign oe = gpio_direction;

    // register the io pins
    always_ff @(posedge clk) begin : read_gpio
        if(!rst_n) input_registers <= '0;
        else input_registers <= input_pins;
    end

    //write to output
    always_comb begin : write_gpio
        output_pins = output_registers;
    end

    // respond to memory bus events
    always_ff @(posedge clk) begin : manage_bus
        if(!rst_n) begin
            bus.data_out <= '0;
            output_registers <= '0;
            gpio_direction <= '0;
        end
        else if(bus.select) begin //peripheral is selected
            case(address)
                //reg 0 is GPIO_DIRECTION
                (2'd0):    begin
                    if(bus.write_enable[0]) gpio_direction[7:0] <= bus.data_in[7:0];
                    if(bus.write_enable[1]) gpio_direction[15:8] <= bus.data_in[15:8];
                    if(bus.write_enable[2]) gpio_direction[23:16] <= bus.data_in[23:16];
                    if(bus.write_enable[3]) gpio_direction[31:24] <= bus.data_in[31:24];
                    bus.data_out <= gpio_direction;
                end

                //reg 1 is GPIO_OUT
                (2'd1):    begin
                    if(bus.write_enable[0]) output_registers[7:0] <= bus.data_in[7:0];
                    if(bus.write_enable[1]) output_registers[15:8] <= bus.data_in[15:8];
                    if(bus.write_enable[2]) output_registers[23:16] <= bus.data_in[23:16];
                    if(bus.write_enable[3]) output_registers[31:24] <= bus.data_in[31:24];
                    bus.data_out <= output_registers;
                end

                //reg 2 is GPIO_IN
                (2'd2):    begin
                    //read-only
                    bus.data_out <= input_registers;
                end

                default:
                    bus.data_out <= '0;
            endcase
        end
    end
endmodule
