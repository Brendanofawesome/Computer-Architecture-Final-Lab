module mips_fpga (
        input  wire         clk,
        input  wire         clk_b,
        input  wire         rst_b,
        inout        [15:0] switches,
        inout        [2:0]  buttons,
        inout        [15:0] LED,
        output wire  [3:0]  LEDSEL,
        output wire  [7:0]  LEDOUT
    );

    //clk generatoin
    wire        clk_5KHz;

    clk_gen clk_gen (
        .clk100MHz          (clk),
        .rst                (rst_b),
        .clk_sec            (),
        .clk_5KHz           (clk_5KHz)
    );

    //clk debouncing
    wire clk_db;
    button_debouncer clk_db_inst (
            .clk                (clk_5KHz),
            .button             (clk_b),
            .debounced_button   (clk_db)
        );

    //reset signal
    wire rst_db;
    button_debouncer rst_db_inst (
            .clk                (clk_5KHz),
            .button             (rst_b),
            .debounced_button   (rst_db)
        );
    wire rst_n;
    assign rst_n = !rst_db;

    //assign IO1 to control the display
    wire [31:0] io1_output;
    wire [31:0] io1_input;
    wire [31:0] oe1;
    assign io1_input = '0;

    wire [31:0] io1_output_muxed;

    genvar i;
    generate
        for(i = 0; i < 32; i = i + 1) begin : g_7Seg_Signals
            assign io1_output_muxed[i] = oe1[i] ? io1_output[i] : 1'b0;
        end
    endgenerate

    wire [7:0]  digit0;
    wire [7:0]  digit1;
    wire [7:0]  digit2;
    wire [7:0]  digit3;
    assign {digit3, digit2, digit1, digit0} = ~io1_output_muxed;

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

    //debounce the button inputs
    logic [2:0] buttons_debounced;
    button_debouncer bd [2:0] (
            .clk                (clk_5KHz),
            .button             (buttons),
            .debounced_button   (buttons_debounced)
        );

    wire [31:0] io2_output;
    wire [31:0] io2_input;
    wire [31:0] oe2;
    assign io2_input[31:19] = 13'b0;
    assign io2_input[18:16] = buttons_debounced;


    genvar j;
    generate
        for(j = 0; j < 16; j = j + 1) begin : g_io2_buffers
            io_buffer switch_buffer (
                .pin            (switches[j]),
                .gpio_input     (io2_input[j]),
                .gpio_output    (1'b0), //disallow output
                .gpio_oe        (1'b0)  //disallow output
            );

            io_buffer led_buffer (
                .pin            (LED[j]),
                .gpio_input     (),
                .gpio_output    (io2_output[16 + j]),
                .gpio_oe        (oe2[16 + j])
            );
        end
    endgenerate

    MIPS #(.IMEM_INIT_FILE("C:/Users/Brend/Downloads/MARS/gpiotest.hex")) mips_top (
            .clk                (clk_db),
            .rst_n              (rst_n),

            .io1_output         (io1_output),
            .io1_input          (io1_input),
            .oe1                (oe1),

            .io2_output         (io2_output),
            .io2_input          (io2_input),
            .oe2                (oe2)
        );
endmodule