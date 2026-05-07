module clk_gen (
        input  wire clk100MHz,
        output reg  clk_sec,
        output reg  clk_5KHz
    );

    integer count1, count2;

    initial count1 = 0;
    initial count2 = 0;

    always @ (posedge clk100MHz) begin
        if (count1 == 800000000) begin
            clk_sec = ~clk_sec;
            count1 = 0;
        end

        if (count2 == 10000) begin
            clk_5KHz = ~clk_5KHz;
            count2 = 0;
        end

        count1 = count1 + 1;
        count2 = count2 + 1;
    end

endmodule
