module GPIO_top (
    input  logic clk,
    input  logic rst_n,

    memory_bus_if       membus_gpio1,
    input  logic [3:2]  memory_address_gpio1,

    memory_bus_if       membus_gpio2,
    input  logic [3:2]  memory_address_gpio2,

    tri         [31:0]  gpio_pins1,
    output      [31:0]  gpio_oe1,

    tri         [31:0]  gpio_pins2,
    output      [31:0]  gpio_oe2
);

    io_unit gpio1_unit(
        .clk     (clk),
        .rst_n   (rst_n),
        .bus     (membus_gpio1.Peripheral),
        .address (memory_address_gpio1),
        .pins    (gpio_pins1),
        .oe      (gpio_oe1)
    );

    io_unit gpio2_unit(
        .clk     (clk),
        .rst_n   (rst_n),
        .bus     (membus_gpio2.Peripheral),
        .address (memory_address_gpio2),
        .pins    (gpio_pins2),
        .oe      (gpio_oe2)
    );

endmodule
