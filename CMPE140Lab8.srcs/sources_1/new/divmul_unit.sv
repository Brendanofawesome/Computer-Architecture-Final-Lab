//Defines the multicycle div/mul unit
//  (FUTURE FEATURE) uses booth multiplication
//  (FUTURE FEATURE) uses non-resoring devision

import shared_definitions_pkg::*;

module divmul_unit(
    //state control
    input logic clk,
    input logic rst_n,

    //function control
    input divmul_function_e op_i,
    input logic signed_mode_i,
    input logic start_i,        //strobe signal

    //data input
    input logic [31:0] d1_i,
    input logic [31:0] d2_i,

    //HILO register
    output logic ready_o,       //latch signal
    output logic [31:0] hi_o,
    output logic [31:0] lo_o
    );

    //state storage
    divmul_function_e current_function;
    logic latched_signed_mode;  //1=>signed
    logic [31:0] latched_d1;
    logic [31:0] latched_d2;

    always_ff @(posedge clk) begin : duvmul_calc

        //RESET LOGIC
        if(!rst_n) begin
            //reset state
            hi_o <= 0;
            lo_o <= 0;
            ready_o <= 1;

        //START LOGIC
        end else if (start_i) begin
            //reset control state
            ready_o <= 0;

            //latch inputs
            current_function <= op_i;
            latched_signed_mode <= signed_mode_i;
            latched_d1 <= d1_i;
            latched_d2 <= d2_i;

        //CALCULATION LOGIC
        end else if (!ready_o) begin
            unique case(current_function)
                //MULTIPLICATION
                DIVMUL_MULT: begin
                        if(latched_signed_mode == 0)
                            {hi_o, lo_o} <= $unsigned(latched_d1) * $unsigned(latched_d2);
                        else
                            {hi_o, lo_o} <= $signed(latched_d1) * $signed(latched_d2);

                        ready_o <= 1;
                    end

                //DIVISION
                DIVMUL_DIV: begin
                        if(latched_signed_mode == 0) begin
                            lo_o <= $unsigned(latched_d1) / $unsigned(latched_d2);
                            hi_o <= $unsigned(latched_d1) % $unsigned(latched_d2);
                        end else begin
                            lo_o <= $signed(latched_d1) / $signed(latched_d2);
                            hi_o <= $signed(latched_d1) % $signed(latched_d2);
                        end

                        ready_o <= 1;
                    end
            endcase
        end
    end
endmodule
