module memory_controller(
    input logic [31:0] address_i,
    input logic [31:0] data_i,

    input logic        sign_extend_i, // 1 == sign extend, 0 == zero extend
    input logic [1:0]  data_type_i, // 00 == byte, 01 == halfword, 10 == word
    input logic        data_dir_i, // 1 == write to memory, 0 == read from memory
    input logic        en_i,

    output logic [31:0] data_o,
    memory_bus_if.Controller membus_o,
    output logic [31:2] address_o
    );

    //passthrough to the interconnect
    assign address_o = address_i[31:2];
    assign membus_o.select = en_i;

    //assign the write enable strobe bits
    always_comb begin : write_en_strobe
        membus_o.write_enable = 4'b0000; //default

        if(en_i && data_dir_i) begin
            unique case(data_type_i)
                2'b00: begin //write byte
                    unique case(address_i[1:0])
                        2'b00: membus_o.write_enable = 4'b0001;
                        2'b01: membus_o.write_enable = 4'b0010;
                        2'b10: membus_o.write_enable = 4'b0100;
                        2'b11: membus_o.write_enable = 4'b1000;
                    endcase
                end

                2'b01: begin //write halfword
                    unique case(address_i[1])
                        1'b0: membus_o.write_enable = 4'b0011;
                        1'b1: membus_o.write_enable = 4'b1100;
                    endcase
                end

                2'b10: begin //write word
                    membus_o.write_enable = 4'b1111;
                end

                default: membus_o.write_enable = 4'b0000;
            endcase
        end
    end

    //assign the memory write data
    logic [31:0] in_shift1, in_shift2, in_shift3;
    assign in_shift1 = data_i << 8;
    assign in_shift2 = data_i << 16;
    assign in_shift3 = data_i << 24;
    always_comb begin : write_data_shift
        membus_o.data_in = '0; //default

        if(en_i && data_dir_i) begin
            unique case(data_type_i)
                2'b00: begin //write byte
                    unique case(address_i[1:0])
                        2'b00: membus_o.data_in = data_i;
                        2'b01: membus_o.data_in = in_shift1;
                        2'b10: membus_o.data_in = in_shift2;
                        2'b11: membus_o.data_in = in_shift3;
                    endcase
                end

                2'b01: begin //write halfword
                    unique case(address_i[1])
                        1'b0: membus_o.data_in = data_i;
                        1'b1: membus_o.data_in = in_shift2;
                    endcase
                end

                2'b10: begin //write word
                    membus_o.data_in = data_i;
                end

                default: membus_o.data_in = '0;
            endcase
        end
    end

    //assign the memory read data
    always_comb begin : read_data_shift
        data_o = '0; //default

        if(en_i && !data_dir_i) begin
            unique case(data_type_i)
                2'b00: begin //read byte
                    unique case(address_i[1:0])
                        2'b00: begin
                            data_o = sign_extend_i
                                ? {{24{membus_o.data_out[7]}}, membus_o.data_out[7:0]}
                                : {24'b0, membus_o.data_out[7:0]};
                        end

                        2'b01: begin
                            data_o = sign_extend_i
                                ? {{24{membus_o.data_out[15]}}, membus_o.data_out[15:8]}
                                : {24'b0, membus_o.data_out[15:8]};
                        end

                        2'b10: begin
                            data_o = sign_extend_i
                                ? {{24{membus_o.data_out[23]}}, membus_o.data_out[23:16]}
                                : {24'b0, membus_o.data_out[23:16]};
                        end

                        2'b11: begin
                            data_o = sign_extend_i
                                ? {{24{membus_o.data_out[31]}}, membus_o.data_out[31:24]}
                                : {24'b0, membus_o.data_out[31:24]};
                        end
                    endcase
                end

                2'b01: begin //read halfword
                    unique case(address_i[1])
                        1'b0: begin
                            data_o = sign_extend_i
                                ? {{16{membus_o.data_out[15]}}, membus_o.data_out[15:0]}
                                : {16'b0, membus_o.data_out[15:0]};
                        end

                        1'b1: begin
                            data_o = sign_extend_i
                                ? {{16{membus_o.data_out[31]}}, membus_o.data_out[31:16]}
                                : {16'b0, membus_o.data_out[31:16]};
                        end
                    endcase
                end

                2'b10: begin //read word
                    data_o = membus_o.data_out;
                end

                default: data_o = '0;
            endcase
        end
    end

endmodule
