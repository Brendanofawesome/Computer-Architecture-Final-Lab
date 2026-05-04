//top level MIPS processor!

module MIPS(
    input clk, rst_n,

    output [31:0]   io1_output,
    input  [31:0]   io1_input,
    output [31:0]   oe1,

    output [31:0]   io2_output,
    input  [31:0]   io2_input,
    output [31:0]   oe2
    );

    ////////////////
    //PC Register //
    ////////////////

    logic [31:0] PC_q, PC_d; //PC register!
    always_ff @( clk ) begin : PC_reg
        if(!rst_n)
            PC_q <= '0;
        else
            PC_q <= PC_d;
    end

    logic [25:0] imm_jump_addr;
    logic id_jump_trig;

    logic is_branch_type;
    logic ex_jump_trig;

    logic [31:2] bta;
    logic [31:0] register_address;

    logic [31:0] next_PC;

    next_pc_gen(
        .imm_addr_i(imm_jump_addr),
        .id_jump_trig(id_jump_trig),
        .ex_j_type_i(is_branch_type),
        .ex_jump_i(ex_jump_trig),
        .bta_i(bta),
        .ra_i(register_address),
        .PC_i(PC_q),
        .PC_o(PC_d)
    );

    ///////////////////////////////
    //Memory Bus and Peripherals //
    ///////////////////////////////

    memory_bus_if membus_input;
    logic [31:0] memory_address_input;
    logic memory_decode_error;

    memory_bus_if membus_ram;
    logic [7:2] memory_address_ram;

    memory_bus_if membus_factorial;
    logic [3:2] memory_address_factorial;

    memory_bus_if membus_gpio1;
    logic [3:2] memory_address_gpio1;

    memory_bus_if membus_gpio2;
    logic [3:2] memory_address_gpio2;

    membus_interconnect_top peripherals(
        .clk(clk),
        .rst_n(rst_n),

        .address(memory_address_input),
        .input_bus(membus_input),

        .decode_error(memory_decode_error),

        .mem_bus_o(membus_ram),
        .mem_address_o(memory_address_ram),

        .factorial_bus(membus_factorial),
        .factorial_address(memory_address_factorial),

        .gpio1_bus(membus_gpio1),
        .gpio1_address(memory_address_gpio1),

        .gpio2_bus(membus_gpio2),
        .gpio2_address(memory_address_gpio2)
    );

    //GPIO
    GPIO_top GPIO_controller(
        .clk(clk),
        .rst_n(rst_n),

        .membus_gpio1(membus_gpio1),
        .memory_address_gpio1(memory_address_gpio1),

        .membus_gpio2(membus_gpio2),
        .memory_address_gpio2(memory_address_gpio2),

        .gpio_outputs1(io1_output),
        .gpio_inputs1(io1_input),
        .gpio_oe1(oe1),

        .gpio_outputs2(io2_output),
        .gpio_inputs2(io2_input),
        .gpio_oe2(oe2)
    );

    ram_interface #(.WIDTH(8)) mapped_RAM (
        .clk(clk),
        .rst_n(rst_n),

        .bus(membus_ram),
        .address(memory_address_ram)
    );

    //////////////
    // Datapath //
    //////////////
    datapath_top datapath(
        .clk(clk),
        .rst_n(rst_n),

        .pc_i(PC_q[31:2]),

        .divmul_op_i('0),
        .divmul_signed_mode_i('0),
        .divmul_start_i('0),

        .mem_bus(membus_input),

        .jump_address_o(imm_jump_addr),
        .id_jump_trig_o(id_jump_trig),
        .is_branch_type_o(is_branch_type),
        .branch_target_o(bta),
        .ra_o(register_address),
        .ex_jump_trig_o(ex_jump_trig),
        .branch_target_ex_o(),
        .alu_data_ex_o(),
        .reg_wr_data_o(),
        .mem_address_o(memory_address_input),
        .reg_wr_en_o(),
        .reg_dst_o(),
        .reg_d2_o()
    );
endmodule
