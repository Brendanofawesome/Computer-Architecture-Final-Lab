module GPIO_top (
    input  logic clk,
    input  logic rst_n,

    memory_bus_if membus_gpio1,
    input  logic [3:2] memory_address_gpio1,

    memory_bus_if membus_gpio2,
    input  logic [3:2] memory_address_gpio2,

    inout  tri [31:0] gpio_pins1,
    inout  tri [31:0] gpio_pins2
);

    io_unit gpio1_unit(
        .clk     (clk),
        .rst_n   (rst_n),
        .bus     (membus_gpio1.Peripheral),
        .address (memory_address_gpio1),
        .pins    (gpio_pins1)
    );

    io_unit gpio2_unit(
        .clk     (clk),
        .rst_n   (rst_n),
        .bus     (membus_gpio2.Peripheral),
        .address (memory_address_gpio2),
        .pins    (gpio_pins2)
    );

endmodule
