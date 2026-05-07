import shared_definitions_pkg::*;

module datapath_exe (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        bubble_i,

    //from ID
    input  alu_opcodes_e ALU_op_id,
    input  logic [4:0]  shamt_id,
    input  logic [15:0] imm_id,
    input  logic        d2_sel_id,
    input  logic        imm_zero_ext_id,
    input  logic        mfsel_id,
    input  logic        mfrd_id,
    input  logic [4:0]  rs_addr_id,
    input  logic [4:0]  rt_addr_id,
    input  logic [4:0]  reg_dst_id,
    input  logic        branch_inv_id,
    input  logic        reg_wr_en_id,
    input  logic        jal_id,
    input  logic        jr_id,
    input  logic        branch_id,
    input  logic [31:2] b_addr_id,
    input  logic [31:0] reg_wb_data,
    input  logic [4:0]  reg_wb_addr,
    input  logic        reg_wb_en,
    input  logic [31:0] forward_mem_data_i,
    input  logic [4:0]  forward_mem_addr_i,
    input  logic        forward_mem_en_i,
    input  divmul_function_e divmul_op_id,
    input  logic        divmul_signed_mode_id,
    input  logic        divmul_start_id,
    input  logic        mem_en_id,
    input  logic        mem_dir_id,
    input  logic [1:0]  mem_type_id,
    input  logic        mem_se_id,
    input  logic        mem_to_reg_id,

    output logic [31:0] ALU_data_ex,
    output logic [31:2] bta_ex,
    output logic [31:2] ra_ex,
    output logic        is_branch_type_ex,
    output logic        ex_jump_trig,
    output logic        mul_done_ex,

    output logic [4:0]  reg_dst_ex,
    output logic        reg_wr_en_ex,
    output logic [31:0] reg_d2_ex,

    output logic        mem_en_ex,
    output logic        mem_dir_ex,
    output logic [1:0]  mem_type_ex,
    output logic        mem_se_ex,
    output logic        mem_to_reg_ex
);

        // --- EX-stage pipeline registers for control and data --- //
    // EX-stage registered signals (suffixed _ex)

    //ALU control
    alu_opcodes_e ALU_op_ex;
    logic [4:0]  shamt_ex;

    //divmul control
    divmul_function_e divmul_op_ex;
    logic        divmul_signed_mode_ex;
    logic        divmul_start_ex;

    logic        hi_lo_sel_ex;
    logic        use_hilo_ex;

    //data input
    logic [4:0]  rs_addr_ex;
    logic [4:0]  rt_addr_ex;
    logic [15:0] imm_ex;
    logic        imm_zero_ext_ex;
    logic        d2_sel_ex;

    //branch control
    logic        jal_sel_ex;
    logic        branch_inv_ex;
    logic        jr_ex;
    logic        branch_ex;
    logic [31:2] branch_addr_ex;

    //memory control passthrough
    logic        mem_en_ex_i;
    logic        mem_dir_ex_i;
    logic [1:0]  mem_type_ex_i;
    logic        mem_se_ex_i;
    logic        mem_to_reg_ex_i;
    always_ff @(posedge clk or negedge rst_n) begin : ID_EX_REG
        if (!rst_n) begin
            jal_sel_ex <= '0;
            shamt_ex <= '0;
            rs_addr_ex <= '0;
            rt_addr_ex <= '0;
            imm_ex <= '0;
            imm_zero_ext_ex <= '0;
            reg_dst_ex <= '0;
            d2_sel_ex <= 1'b0;
            hi_lo_sel_ex <= 1'b0;
            use_hilo_ex <= 1'b0;
            branch_inv_ex <= 1'b0;
            reg_wr_en_ex <= 1'b0;
            jr_ex <= 1'b0;
            branch_ex <= 1'b0;
            branch_addr_ex <= '0;
            ALU_op_ex <= shared_definitions_pkg::ALU_ADD;
            divmul_op_ex <= shared_definitions_pkg::DIVMUL_MULT;
            divmul_signed_mode_ex <= 1'b0;
            divmul_start_ex <= 1'b0;
            mem_en_ex_i <= 1'b0;
            mem_dir_ex_i <= 1'b0;
            mem_type_ex_i <= 2'b10;
            mem_se_ex_i <= 1'b0;
            mem_to_reg_ex_i <= 1'b0;
        end else if (bubble_i) begin
            jal_sel_ex <= 1'b0;
            shamt_ex <= '0;
            rs_addr_ex <= '0;
            rt_addr_ex <= '0;
            reg_dst_ex <= '0;
            imm_ex <= '0;
            imm_zero_ext_ex <= 1'b0;
            d2_sel_ex <= 1'b0;
            hi_lo_sel_ex <= 1'b0;
            use_hilo_ex <= 1'b0;
            branch_inv_ex <= 1'b0;
            reg_wr_en_ex <= 1'b0;
            jr_ex <= 1'b0;
            branch_ex <= 1'b0;
            branch_addr_ex <= '0;
            ALU_op_ex <= shared_definitions_pkg::ALU_ADD;
            divmul_op_ex <= shared_definitions_pkg::DIVMUL_MULT;
            divmul_signed_mode_ex <= 1'b0;
            divmul_start_ex <= 1'b0;
            mem_en_ex_i <= 1'b0;
            mem_dir_ex_i <= 1'b0;
            mem_type_ex_i <= 2'b10;
            mem_se_ex_i <= 1'b0;
            mem_to_reg_ex_i <= 1'b0;
        end else begin
            jal_sel_ex <= jal_id;
            shamt_ex <= shamt_id;
            rs_addr_ex <= rs_addr_id;
            rt_addr_ex <= rt_addr_id;
            reg_dst_ex <= reg_dst_id;
            imm_ex <= imm_id;
            imm_zero_ext_ex <= imm_zero_ext_id;
            d2_sel_ex <= d2_sel_id;
            hi_lo_sel_ex <= mfsel_id;
            use_hilo_ex <= mfrd_id;
            branch_inv_ex <= branch_inv_id;
            reg_wr_en_ex <= reg_wr_en_id;
            jr_ex <= jr_id;
            branch_ex <= branch_id;
            branch_addr_ex <= b_addr_id;
            ALU_op_ex <= ALU_op_id;
            divmul_op_ex <= divmul_op_id;
            divmul_signed_mode_ex <= divmul_signed_mode_id;
            divmul_start_ex <= divmul_start_id;
            mem_en_ex_i <= mem_en_id;
            mem_dir_ex_i <= mem_dir_id;
            mem_type_ex_i <= mem_type_id;
            mem_se_ex_i <= mem_se_id;
            mem_to_reg_ex_i <= mem_to_reg_id;
        end
    end


        // Unregistered Signals
    logic [31:0] rs_data_raw;
    logic [31:0] rt_data_raw;
    logic [31:0] rs_data;
    logic [31:0] rt_data;

    logic [31:0] imm_se;

    logic [31:0] divmul_hi_q;
    logic [31:0] divmul_lo_q;
    logic [31:0] hilo_out;
    logic        divmul_ready_o;

    logic [31:0] alu_src2;
    logic [31:0] alu_out;
    logic        alu_zero;

    logic        branch_success;

    // Forwarding priority:
    //   1. MEM stage result (newer than WB)
    //   2. WB stage result
    //   3. Register file value
    // This feeds ALU operands, branch/JR operands, div/mul operands, and store data.
    always_comb begin : FORWARD_RS
        rs_data = rs_data_raw;
        if (forward_mem_en_i && (forward_mem_addr_i != 5'd0) && (forward_mem_addr_i == rs_addr_ex)) begin
            rs_data = forward_mem_data_i;
        end else if (reg_wb_en && (reg_wb_addr != 5'd0) && (reg_wb_addr == rs_addr_ex)) begin
            rs_data = reg_wb_data;
        end
    end

    always_comb begin : FORWARD_RT
        rt_data = rt_data_raw;
        if (forward_mem_en_i && (forward_mem_addr_i != 5'd0) && (forward_mem_addr_i == rt_addr_ex)) begin
            rt_data = forward_mem_data_i;
        end else if (reg_wb_en && (reg_wb_addr != 5'd0) && (reg_wb_addr == rt_addr_ex)) begin
            rt_data = reg_wb_data;
        end
    end

    assign imm_se = imm_zero_ext_ex ? {16'b0, imm_ex} : {{16{imm_ex[15]}}, imm_ex};
    assign ra_ex = rs_data[31:2];
    assign bta_ex = branch_addr_ex;
    assign is_branch_type_ex = branch_ex;

    // --- ALU Logic --- //
    mux2to1 #(32) alu_d2_mux (
        .a(rt_data),
        .b(imm_se),
        .sel(d2_sel_ex),
        .y(alu_src2)
    );

    ALU alu (
        .opcode_i(ALU_op_ex),
        .shamt_i(shamt_ex),
        .data1_i(rs_data),
        .data2_i(alu_src2),
        .data_o(alu_out),
        .zero_o(alu_zero)
    );

    // --- Multiplication/Division Logic --- //
    divmul_unit divmul (
        .clk(clk),
        .rst_n(rst_n),
        .op_i(divmul_op_ex),
        .signed_mode_i(divmul_signed_mode_ex),
        .start_i(divmul_start_ex),
        .d1_i(rs_data),
        .d2_i(rt_data),
        .ready_o(divmul_ready_o),
        .hi_o(divmul_hi_q),
        .lo_o(divmul_lo_q)
    );

    mux2to1 #(32) HI_LO_sel (
        .a(divmul_hi_q),
        .b(divmul_lo_q),
        .sel(hi_lo_sel_ex),
        .y(hilo_out)
    );

    always_comb begin : D_wr_sel
        if(use_hilo_ex) begin
            ALU_data_ex = hilo_out;
        end else if (jal_sel_ex) begin
            ALU_data_ex = {branch_addr_ex, 2'b00};
        end else begin
            ALU_data_ex = alu_out;
        end
    end

    // --- Register Logic --- //
        register_file regfile (
                .clk(clk),
                .read_addr1_i(rs_addr_ex),
                .read_addr2_i(rt_addr_ex),
                .write_data_i(reg_wb_data),
                .write_addr_i(reg_wb_addr),
                .write_en_i(reg_wb_en),
                            .d1_o(rs_data_raw),
                            .d2_o(rt_data_raw)
        );

    // --- Branch Logic --- //
    mux2to1 branch_inv_mux (
        .a(alu_zero),
        .b(~alu_zero),
        .sel(branch_inv_ex),
        .y(branch_success)
    );

    mux2to1 branch_sel_mux (
        .a(jr_ex),
        .b(branch_success),
        .sel(branch_ex),
        .y(ex_jump_trig)
    );

    // expose registered write-back control and RT data for next stage (module outputs)
    assign mul_done_ex = divmul_ready_o;
    assign reg_d2_ex = rt_data;

    // reg_dst_ex and reg_wr_en_ex are already internal registers with matching output names
    assign mem_en_ex = mem_en_ex_i;
    assign mem_dir_ex = mem_dir_ex_i;
    assign mem_type_ex = mem_type_ex_i;
    assign mem_se_ex = mem_se_ex_i;
    assign mem_to_reg_ex = mem_to_reg_ex_i;

endmodule
