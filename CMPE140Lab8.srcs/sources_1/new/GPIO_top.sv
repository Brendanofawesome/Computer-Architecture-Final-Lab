module GPIO_top (
    input  logic clk,
    input  logic rst_n,

    memory_bus_if       membus_gpio1,
    input  logic [3:2]  memory_address_gpio1,

    memory_bus_if       membus_gpio2,
    input  logic [3:2]  memory_address_gpio2,

    output      [31:0]  gpio_outputs1,
    input       [31:0]  gpio_inputs1,
    output      [31:0]  gpio_oe1,

    output      [31:0]  gpio_outputs2,
    input       [31:0]  gpio_inputs2,
    output      [31:0]  gpio_oe2
);

    io_unit gpio1_unit(
        .clk     (clk),
        .rst_n   (rst_n),
        .bus     (membus_gpio1.Peripheral),
        .address (memory_address_gpio1),
        .output_pins(gpio_outputs1),
        .input_pins(gpio_inputs1),
        .oe      (gpio_oe1)
    );

    io_unit gpio2_unit(
        .clk     (clk),
        .rst_n   (rst_n),
        .bus     (membus_gpio2.Peripheral),
        .address (memory_address_gpio2),
        .output_pins(gpio_outputs2),
        .input_pins(gpio_inputs2),
        .oe      (gpio_oe2)
    );

endmodule
