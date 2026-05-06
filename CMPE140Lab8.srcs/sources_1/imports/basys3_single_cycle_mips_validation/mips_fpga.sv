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

    wire [31:0] pc_output;

    function automatic [7:0] hex_to_7seg(input logic [3:0] hex);
        case (hex)
            4'h0: hex_to_7seg = 8'b1100_0000;
            4'h1: hex_to_7seg = 8'b1111_1001;
            4'h2: hex_to_7seg = 8'b1010_0100;
            4'h3: hex_to_7seg = 8'b1011_0000;
            4'h4: hex_to_7seg = 8'b1001_1001;
            4'h5: hex_to_7seg = 8'b1001_0010;
            4'h6: hex_to_7seg = 8'b1000_0010;
            4'h7: hex_to_7seg = 8'b1111_1000;
            4'h8: hex_to_7seg = 8'b1000_0000;
            4'h9: hex_to_7seg = 8'b1001_0000;
            4'hA: hex_to_7seg = 8'b1000_1000;
            4'hB: hex_to_7seg = 8'b1000_0011;
            4'hC: hex_to_7seg = 8'b1100_0110;
            4'hD: hex_to_7seg = 8'b1010_0001;
            4'hE: hex_to_7seg = 8'b1000_0110;
            4'hF: hex_to_7seg = 8'b1000_1110;
            default: hex_to_7seg = 8'b1111_1111;
        endcase
    endfunction

    wire [7:0]  digit0;
    wire [7:0]  digit1;
    wire [7:0]  digit2;
    wire [7:0]  digit3;
    assign digit0 = hex_to_7seg(pc_output[3:0]);
    assign digit1 = hex_to_7seg(pc_output[7:4]);
    assign digit2 = hex_to_7seg(pc_output[11:8]);
    assign digit3 = hex_to_7seg(pc_output[15:12]);

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
    assign io2_input[31:16] = 13'b0;


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

    MIPS #(.IMEM_INIT_FILE("C:/Users/Brend/Downloads/MARS/mipsblink.hex")) mips_top (
            .clk                (clk_db),
            .rst_n              (rst_n),

            .io1_output         (io1_output),
            .io1_input          (io1_input),
            .oe1                (oe1),

            .io2_output         (io2_output),
            .io2_input          (io2_input),
            .oe2                (oe2),

            .pc_o               (pc_output)
        );
endmodule
