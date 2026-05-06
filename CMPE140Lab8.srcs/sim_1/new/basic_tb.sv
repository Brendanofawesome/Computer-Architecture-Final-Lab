`timescale 1ns / 1ps
// =============================================================================
//  MIPS Processor - Smoke Test Testbench
//  Simulator : Vivado xsim
//  DUT       : MIPS.sv (full top-level)
//
//  Tested instructions:
//    ADDI, ADD, SUB, AND, OR, SLT, LUI, SW, LW, SLL, BEQ, J
//
//  Test program (see mipstest_tb.hex for encoded binary):
//    ADDI $1,  $0,  5        => $1  = 5
//    ADDI $2,  $0,  3        => $2  = 3
//    ADD  $3,  $1,  $2       => $3  = 8
//    SUB  $4,  $1,  $2       => $4  = 2
//    AND  $5,  $1,  $2       => $5  = 1
//    OR   $6,  $1,  $2       => $6  = 7
//    SLT  $7,  $2,  $1       => $7  = 1   (3 < 5)
//    LUI  $8,  0x0001        => $8  = 0x00010000
//    SW   $1,  0($0)         => mem[0] = 5
//    LW   $9,  0($0)         => $9  = 5
//    SLL  $10, $1,  2        => $10 = 20
//    BEQ  $3,  $3,  +3       => taken; skips ADDI $11,$0,99
//    ADDI $12, $0,  42       => $12 = 42  (landing pad)
//    J    self               => halt
//
//  All hazardous instruction pairs separated by 2 NOPs as required
//  by the no-hazard-detection design contract.
// =============================================================================

module basic_tb;

    // -------------------------------------------------------------------------
    //  Parameters
    // -------------------------------------------------------------------------
    localparam CLK_PERIOD     = 10;   // 10 ns => 100 MHz
    localparam TIMEOUT_CYCLES = 500;

    // Enough cycles for the pipeline to fully drain each instruction.
    // Each instruction takes 1 cycle + 2 NOPs = 3 cycles, ~13 instructions
    // + branch + jump padding = ~50 real cycles, 200 is comfortably safe.
    localparam SETTLE_CYCLES  = 200;

    // Total real (non-NOP) instructions in the test program.
    // Used to calculate effective CPI.
    //   14 real instructions: 2x ADDI, ADD, SUB, AND, OR, SLT, LUI,
    //                         SW, LW, SLL, BEQ, ADDI(landing), J
    localparam REAL_INSTR_COUNT = 14;

    // -------------------------------------------------------------------------
    //  DUT signals
    // -------------------------------------------------------------------------
    logic        clk;
    logic        rst_n;

    logic [31:0] io1_output;
    logic [31:0] io1_input;
    logic [31:0] oe1;

    logic [31:0] io2_output;
    logic [31:0] io2_input;
    logic [31:0] oe2;

    // -------------------------------------------------------------------------
    //  DUT instantiation
    // -------------------------------------------------------------------------
    MIPS #(
        // Override the IMEM init file to point at our test program.
        // This parameter propagates through datapath_top -> datapath_if.
        .IMEM_INIT_FILE("mipstest_tb.hex")
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .io1_output (io1_output),
        .io1_input  (io1_input),
        .oe1        (oe1),
        .io2_output (io2_output),
        .io2_input  (io2_input),
        .oe2        (oe2)
    );

    // -------------------------------------------------------------------------
    //  Clock generation
    // -------------------------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // -------------------------------------------------------------------------
    //  Convenience: direct register file access via hierarchical path.
    //  Adjust the path if your hierarchy differs.
    // -------------------------------------------------------------------------
    `define REGFILE dut.datapath.u_exe.regfile.registers
    `define RAM     dut.mapped_RAM.memory

    // -------------------------------------------------------------------------
    //  Timing variables
    // -------------------------------------------------------------------------
    longint t_reset_deassert;   // $time when rst_n goes high    (ns)
    longint t_program_end;      // $time when J-halt is detected (ns)

    longint elapsed_ns;         // total wall-clock sim time     (ns)
    longint elapsed_cycles;     // total clock cycles counted    (cycles)
    real    effective_cpi;      // elapsed_cycles / real instructions

    // -------------------------------------------------------------------------
    //  Cycle counter - increments every rising edge after reset releases
    // -------------------------------------------------------------------------
    longint cycle_counter;
    always @(posedge clk) begin
        if (!rst_n)
            cycle_counter <= 0;
        else
            cycle_counter <= cycle_counter + 1;
    end

    // -------------------------------------------------------------------------
    //  Halt detector
    //  Watches the PC register inside MIPS.sv directly.
    //  When PC stops changing (J-to-self) we snapshot $time and cycle count.
    // -------------------------------------------------------------------------
    logic [31:2] prev_pc;
    longint      halt_detected_at_cycle;
    bit          halt_seen;

    always @(posedge clk) begin
        if (!rst_n) begin
            prev_pc                <= '0;
            halt_seen              <= 0;
            halt_detected_at_cycle <= 0;
            t_program_end          <= 0;
        end else begin
            prev_pc <= dut.PC_q;
            // PC repeating itself == J-to-self halt.
            // Guard cycle_counter > 5 to ignore the reset/bubble period.
            if (!halt_seen && (dut.PC_q === prev_pc) && (cycle_counter > 5)) begin
                halt_seen              <= 1;
                halt_detected_at_cycle <= cycle_counter;
                t_program_end          <= $time;
            end
        end
    end

    // -------------------------------------------------------------------------
    //  Test tracking
    // -------------------------------------------------------------------------
    int pass_count;
    int fail_count;

    task automatic check(
        input string       test_name,
        input logic [31:0] got,
        input logic [31:0] expected
    );
        if (got === expected) begin
            $display("  PASS  %-32s  got=0x%08X", test_name, got);
            pass_count++;
        end else begin
            $display("  FAIL  %-32s  got=0x%08X  expected=0x%08X",
                     test_name, got, expected);
            fail_count++;
        end
    endtask

    // -------------------------------------------------------------------------
    //  Main test sequence
    // -------------------------------------------------------------------------
    initial begin
        // --- initialise ---
        rst_n      = 0;
        io1_input  = 32'hDEAD_BEEF;
        io2_input  = 32'hCAFE_F00D;
        pass_count = 0;
        fail_count = 0;
        halt_seen  = 0;

        // Apply reset for 4 clock cycles
        repeat(4) @(posedge clk);
        @(negedge clk);

        // Snapshot the exact sim time reset is released
        t_reset_deassert = $time;
        rst_n = 1;

        $display("");
        $display("========================================");
        $display("  MIPS Smoke Test Starting");
        $display("  Reset released at t = %0d ns", t_reset_deassert);
        $display("========================================");

        // Wait for the program to run and fully settle
        repeat(SETTLE_CYCLES) @(posedge clk);

        // ---------------------------------------------------------------
        //  Execution Time Report
        // ---------------------------------------------------------------
        elapsed_ns     = t_program_end - t_reset_deassert;
        elapsed_cycles = halt_detected_at_cycle;
        effective_cpi  = real'(elapsed_cycles) / real'(REAL_INSTR_COUNT);

        $display("");
        $display("--- Execution Time Report ---");
        if (halt_seen) begin
            $display("  Reset released        : t = %0d ns",  t_reset_deassert);
            $display("  Halt (J-self) reached : t = %0d ns",  t_program_end);
            $display("  Elapsed sim time      : %0d ns",      elapsed_ns);
            $display("  Elapsed cycles        : %0d cycles",  elapsed_cycles);
            $display("  Clock period          : %0d ns  (%0d MHz)",
                     CLK_PERIOD, 1000/CLK_PERIOD);
            $display("  Real instructions     : %0d  (NOPs excluded)",
                     REAL_INSTR_COUNT);
            $display("  Effective CPI         : %.2f  (ideal = 1.00, NOP-padded = 3.00)",
                     effective_cpi);
        end else begin
            $display("  WARNING: halt (J-self) was never detected.");
            $display("  Timing data unavailable - check program or SETTLE_CYCLES.");
        end

        // ---------------------------------------------------------------
        //  Register correctness checks
        // ---------------------------------------------------------------
        $display("");
        $display("--- Checking register results ---");

        check("ADDI: $1 = 5",          `REGFILE[1],  32'd5);
        check("ADDI: $2 = 3",          `REGFILE[2],  32'd3);
        check("ADD:  $3 = 8",          `REGFILE[3],  32'd8);
        check("SUB:  $4 = 2",          `REGFILE[4],  32'd2);
        check("AND:  $5 = 1",          `REGFILE[5],  32'd1);
        check("OR:   $6 = 7",          `REGFILE[6],  32'd7);
        check("SLT:  $7 = 1",          `REGFILE[7],  32'd1);
        check("LUI:  $8 = 0x00010000", `REGFILE[8],  32'h0001_0000);
        check("SLL:  $10 = 20",        `REGFILE[10], 32'd20);

        $display("");
        $display("--- Checking memory results ---");

        check("LW:   $9 = 5 (from mem[0])", `REGFILE[9], 32'd5);
        check("SW:   RAM[0] = 5",           `RAM[0],     32'd5);

        $display("");
        $display("--- Checking branch results ---");

        check("BEQ taken: $11 = 0 (not 99)", `REGFILE[11], 32'd0);
        check("BEQ landing: $12 = 42",        `REGFILE[12], 32'd42);

        $display("");
        $display("--- Sanity checks ---");

        check("$0 = 0 (hardwired)", `REGFILE[0], 32'd0);

        // ---------------------------------------------------------------
        //  Summary
        // ---------------------------------------------------------------
        $display("");
        $display("========================================");
        $display("  Results: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("========================================");

        if (fail_count == 0)
            $display("  *** ALL TESTS PASSED ***");
        else
            $display("  *** SOME TESTS FAILED - see above ***");

        $display("");
        $finish;
    end

    // -------------------------------------------------------------------------
    //  Timeout watchdog
    // -------------------------------------------------------------------------
    initial begin
        repeat(TIMEOUT_CYCLES) @(posedge clk);
        $display("TIMEOUT: simulation exceeded %0d cycles without $finish.",
                 TIMEOUT_CYCLES);
        $fatal(1, "Watchdog timeout");
    end

    // -------------------------------------------------------------------------
    //  Optional waveform dump
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("basic_tb.vcd");
        $dumpvars(0, basic_tb);
    end

endmodule
