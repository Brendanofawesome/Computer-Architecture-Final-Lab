// opcode_decoder_instantiate for top level

instruction_function_e  function_w;
instruction_format_e    format_w;
logic  illegal_instr_w;
logic [4:0]  rs_w;
logic [4:0]  rt_w;
logic [4:0]  rd_w;
logic [15:0] imm_w;
logic [25:0] imm_addr_w;
logic [4:0]  shamt_w;


opcode_decoder u_opcode_decoder (
        .instr_i            (instr_i),

        .function_o         (function_w),
        .format_o           (format_w),
        .illegal_instr_o    (illegal_instr_w),

        .rs_o               (rs_w),
        .rt_o               (rt_w),
        .rd_o               (rd_w),

        .imm_o              (imm_w),
        .imm_addr_o         (imm_addr_w),
        .shamt_o            (shamt_w)
);






