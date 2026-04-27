module mips_fpga (
        input  wire         clk,
        input  wire         clk_b,
        input  wire         rst_b,
        tri          [15:0] switches,
        tri          [2:0]  buttons,
        tri          [15:0] LED,
        output wire  [3:0]  LEDSEL,
        output wire  [7:0]  LEDOUT
    );

    //clk generatoin
    wire        clk_sec;
    wire        clk_5KHz;

    clk_gen clk_gen (
        .clk100MHz          (clk),
        .rst                (rst_b),
        .clk_sec            (clk_sec),
        .clk_5KHz           (clk_5KHz)
    );

    //clk debouncing
    wire clk_db;
    button_debouncer clk_db (
            .clk                (clk_5KHz),
            .button             (clk_b),
            .debounced_button   (clk_db)
        );

    //reset signal
    wire rst_db;
    button_debouncer rst_db (
            .clk                (clk_5KHz),
            .button             (rst_b),
            .debounced_button   (rst_db)
        );
    wire rst_n;
    assign rst_n = !rst_db;

    //assign IO1 to control the display
    tri [31:0] io1;
    wire [31:0] io1_output_muxed;
    wire [31:0] oe1;

    genvar i;
    generate
        for(i = 0; i < 32; i = i + 1) begin
            assign io1_output_muxed[i] = oe1[i] ? io1[i] : 1'b0;
        end
    endgenerate

    wire [7:0]  digit0;
    wire [7:0]  digit1;
    wire [7:0]  digit2;
    wire [7:0]  digit3;
    assign {digit3, digit2, digit1, digit0} = io1_output_muxed;

    led_mux led_mux (
            .clk                (clk_5KHz),
            .rst                (rst_b),
            .LED3               (digit3),
            .LED2               (digit2),
            .LED1               (digit1),
            .LED0               (digit0),
            .LEDSEL             (LEDSEL),
            .LEDOUT             (LEDOUT)
        );

    logic [3:0] buttons_debounced;
    button_debouncer bd [3:0] (
            .clk                (clk_5KHz),
            .button             (buttons),
            .debounced_button   (buttons_debounced)
        );

    wire [31:0] oe2;
    MIPS mips_top (
            .clk                (clk_db),
            .rst                (rst_n),

            .io1(io1),
            .oe1(oe1),
            .io2({LED, switches}),
            .oe2(oe2)
        );
endmodule
