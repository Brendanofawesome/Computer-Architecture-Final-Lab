module io_unit(
    input clk,
    input rst_n,

    memory_bus_if.Peripheral bus,
    input logic [1:0] address,

    inout tri [31:0] pins
    );

    logic [31:0] input_registers;
    logic [31:0] output_registers;
    logic [31:0] gpio_direction;

    // register the io pins
    always_ff @(posedge clk) begin : read_gpio
        if(!rst_n) input_registers <= '0;
        else input_registers <= pins;
    end

    // output to pins when requested
    genvar i;
    generate
        for (i = 0; i < 32; i++) begin : g_drive_gpio
            assign pins[i] = (!rst_n) ? 1'bz :
                            (gpio_direction[i] ? output_registers[i] : 1'bz);
        end
    endgenerate

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
                    if(bus.write_enable) gpio_direction <= bus.data_in;
                    bus.data_out <= gpio_direction;
                end

                //reg 1 is GPIO_OUT
                (2'd1):    begin
                    if(bus.write_enable) output_registers <= bus.data_in;
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
