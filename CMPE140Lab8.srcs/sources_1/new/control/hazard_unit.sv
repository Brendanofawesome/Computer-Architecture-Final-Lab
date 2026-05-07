// Pipeline hazard / stall control unit.
//
// The datapath has MEM/WB forwarding, so ordinary ALU RAW dependencies do not
// need stalls.  The two real interlocks are:
//   1) load-use: the loaded value is not available to the immediately following
//      instruction's EX stage, so insert one bubble;
//   2) MFHI/MFLO while the mult/div unit is still busy.
module hazard_unit (
    // decoded instruction currently in ID
    input  logic        id_uses_rs_i,
    input  logic        id_uses_rt_i,
    input  logic        id_branch_i,
    input  logic        id_jr_i,
    input  logic        id_mfrd_i,
    input  logic [4:0]  id_rs_i,
    input  logic [4:0]  id_rt_i,
    input  logic        id_jump_trig_i,

    // instruction currently in EX
    input  logic        ex_reg_write_i,
    input  logic [4:0]  ex_reg_dst_i,
    input  logic        ex_mem_to_reg_i,
    input  logic        ex_jump_trig_i,

    // mult/div status
    input  logic        divmul_ready_i,

    output logic        stall_pc_o,
    output logic        stall_if_id_o,
    output logic        bubble_id_ex_o,
    output logic        if_id_flush_o,
    output logic        raw_stall_o,
    output logic        branch_stall_o,
    output logic        mfrd_stall_o
);

    logic rs_depends_on_ex;
    logic rt_depends_on_ex;
    logic load_use_stall;
    logic hilo_stall;
    logic data_stall;
    logic branch_or_jr;

    assign rs_depends_on_ex = id_uses_rs_i &&
                              ex_reg_write_i &&
                              (ex_reg_dst_i != 5'd0) &&
                              (ex_reg_dst_i == id_rs_i);

    assign rt_depends_on_ex = id_uses_rt_i &&
                              ex_reg_write_i &&
                              (ex_reg_dst_i != 5'd0) &&
                              (ex_reg_dst_i == id_rt_i);

    // Only a load in EX needs a RAW interlock.  ALU/div-hi-lo values are either
    // forwarded or held by the MFHI/MFLO-specific interlock below.
    assign load_use_stall = ex_mem_to_reg_i && (rs_depends_on_ex || rt_depends_on_ex);
    assign hilo_stall     = id_mfrd_i && !divmul_ready_i;
    assign data_stall     = load_use_stall || hilo_stall;
    assign branch_or_jr   = id_branch_i || id_jr_i;

    // Status/debug outputs.
    assign raw_stall_o    = load_use_stall;
    assign branch_stall_o = branch_or_jr && load_use_stall;
    assign mfrd_stall_o   = hilo_stall;

    // A taken EX-stage redirect wins over a data stall; do not freeze the PC
    // when the correct redirect target is already known.
    assign stall_pc_o    = data_stall && !ex_jump_trig_i;
    assign stall_if_id_o = data_stall && !ex_jump_trig_i;

    // Taken EX-stage branch/JR flushes IF/ID and the instruction entering EX.
    // J/JAL is resolved in ID, so only IF/ID is flushed and the jump itself is
    // allowed to continue into EX.  During a data stall, hold IF/ID instead of
    // flushing it.
    assign if_id_flush_o  = ex_jump_trig_i || (id_jump_trig_i && !data_stall);
    assign bubble_id_ex_o = data_stall || ex_jump_trig_i;

endmodule
