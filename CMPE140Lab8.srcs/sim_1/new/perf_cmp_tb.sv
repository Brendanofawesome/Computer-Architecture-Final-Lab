`timescale 1ns/1ps

module perf_cmp_tb;

    localparam int CLK_PERIOD = 10;
    localparam int MAX_CYCLES = 50000;

    logic        clk = 0;
    logic        rst_n;
    logic [31:0] io1_in = 0, io2_in = 0;
    logic [31:0] io1_out, io2_out, oe1, oe2;
    logic [31:0] pc_o_unused;

    always #(CLK_PERIOD/2) clk = ~clk;

    // instantiate two MIPS cores: one runs SW, one runs HW
    MIPS #(.IMEM_INIT_FILE("test_fact_sw.hex")) sw_dut (
        .clk(clk), .rst_n(rst_n),
        .io1_input(io1_in), .io2_input(io2_in),
        .io1_output(io1_out), .io2_output(io2_out),
        .oe1(oe1), .oe2(oe2), .pc_o(pc_o_unused));

    MIPS #(.IMEM_INIT_FILE("test_fact_hw.hex")) hw_dut (
        .clk(clk), .rst_n(rst_n),
        .io1_input(32'b0), .io2_input(32'b0),
        .io1_output(), .io2_output(),
        .oe1(), .oe2(), .pc_o());

    int sw_done_cyc = -1, hw_done_cyc = -1;

    int cycle;

    initial begin
        rst_n = 0;
        cycle = 0;
        repeat (4) @(posedge clk);
        rst_n = 1;
        while (cycle < MAX_CYCLES && (sw_done_cyc < 0 || hw_done_cyc < 0)) begin
            @(posedge clk);
            #1;
            cycle++;
            // end if calculation is done and result is as expected
            if (sw_done_cyc < 0 && sw_dut.datapath.u_exe.regfile.registers[2] == 32'd120)
                sw_done_cyc = cycle;
            if (hw_done_cyc < 0 && hw_dut.datapath.u_exe.regfile.registers[6] == 32'd120)
                hw_done_cyc = cycle;
        end

        $display("");
        $display("============================================");
        $display("  Performance Comparison Results (n=5)");
        $display("============================================");
        $display("  Software factorial : %0d cycles (result $v0=%0d)",
                 sw_done_cyc,
                 sw_dut.datapath.u_exe.regfile.registers[2]);
        $display("  Hardware factorial : %0d cycles (result $6 =%0d)",
                 hw_done_cyc,
                 hw_dut.datapath.u_exe.regfile.registers[6]);
        if (sw_done_cyc > 0 && hw_done_cyc > 0)
            $display("  Speedup            : %.2fx", real'(sw_done_cyc)/real'(hw_done_cyc));
        $display("============================================");
        $finish;
    end

    initial begin
        #(MAX_CYCLES * CLK_PERIOD * 2);
        $display("TIMEOUT");
        $finish;
    end
endmodule
