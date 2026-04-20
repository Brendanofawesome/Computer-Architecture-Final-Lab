interface memory_bus_if();
    logic        select;
    logic [31:0] data_in;
    logic        write_enable;

    logic [31:0] data_out;

    modport Controller (output data_in, write_enable, select,
                        input data_out);

    modport Peripheral (output data_out,
                        input data_in, write_enable, select);
endinterface
