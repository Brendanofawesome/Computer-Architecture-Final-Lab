//pipeline hazard / stall control unit
// freezes PC + IF/ID and injects a NOP into ID/EX when the instruction in ID
// must wait for an older instruction to produce its value.
module hazard_unit (
    //decoded instruction currently in ID
    input  logic        id_uses_rs_i,
    input  logic        id_uses_rt_i,
    input  logic        id_branch_i,
    input  logic        id_jr_i,
    input  logic        id_mfrd_i,
    input  logic [4:0]  id_rs_i,
    input  logic [4:0]  id_rt_i,

    //instruction currently in EX
    input  logic        ex_reg_write_i,
    input  logic [4:0]  ex_reg_dst_i,
    input  logic        ex_mem_to_reg_i,

    //instruction currently in MEM
    input  logic        mem_reg_write_i,
    input  logic [4:0]  mem_reg_dst_i,

    //is div/mul unit ready with the result
    input  logic        divmul_ready_i,

    output logic        stall_pc_o,
    output logic        stall_if_id_o,
    output logic        bubble_id_ex_o,
    output logic        raw_stall_o,
    output logic        branch_stall_o,
    output logic        mfrd_stall_o
);

    logic rs_waiting_ex, rt_waiting_ex;
    logic rs_waiting_mem, rt_waiting_mem;
    logic raw_waiting_ex;
    logic load_use_waiting_ex;
    logic stall_any;

    assign rs_waiting_ex  = id_uses_rs_i && ex_reg_write_i  && (ex_reg_dst_i  != 5'd0) && (ex_reg_dst_i  == id_rs_i);
    assign rt_waiting_ex  = id_uses_rt_i && ex_reg_write_i  && (ex_reg_dst_i  != 5'd0) && (ex_reg_dst_i  == id_rt_i);
    assign rs_waiting_mem = id_uses_rs_i && mem_reg_write_i && (mem_reg_dst_i != 5'd0) && (mem_reg_dst_i == id_rs_i);
    assign rt_waiting_mem = id_uses_rt_i && mem_reg_write_i && (mem_reg_dst_i != 5'd0) && (mem_reg_dst_i == id_rt_i);

    assign raw_waiting_ex = rs_waiting_ex || rt_waiting_ex;

    //ALU/branch/store consumers only need to stall
    // when the producer in EX is a load. That value is not available soon enough
    // for the next instruction's EX stage without inserting one bubble.
    assign load_use_waiting_ex = ex_mem_to_reg_i && raw_waiting_ex;
    assign raw_stall_o = load_use_waiting_ex;

    //branches/JR also use the forwarded EX operands. They only stall for the
    // same load-use case above.
    assign branch_stall_o = (id_branch_i || id_jr_i) && load_use_waiting_ex;

    //MF must not enter EX until HI/LO has a valid result from divmul_unit.
    assign mfrd_stall_o = id_mfrd_i && !divmul_ready_i;

    assign stall_any = raw_stall_o || mfrd_stall_o;

    assign stall_pc_o = stall_any;
    assign stall_if_id_o = stall_any;
    assign bubble_id_ex_o = stall_any;
endmodule
