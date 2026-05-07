`timescale 1ns / 1ps

module generic_hex_tb;

    localparam int CLK_PERIOD = 10;

    // 🔹 Compile-time selected program
    localparam string HEX_FILE = "factorial.hex";
    localparam int MAX_CYCLES  = 1000;

    logic clk;
    logic rst_n;

    logic [31:0] io1_output, io1_input, oe1;
    logic [31:0] io2_output, io2_input, oe2;

    int cycle;

    MIPS #(
        .IMEM_INIT_FILE(HEX_FILE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),

        .io1_output(io1_output),
        .io1_input (io1_input),
        .oe1       (oe1),

        .io2_output(io2_output),
        .io2_input (io2_input),
        .oe2       (oe2)
    );

    `define PC dut.PC_q

    // Clock
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        rst_n = 0;
        io1_input = 0;
        io2_input = 0;
        cycle = 0;

        $display("Using program: %s", HEX_FILE);

        repeat (5) @(posedge clk);
        rst_n = 1;
    end

    always @(posedge clk) begin
        if (rst_n) begin
            cycle++;

            $display("cycle=%0d pc=0x%08x",
                     cycle,
                     {`PC, 2'b00});

            if (cycle >= MAX_CYCLES) begin
                $display("Reached MAX_CYCLES");
                $finish;
            end
        end
    end

endmodule