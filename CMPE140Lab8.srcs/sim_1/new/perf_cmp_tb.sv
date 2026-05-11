`timescale 1ns/1ps

module perf_cmp_tb;
    logic clk = 0, rst_n;
    logic [31:0] z = 0;
    logic [31:0] io1_out, io2_out, oe1, oe2;
    logic [31:0] pc_o_unused;
    always #5 clk = ~clk;

    MIPS #(.IMEM_INIT_FILE("test_fact_hw.hex")) hw_dut (
        .clk(clk), .rst_n(rst_n),
        .io1_input(z), .io2_input(z),
        .io1_output(), .io2_output(),
        .oe1(), .oe2(), .pc_o());

    MIPS #(.IMEM_INIT_FILE("test_fact_sw.hex")) sw_dut (
        .clk(clk), .rst_n(rst_n),
        .io1_input(z), .io2_input(z),
        .io1_output(), .io2_output(),
        .oe1(), .oe2(), .pc_o());

    int unsigned expected [0:12] = '{1,1,2,6,24,120,720,5040,40320,362880,3628800,39916800,479001600};
    int sw_cyc, hw_cyc, c;
    
    initial begin
        $display("");
        $display("=== Parameterized factorial sweep ===");
        $display("n,  SW result   SW cyc | HW result   HW cyc | speedup");
        for (int n = 0; n <= 12; n++) begin
            sw_cyc = -1;
            hw_cyc = -1;
            c = 0;
            rst_n = 0;
            repeat (4) @(posedge clk);
            // set input RAM[0] to n
            hw_dut.mapped_RAM.memory[0] = n;
            sw_dut.mapped_RAM.memory[0] = n;
            // clear RAM[1] so we don't see old result
            hw_dut.mapped_RAM.memory[1] = 0;
            sw_dut.mapped_RAM.memory[1] = 0;
            rst_n = 1;
            while (c < 5000 && (sw_cyc < 0 || hw_cyc < 0)) begin
                @(posedge clk); #1;
                c++;
                if (sw_cyc < 0 && sw_dut.mapped_RAM.memory[1] == expected[n])
                    sw_cyc = c;
                if (hw_cyc < 0 && hw_dut.mapped_RAM.memory[1] == expected[n])
                    hw_cyc = c;
            end
            $display("%2d  %d %4d   | %d %4d   | %.2fx",
                n,
                sw_dut.mapped_RAM.memory[1], sw_cyc,
                hw_dut.mapped_RAM.memory[1], hw_cyc,
                (sw_cyc>0 && hw_cyc>0) ? real'(sw_cyc)/real'(hw_cyc) : 0.0);
        end
        $finish;
    end
    initial begin #500000; $display("TIMEOUT"); $finish; end
endmodule