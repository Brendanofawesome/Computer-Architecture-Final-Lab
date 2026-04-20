//performs memory bus routing by decoding address to dispatch writes and multiplex reads

module membus_interconnect_top(
    input clk,
    input rst_n,

    input logic [31:0] address,
    memory_bus_if.Peripheral input_bus,

    output logic decode_error,

    inout tri [31:0] io1,
    inout tri [31:0] io2
    );

    // address mapping
    localparam bit [31:0]   RAM_START_ADDRESS = 'h00000;
    localparam int          RAM_ADDRESS_SIZE = 8;
    localparam bit [31:0]   RAM_END_ADDRESS = RAM_START_ADDRESS + (1 << RAM_ADDRESS_SIZE);

    localparam bit [31:0]   FACTORIAL_START_ADDRESS = 'h80000;
    localparam int          FACTORIAL_ADDRESS_SIZE = 4;
    localparam bit [31:0]   FACTORIAL_END_ADDRESS = FACTORIAL_START_ADDRESS + (1 << FACTORIAL_ADDRESS_SIZE);

    localparam bit [31:0]   GPIO1_START_ADDRESS = 'h90000;
    localparam int          GPIO1_ADDRESS_SIZE = 4;
    localparam bit [31:0]   GPIO1_END_ADDRESS = GPIO1_START_ADDRESS + (1 << GPIO1_ADDRESS_SIZE);

    localparam bit [31:0]   GPIO2_START_ADDRESS = 'h90010;
    localparam int          GPIO2_ADDRESS_SIZE = 4;
    localparam bit [31:0]   GPIO2_END_ADDRESS = GPIO2_START_ADDRESS + (1 << GPIO2_ADDRESS_SIZE);

    // RAM
    memory_bus_if RAM_bus();
    logic[7:2] RAM_address;

    ram_interface mapped_RAM(
        .clk(clk),
        .rst_n(rst_n),

        .bus(RAM_bus),
        .address(RAM_address)
    );

    // Factorial Accelerator
    memory_bus_if factorial_bus();
    logic[3:2] factorial_address;

    factorial_interface mapped_accelerator(
        .clk(clk),
        .rst_n(rst_n),

        .bus(factorial_bus),
        .address(factorial_address)
    );

    // GPIO 1
    memory_bus_if GPIO1_bus();
    logic[3:2] GPIO1_address;

    io_unit GPIO1(
        .clk(clk),
        .rst_n(rst_n),

        .bus(GPIO1_bus),
        .address(GPIO1_address),

        .pins(io1)
    );

    // GPIO 2
    memory_bus_if GPIO2_bus();
    logic[3:2] GPIO2_address;

    io_unit GPIO2(
        .clk(clk),
        .rst_n(rst_n),

        .bus(GPIO2_bus),
        .address(GPIO2_address),

        .pins(io2)
    );

    //multiplex control signals
    typedef enum {MEMORY, GPIO1, GPIO2, FACTORIAL_ACCELERATOR, NONE} peripherals_e;
    peripherals_e current_peripheral;

    //memory is word-oriented
    wire [31:0] word_aligned_address;
    assign word_aligned_address = {address[31:2], 2'b00};

    // decode selected peripheral from address
    always_comb begin : address_decode
        if(input_bus.select) begin
            decode_error = 0;

            if      (word_aligned_address >= RAM_START_ADDRESS && word_aligned_address < RAM_END_ADDRESS) current_peripheral = MEMORY;
            else if (word_aligned_address >= FACTORIAL_START_ADDRESS && word_aligned_address < FACTORIAL_END_ADDRESS) current_peripheral = FACTORIAL_ACCELERATOR;
            else if (word_aligned_address >= GPIO1_START_ADDRESS && word_aligned_address < GPIO1_END_ADDRESS) current_peripheral = GPIO1;
            else if (word_aligned_address >= GPIO2_START_ADDRESS && word_aligned_address < GPIO2_END_ADDRESS) current_peripheral = GPIO2;
            else begin
                decode_error = 1;
                current_peripheral = NONE;
            end
        end else begin
            decode_error = 0;
            current_peripheral = NONE;
        end
    end

    // multiplex write requests
    always_comb begin
        RAM_bus.select = current_peripheral == MEMORY && !decode_error;
        RAM_bus.data_in = input_bus.data_in;
        RAM_bus.write_enable = input_bus.write_enable;

        factorial_bus.select = current_peripheral == FACTORIAL_ACCELERATOR && !decode_error;
        factorial_bus.data_in = input_bus.data_in;
        factorial_bus.write_enable = input_bus.write_enable;

        GPIO1_bus.select = current_peripheral == GPIO1 && !decode_error;
        GPIO1_bus.data_in = input_bus.data_in;
        GPIO1_bus.write_enable = input_bus.write_enable;

        GPIO2_bus.select = current_peripheral == GPIO2 && !decode_error;
        GPIO2_bus.data_in = input_bus.data_in;
        GPIO2_bus.write_enable = input_bus.write_enable;

        RAM_address = (word_aligned_address - RAM_START_ADDRESS) >> 2;
        factorial_address = (word_aligned_address - FACTORIAL_START_ADDRESS) >> 2;
        GPIO1_address = (word_aligned_address - GPIO1_START_ADDRESS) >> 2;
        GPIO2_address = (word_aligned_address - GPIO2_START_ADDRESS) >> 2;
    end

    // multiplex reads
    always_comb begin
        input_bus.data_out = '0;

        if(input_bus.select && !decode_error) begin
            unique case(current_peripheral)
                MEMORY: input_bus.data_out = RAM_bus.data_out;
                GPIO1:  input_bus.data_out = GPIO1_bus.data_out;
                GPIO2:  input_bus.data_out = GPIO2_bus.data_out;
                FACTORIAL_ACCELERATOR: input_bus.data_out = factorial_bus.data_out;
                default: input_bus.data_out = '0;
            endcase
        end
    end
endmodule
