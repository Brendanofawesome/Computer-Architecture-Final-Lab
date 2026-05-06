//top level MIPS processor!

module MIPS #(parameter string IMEM_INIT_FILE = "mipstest.bin")(
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

    logic [31:2] PC_q, PC_d; // PC word-address register
    logic [31:0] nPC_d_full;
    logic        stall_pc;
    always @( posedge clk ) begin : PC_reg
        if(!rst_n)
            PC_q <= '0;
        else if (!stall_pc)
            PC_q <= PC_d;
    end

    logic [25:0] imm_jump_addr;
    logic id_jump_trig;

    logic is_branch_type;
    logic ex_jump_trig;

    logic [31:2] bta;
    logic [31:2] register_address;

    next_pc_gen pc_gen(
        .imm_addr_i(imm_jump_addr),
        .id_jump_i(id_jump_trig),
        .ex_j_type_i(is_branch_type),
        .ex_jump_i(ex_jump_trig),
        .bta_i(bta),
        .ra_i(register_address),
        .PC_i(PC_q),
        .nPC_o(nPC_d_full)
    );
    assign PC_d = nPC_d_full[31:2];

    ///////////////////////////////
    //Memory Bus and Peripherals //
    ///////////////////////////////

    memory_bus_if membus_input();
    logic [31:2] memory_address_input;

    memory_bus_if membus_ram();
    logic [7:2] memory_address_ram;

    memory_bus_if membus_factorial();
    logic [3:2] memory_address_factorial;

    memory_bus_if membus_gpio1();
    logic [3:2] memory_address_gpio1;

    memory_bus_if membus_gpio2();
    logic [3:2] memory_address_gpio2;

    membus_interconnect_top peripherals(
        .clk(clk),
        .rst_n(rst_n),

        .address(memory_address_input),
        .input_bus(membus_input),

        .decode_error(),

        .ram_bus(membus_ram),
        .ram_address(memory_address_ram),

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

    // Factorial accelerator interface
    factorial_module_interface factorial_if (
        .clk(clk),
        .rst_n(rst_n),
        .factorial_bus(membus_factorial),
        .factorial_address(memory_address_factorial)
    );

    //////////////
    // Datapath //
    //////////////
    datapath_top #(.IMEM_INIT_FILE(IMEM_INIT_FILE)) datapath(
        .clk(clk),
        .rst_n(rst_n),

        .pc_i(PC_q),

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
        .reg_d2_o(),
        .stall_pc_o(stall_pc),
        .stall_if_id_o(),
        .bubble_id_ex_o(),
        .raw_stall_o(),
        .branch_stall_o(),
        .mfrd_stall_o()
    );
endmodule
