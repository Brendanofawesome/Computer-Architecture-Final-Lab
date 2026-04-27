module mips_fpga (
        input  wire         clk,
        input  wire         rst,
        inout  wire [15:0]  switches,
        inout wire  [2:0]   buttons,
        inout wire  [15:0]  LED,
        inout wire  [3:0]   LEDSEL,
        inout wire  [7:0]   LEDOUT
    );

    //clk generatoin
    wire        clk_sec;
    wire        clk_5KHz;

    clk_gen clk_gen (
        .clk100MHz          (clk),
        .rst                (rst),
        .clk_sec            (clk_sec),
        .clk_5KHz           (clk_5KHz)
    );

    //clk debouncing
    wire clk_db;
    button_debouncer clk_db (
            .clk                (clk_5KHz),
            .button             (clk),
            .debounced_button   (clk_db)
        );

    //reset signal
    wire rst_db;
    button_debouncer rst_db (
            .clk                (clk_5KHz),
            .button             (rst),
            .debounced_button   (rst_db)
        );
    wire rst_n;
    assign rst_n = !rst_db;

    //assign IO1 to control the display
    inout [31:0] io1;
    wire [7:0]  digit0;
    wire [7:0]  digit1;
    wire [7:0]  digit2;
    wire [7:0]  digit3;
    assign {digit3, digit2, digit1, digit0} = io1;

    led_mux led_mux (
            .clk                (clk_5KHz),
            .rst                (rst),
            .LED3               (digit3),
            .LED2               (digit2),
            .LED1               (digit1),
            .LED0               (digit0),
            .LEDSEL             (LEDSEL),
            .LEDOUT             (LEDOUT)
        );

    //assign IO2 to use the switches and LEDs
    inout [31:0] io2;
    assign {LED, switches} = io2;


    logic [3:0] buttons_debounced;
    button_debouncer bd [3:0] (
            .clk                (clk_5KHz),
            .button             (buttons),
            .debounced_button   (buttons_debounced)
        );

    MIPS mips_top (
            .clk                (clk_db),
            .rst                (rst_n),

            .io1(io1),
            .io2(io2)
        );
endmodule
