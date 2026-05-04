// Top-level datapath wrapper
import shared_definitions_pkg::*;

module datapath_top(
    input  logic        clk,
    input  logic        rst_n,

    // PC from MIPS (PC generation is external)
    input  logic [31:2] pc_i,

    // Shared memory bus
    memory_bus_if.Controller mem_bus,

    // Jump control signals for PC generation (external)
    output logic [25:0] jump_address_o,
    output logic        id_jump_trig_o,
    output logic        is_branch_type_o,
    output logic [31:2] branch_target_o,
    output logic [31:2] ra_o,
    output logic        ex_jump_trig_o,

    // Pipeline data visibility
    output logic [31:2] branch_target_ex_o,
    output logic [31:0] alu_data_ex_o,
    output logic [31:0] reg_wr_data_o,
    output logic [31:2] mem_address_o,
    output logic        reg_wr_en_o,
    output logic [4:0]  reg_dst_o,
    output logic [31:0] reg_d2_o
);

    // IF-stage instruction fetch
    logic [31:0] instr_if;

    datapath_if u_if (
        .address_i(pc_i),
        .instr_o(instr_if)
    );

    // ID-stage decode wires
    logic [4:0]  shamt_id;
    logic [15:0] imm_id;
    logic [4:0]  rs_id;
    logic [4:0]  rt_id;
    logic [25:0] imm_addr_id;
    logic [31:2] bta_id;
    logic        mfsel_id;
    logic        mfrd_id;
    logic        branch_inv_id;
    logic        branch_id;
    logic        jr_id;
    logic        imm_sel_id;
    logic        imm_zero_ext_id;
    alu_opcodes_e alu_op_id;
    logic        reg_write_en_id;
    logic        jump_trig_id;
    logic        jal_trig_id;
    logic [4:0]  dst_id;
    logic        mem_en_id;
    logic        mem_dir_id;
    logic [1:0]  mem_type_id;
    logic        mem_se_id;
    logic        mem_to_reg_id;
    divmul_function_e divmul_op_id;
    logic             divmul_start_id;
    logic             divmul_signmode_id;

    datapath_id u_id (
        .clk(clk),
        .rst_n(rst_n),
        .instr_i(instr_if),
        .pc_q(pc_i),
        .shamt_o(shamt_id),
        .imm_o(imm_id),
        .rs_o(rs_id),
        .rt_o(rt_id),
        .imm_addr_o(imm_addr_id),
        .b_adder_o(bta_id),
        .mfsel_o(mfsel_id),
        .mfrd_o(mfrd_id),
        .branch_inv_o(branch_inv_id),
        .branch_o(branch_id),
        .jr_o(jr_id),
        .imm_sel_o(imm_sel_id),
        .imm_zero_ext_o(imm_zero_ext_id),
        .alu_op_o(alu_op_id),
        .reg_write_en_o(reg_write_en_id),
        .jump_trig_o(jump_trig_id),
        .jal_trig_o(jal_trig_id),
        .decode_err_o(),
        .mem_en_o(mem_en_id),
        .mem_dir_o(mem_dir_id),
        .mem_type_o(mem_type_id),
        .mem_se_o(mem_se_id),
        .mem_to_reg_o(mem_to_reg_id),
        .div_mul_op_o(divmul_op_id),
        .divmul_start_o(divmul_start_id),
        .divmul_signmode_o(divmul_signmode_id),
        .dst_o(dst_id)
    );

    assign jump_address_o = imm_addr_id;
    assign id_jump_trig_o = jump_trig_id | jal_trig_id;

    // Map ID controls to EX controls used by datapath_exe

    // EX-stage outputs
    logic [31:0] alu_data_ex;
    logic [31:2] bta_ex;
    logic [31:0] ra_ex;
    logic        is_branch_type_ex;
    logic [4:0]  reg_dst_ex;
    logic        reg_wr_en_ex;
    logic [31:0] reg_d2_ex;
    logic        mem_en_ex;
    logic        mem_dir_ex;
    logic [1:0]  mem_type_ex;
    logic        mem_se_ex;
    logic        mem_to_reg_ex;

    // MEM/WB pipeline wires
    logic        reg_wr_en_mem;
    logic [4:0]  reg_dst_mem;
    logic [31:0] reg_wr_data_mem;
    logic        reg_wr_en_wb;
    logic [4:0]  reg_dst_wb;
    logic [31:0] data_wb;

    datapath_exe u_exe (
        .clk(clk),
        .rst_n(rst_n),
        .ALU_op_id(alu_op_id),
        .shamt_id(shamt_id),
        .imm_id(imm_id),
        .d2_sel_id(imm_sel_id),
        .imm_zero_ext_id(imm_zero_ext_id),
        .mfsel_id(mfsel_id),
        .mfrd_id(mfrd_id),
        .rs_addr_id(rs_id),
        .rt_addr_id(rt_id),
        .reg_dst_id(dst_id),
        .branch_inv_id(branch_inv_id),
        .reg_wr_en_id(reg_write_en_id),
        .jr_id(jr_id),
        .branch_id(branch_id),
        .b_addr_id(bta_id),
        .reg_wb_data(data_wb),
        .reg_wb_addr(reg_dst_wb),
        .reg_wb_en(reg_wr_en_wb),
        .divmul_op_id(divmul_op_id),
        .divmul_signed_mode_id(divmul_signmode_id),
        .divmul_start_id(divmul_start_id),
        .mem_en_id(mem_en_id),
        .mem_dir_id(mem_dir_id),
        .mem_type_id(mem_type_id),
        .mem_se_id(mem_se_id),
        .mem_to_reg_id(mem_to_reg_id),
        .ALU_data_ex(alu_data_ex),
        .bta_ex(bta_ex),
        .ra_ex(ra_ex),
        .is_branch_type_ex(is_branch_type_ex),
        .ex_jump_trig(ex_jump_trig_o),
        .mul_done_ex(),
        .reg_dst_ex(reg_dst_ex),
        .reg_wr_en_ex(reg_wr_en_ex),
        .reg_d2_ex(reg_d2_ex),
        .mem_en_ex(mem_en_ex),
        .mem_dir_ex(mem_dir_ex),
        .mem_type_ex(mem_type_ex),
        .mem_se_ex(mem_se_ex),
        .mem_to_reg_ex(mem_to_reg_ex)
    );

    datapath_mem u_mem (
        .clk(clk),
        .rst_n(rst_n),
        .reg_wr_en_i(reg_wr_en_ex),
        .reg_dst_i(reg_dst_ex),
        .ALU_data_i(alu_data_ex),
        .reg_d2(reg_d2_ex),
        .mem_se(mem_se_ex),
        .mem_type(mem_type_ex),
        .mem_dir(mem_dir_ex),
        .mem_en(mem_en_ex),
        .mem_to_reg(mem_to_reg_ex),
        .reg_wr_en(reg_wr_en_mem),
        .reg_dst(reg_dst_mem),
        .reg_wr_data(reg_wr_data_mem),
        .mem_bus(mem_bus),
        .mem_address_o(mem_address_o)
    );

    datapath_wb u_wb (
        .clk(clk),
        .rst_n(rst_n),
        .reg_wr_en(reg_wr_en_mem),
        .reg_dst(reg_dst_mem),
        .data(reg_wr_data_mem),
        .reg_wr_en_passback(reg_wr_en_wb),
        .reg_dst_passback(reg_dst_wb),
        .data_passback(data_wb)
    );

    assign branch_target_o = bta_ex;
    assign branch_target_ex_o = bta_ex;

    assign reg_wr_en_o = reg_wr_en_wb;
    assign reg_dst_o = reg_dst_wb;
    assign reg_d2_o = reg_d2_ex;
    assign alu_data_ex_o = alu_data_ex;
    assign ra_o = ra_ex[31:2];
    assign is_branch_type_o = is_branch_type_ex;
    assign reg_wr_data_o = data_wb;

endmodule

