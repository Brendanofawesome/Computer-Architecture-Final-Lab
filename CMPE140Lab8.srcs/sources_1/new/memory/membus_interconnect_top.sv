//performs memory bus routing by decoding address to dispatch writes and multiplex reads

module membus_interconnect_top(
    input logic clk,
    input logic rst_n,

    input logic [31:0] address,
    memory_bus_if.Peripheral input_bus,

    output logic decode_error,

    memory_bus_if.Controller ram_bus,
    output logic [7:2] ram_address,

    memory_bus_if.Controller factorial_bus,
    output logic [3:2] factorial_address,

    memory_bus_if.Controller gpio1_bus,
    output logic [3:2] gpio1_address,

    memory_bus_if.Controller gpio2_bus,
    output logic [3:2] gpio2_address
    );

    // address mapping
    localparam bit [31:0]   RamStartAddress = 'h00000;
    localparam int          RamAddressSize = 8;
    localparam bit [31:0]   RamEndAddress = RamStartAddress + (1 << RamAddressSize);

    localparam bit [31:0]   FactorialStartAddress = 'h80000;
    localparam int          FactorialAddressSize = 4;
    localparam bit [31:0]   FactorialEndAddress = FactorialStartAddress + (1 << FactorialAddressSize);

    localparam bit [31:0]   Gpio1StartAddress = 'h90000;
    localparam int          Gpio1AddressSize = 4;
    localparam bit [31:0]   Gpio1EndAddress = Gpio1StartAddress + (1 << Gpio1AddressSize);

    localparam bit [31:0]   Gpio2StartAddress = 'h90010;
    localparam int          Gpio2AddressSize = 4;
    localparam bit [31:0]   Gpio2EndAddress = Gpio2StartAddress + (1 << Gpio2AddressSize);

    //multiplex control signals
    typedef enum {MEMORY, GPIO1, GPIO2, FACTORIAL_ACCELERATOR, NONE} peripherals_e;
    peripherals_e current_peripheral;

    //memory is word-oriented
    logic [31:0] word_aligned_address;
    assign word_aligned_address = {address[31:2], 2'b00};

    // decode selected peripheral from address
    always_comb begin : address_decode
        decode_error = 0;
        current_peripheral = NONE;

        if(input_bus.select) begin
            decode_error = 0;

            if      (word_aligned_address >= RamStartAddress && word_aligned_address < RamEndAddress) current_peripheral = MEMORY;
            else if (word_aligned_address >= FactorialStartAddress && word_aligned_address < FactorialEndAddress) current_peripheral = FACTORIAL_ACCELERATOR;
            else if (word_aligned_address >= Gpio1StartAddress && word_aligned_address < Gpio1EndAddress) current_peripheral = GPIO1;
            else if (word_aligned_address >= Gpio2StartAddress && word_aligned_address < Gpio2EndAddress) current_peripheral = GPIO2;
            else begin
                decode_error = 1;
                current_peripheral = NONE;
            end
        end
    end

    // multiplex write requests
    always_comb begin : write_dispatch
        ram_address       = '0;
        factorial_address = '0;
        gpio1_address     = '0;
        gpio2_address     = '0;

        ram_bus.select = current_peripheral == MEMORY && !decode_error;
        ram_bus.data_in = input_bus.data_in;
        ram_bus.write_enable = input_bus.write_enable;

        factorial_bus.select = current_peripheral == FACTORIAL_ACCELERATOR && !decode_error;
        factorial_bus.data_in = input_bus.data_in;
        factorial_bus.write_enable = input_bus.write_enable;

        gpio1_bus.select = current_peripheral == GPIO1 && !decode_error;
        gpio1_bus.data_in = input_bus.data_in;
        gpio1_bus.write_enable = input_bus.write_enable;

        gpio2_bus.select = current_peripheral == GPIO2 && !decode_error;
        gpio2_bus.data_in = input_bus.data_in;
        gpio2_bus.write_enable = input_bus.write_enable;

        unique case(current_peripheral)
            MEMORY: ram_address = word_aligned_address[7:2] - RamStartAddress[7:2];
            FACTORIAL_ACCELERATOR: factorial_address = word_aligned_address[3:2] - FactorialStartAddress[3:2];
            GPIO1: gpio1_address = word_aligned_address[3:2] - Gpio1StartAddress[3:2];
            GPIO2: gpio2_address = word_aligned_address[3:2] - Gpio2StartAddress[3:2];
            default: ;
        endcase
    end

    // multiplex reads
    always_comb begin : read_mux
        input_bus.data_out = '0;

        if(input_bus.select && !decode_error) begin
            unique case(current_peripheral)
                MEMORY: input_bus.data_out = ram_bus.data_out;
                GPIO1:  input_bus.data_out = gpio1_bus.data_out;
                GPIO2:  input_bus.data_out = gpio2_bus.data_out;
                FACTORIAL_ACCELERATOR: input_bus.data_out = factorial_bus.data_out;
                default: input_bus.data_out = '0;
            endcase
        end
    end
endmodule
