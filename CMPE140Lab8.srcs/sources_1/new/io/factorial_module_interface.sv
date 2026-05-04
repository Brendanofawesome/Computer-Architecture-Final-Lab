module factorial_module_interface(
    input  logic                    clk,
    input  logic                    rst_n,
    memory_bus_if.Peripheral        factorial_bus,
    input  logic [3:2]              factorial_address
    );

    // local registers for accelerator control
    logic [3:0]  hex_in_reg;
    logic        go_req;
    logic [31:0] fact_out;
    logic        fact_done;
    logic        fact_error;

    // instantiate behavioral accelerator
    Factorial u_factorial(
        .hex_in(hex_in_reg),
        .go(go_req),
        .clk(clk),
        .rst(~rst_n),
        .hex_out(fact_out),
        .done(fact_done),
        .error(fact_error)
    );

    // capture writes synchronously (write enables are byte lanes; any non-zero indicates a write)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hex_in_reg <= '0;
            go_req <= 1'b0;
        end else begin
            // default: clear any transient go request
            go_req <= 1'b0;
            if (factorial_bus.select && |factorial_bus.write_enable) begin
                // factorial_address comes as bits [3:2] from interconnect; map to 2-bit address
                unique case (factorial_address)
                    2'b00: begin
                        // write input value (lower 4 bits)
                        hex_in_reg <= factorial_bus.data_in[3:0];
                    end
                    2'b01: begin
                        // write start/go bit (bit 0)
                        if (factorial_bus.data_in[0]) go_req <= 1'b1;
                    end
                    default: begin end
                endcase
            end
        end
    end

    // provide read data combinationally
    always_comb begin
        factorial_bus.data_out = '0;
        if (factorial_bus.select) begin
            unique case (factorial_address)
                2'b00: factorial_bus.data_out = fact_out; // result
                2'b01: begin
                    factorial_bus.data_out = {30'b0, fact_error, fact_done};
                end // status: [1]=error, [0]=done
                default: factorial_bus.data_out = '0;
            endcase
        end
    end

endmodule
