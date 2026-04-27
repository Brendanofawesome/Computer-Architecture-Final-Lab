module io_buffer(
    inout pin,

    output gpio_input,
    input gpio_output,
    input gpio_oe
    );

    assign pin = gpio_oe ? gpio_output : 1'bz;

    assign gpio_input = pin;
endmodule
