//performs memory bus routing by decoding address to dispatch writes and multiplex reads

module membus_interconnect_top(
    input clk,
    input rst_n,

    input logic [31:0] address,
    memory_bus_if.Peripheral input_bus,

    output logic decode_error,

    memory_bus_if ram_bus,
    output logic [7:2] ram_address,

    memory_bus_if factorial_bus,
    output logic [3:2] factorial_address,

    memory_bus_if gpio1_bus,
    output logic [3:2] gpio1_address,

    memory_bus_if gpio2_bus,
    output logic [3:2] gpio2_address
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
    logic [31:0] selected_peripheral_base, target_address;
    always_comb begin
        unique case(current_peripheral)
            MEMORY: selected_peripheral_base = RAM_START_ADDRESS;
            FACTORIAL_ACCELERATOR: selected_peripheral_base = FACTORIAL_START_ADDRESS;
            GPIO1: selected_peripheral_base = GPIO1_START_ADDRESS;
            GPIO2: selected_peripheral_base = GPIO2_START_ADDRESS;
        endcase
        target_address = word_aligned_address - selected_peripheral_base;

        ram_address = target_address[7:2];
        RAM_bus.select = current_peripheral == MEMORY && !decode_error;
        RAM_bus.data_in = input_bus.data_in;
        RAM_bus.write_enable = input_bus.write_enable;

        factorial_address = target_address[3:2];
        factorial_bus.select = current_peripheral == FACTORIAL_ACCELERATOR && !decode_error;
        factorial_bus.data_in = input_bus.data_in;
        factorial_bus.write_enable = input_bus.write_enable;

        gpio1_address = target_address[3:2];
        GPIO1_bus.select = current_peripheral == GPIO1 && !decode_error;
        GPIO1_bus.data_in = input_bus.data_in;
        GPIO1_bus.write_enable = input_bus.write_enable;

        gpio2_address = target_address[3:2];
        GPIO2_bus.select = current_peripheral == GPIO2 && !decode_error;
        GPIO2_bus.data_in = input_bus.data_in;
        GPIO2_bus.write_enable = input_bus.write_enable;
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
