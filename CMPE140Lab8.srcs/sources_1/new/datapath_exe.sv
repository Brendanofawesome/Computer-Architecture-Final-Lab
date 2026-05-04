module datapath_exe (
    input  logic        clk,
    input  logic        rst_n,

    //from ID
    input  alu_opcodes_e        ALU_op,
    input  logic [4:0]  shamt,
    input  logic [15:0] imm,
    input  logic        d2_sel,
    input  logic        mfsel,
    input  logic        mfrd,
    input  logic [4:0]  rs,
    input  logic [4:0]  rt,
    input  logic [4:0]  reg_dst_i,
    input  logic        branch_inv,
    input  logic        reg_wr_en_i,
    input  logic        jr,
    input  logic        branch,
    input  logic [31:2] b_addr,
    input  logic [31:0] reg_wb_data,
    input  logic [4:0]  reg_wb_addr,
    input  logic        reg_wb_en,
    input  divmul_function_e divmul_op,
    input  logic        divmul_signed_mode,
    input  logic        divmul_start,

    output logic [31:0] ALU_data,
    output logic [31:2] bta,
    output logic [31:0] ra,
    output logic        is_branch_type,
    output logic        ex_jump_trig,
    output logic        mul_done_o,
    output logic        reg_dst,
    output logic        reg_wr_en,
    output logic        reg_d2_o
);

    //register control signals


  logic [31:0] se_imm;
  logic [31:0] d2;
  logic [31:0] reg_d2;
  logic [31:0] d1;
  logic [31:0] divmul_hi;
  logic [31:0] divmul_lo;
  logic [31:0] hilo_out;
  logic [31:0] alu_out;
  logic        alu_zero;
  logic        branch_success;
  logic        divmul_ready_o;

  assign reg_dst = reg_dst_i;
  assign reg_wr_en = reg_wr_en_i;
  assign reg_d2_o = reg_d2;
  assign se_imm = {{16{imm[15]}}, imm};
  assign ra = d1;
  assign bta = b_addr;
  assign is_branch_type = branch;

  // --- ALU Logic --- //
  mux2to1 #(32) alu_d2_mux (
      .a(se_imm),
      .b(reg_d2),
      .sel(d2_sel),
      .y(d2)
  );

  ALU alu (
      .opcode_i(ALU_op),
      .shamt_i(shamt),
      .data1_i(d1),
      .data2_i(d2),
      .data_o(alu_out),
      .zero_o(alu_zero)
  );

  // --- Multiplication/Division Logic --- //
  divmul_unit divmul (
      .clk(clk),
      .rst_n(rst_n),
      .op_i(divmul_op),
      .signed_mode_i(divmul_signed_mode),
      .start_i(divmul_start),
      .d1_i(d1),
      .d2_i(reg_d2),
      .ready_o(mul_done_o),
      .hi_o(divmul_hi),
      .lo_o(divmul_lo)
  );

  mux2to1 #(32) HI_LO_sel (
      .a(divmul_hi),
      .b(divmul_lo),
      .sel(mfsel),
      .y(hilo_out)
  );

  mux2to1 #(32) D_wr_sel (
      .a(alu_out),
      .b(hilo_out),
      .sel(mfrd),
      .y(ALU_data)
  );

  // --- Register Logic --- //
  register_file regfile (
      .clk(clk),
      .read_addr1_i(rs),
      .read_addr2_i(rt),
      .write_data_i(reg_wb_data),
      .write_addr_i(reg_wb_addr),
      .write_en_i(reg_wb_en),
      .d1_o(d1),
      .d2_o(reg_d2)
  );

  // --- Branch Logic --- //
  mux2to1 branch_inv_mux (
      .a(alu_zero),
      .b(~alu_zero),
      .sel(branch_inv),
      .y(branch_success)
  );

  mux2to1 branch_sel_mux (
      .a(jr),
      .b(branch_success),
      .sel(branch),
      .y(ex_jump_trig)
  );

endmodule