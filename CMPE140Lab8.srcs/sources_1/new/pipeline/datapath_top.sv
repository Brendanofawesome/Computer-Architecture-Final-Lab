//top-level datapath wrapper
import shared_definitions_pkg::*;

module datapath_top #(parameter string IMEM_INIT_FILE = "mipstest.bin")(
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
    output logic [31:0] reg_d2_o,
    output logic        stall_pc_o,
    output logic        stall_if_id_o,
    output logic        bubble_id_ex_o,
    output logic        raw_stall_o,
    output logic        branch_stall_o,
    output logic        mfrd_stall_o
);

    // IF-stage instruction fetch
    logic [31:0] instr_if;

    datapath_if #(.IMEM_INIT_FILE(IMEM_INIT_FILE)) u_if (
        .clk(clk),
        .rst_n(rst_n),
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

    logic        stall_pc;
    logic        stall_if_id;
    logic        bubble_id_ex;
    logic        if_id_flush;
    logic        raw_stall;
    logic        branch_stall;
    logic        mfrd_stall;
    logic        divmul_ready_ex;
    logic        id_uses_rs;
    logic        id_uses_rt;

    //determine the registers read by ID instruction
    instruction_format_e instruction_format_id;
    always_comb begin
        unique case (instruction_format_id)
            FORMAT_INSTR_R: begin
                id_uses_rs = 1'b1;
                id_uses_rt = !jr_id;
            end

            FORMAT_INSTR_I: begin
                id_uses_rs = 1'b1;
                id_uses_rt = mem_dir_id || branch_id;
            end


            FORMAT_INSTR_J: begin
                id_uses_rs = 1'b0;
                id_uses_rt = 1'b0;
            end

            default: begin
                id_uses_rs = 1'b0;
                id_uses_rt = 1'b0;
            end
        endcase
    end

    datapath_id u_id (
        .clk(clk),
        .rst_n(rst_n),
        .stall_i(stall_if_id),
        .flush_i(if_id_flush),
        .instr_i(instr_if),
        .pc_q(pc_i),
        .shamt_o(shamt_id),
        .imm_o(imm_id),
        .rs_o(rs_id),
        .rt_o(rt_id),
        .imm_addr_o(imm_addr_id),
        .branch_address_o(bta_id),
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
        .dst_o(dst_id),
        .instruction_format_o(instruction_format_id)
    );

    assign jump_address_o = imm_addr_id;
    assign id_jump_trig_o = jump_trig_id || jal_trig_id;

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
        .bubble_i(bubble_id_ex),
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
        .jal_id(jal_trig_id),
        .jr_id(jr_id),
        .branch_id(branch_id),
        .b_addr_id(bta_id),
        .reg_wb_data(data_wb),
        .reg_wb_addr(reg_dst_wb),
        .reg_wb_en(reg_wr_en_wb),
        .forward_mem_data_i(reg_wr_data_mem),
        .forward_mem_addr_i(reg_dst_mem),
        .forward_mem_en_i(reg_wr_en_mem),
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
        .mul_done_ex(divmul_ready_ex),
        .reg_dst_ex(reg_dst_ex),
        .reg_wr_en_ex(reg_wr_en_ex),
        .reg_d2_ex(reg_d2_ex),
        .mem_en_ex(mem_en_ex),
        .mem_dir_ex(mem_dir_ex),
        .mem_type_ex(mem_type_ex),
        .mem_se_ex(mem_se_ex),
        .mem_to_reg_ex(mem_to_reg_ex)
    );


    hazard_unit u_hazard_unit (
        .id_uses_rs_i(id_uses_rs),
        .id_uses_rt_i(id_uses_rt),
        .id_branch_i(branch_id),
        .id_jr_i(jr_id),
        .id_mfrd_i(mfrd_id),
        .id_rs_i(rs_id),
        .id_rt_i(rt_id),
        .id_jump_trig_i(jump_trig_id || jal_trig_id),
        .ex_reg_write_i(reg_wr_en_ex),
        .ex_reg_dst_i(reg_dst_ex),
        .ex_mem_to_reg_i(mem_to_reg_ex),
        .ex_jump_trig_i(ex_jump_trig_o),
        .mem_reg_write_i(reg_wr_en_mem),
        .mem_reg_dst_i(reg_dst_mem),
        .divmul_ready_i(divmul_ready_ex),
        .stall_pc_o(stall_pc),
        .stall_if_id_o(stall_if_id),
        .bubble_id_ex_o(bubble_id_ex),
        .if_id_flush_o(if_id_flush),
        .raw_stall_o(raw_stall),
        .branch_stall_o(branch_stall),
        .mfrd_stall_o(mfrd_stall)
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

    assign stall_pc_o = stall_pc;
    assign stall_if_id_o = stall_if_id;
    assign bubble_id_ex_o = bubble_id_ex;
    assign raw_stall_o = raw_stall;
    assign branch_stall_o = branch_stall;
    assign mfrd_stall_o = mfrd_stall;
endmodule
