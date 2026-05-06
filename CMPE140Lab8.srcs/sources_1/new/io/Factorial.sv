`timescale 1ns / 1ps

module Factorial(
    input [3:0] hex_in,
    input go,
    input clk,
    input rst_n,
    output [31:0] hex_out,
    output reg done,
    output reg error
    );

    reg [31:0] factorial_out;
    reg [3:0] it_count;

    // Always drive output; `done` indicates when result is valid
    assign hex_out = factorial_out;

    reg [1:0] state;
    localparam bit [1:0] StateIdle = 2'b00;
    localparam bit [1:0] StateError = 2'b01;
    localparam bit [1:0] StateDone = 2'b10;
    localparam bit [1:0] StateRunning = 2'b11;

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= StateIdle;
            done <= 0;
            error <= 0;
            it_count <= 0;
            factorial_out <= 0;
        end else if (go) begin
            // start request: initialize or error-check
            done <= 0;
            error <= 0;
            if (hex_in > 12) state <= StateError;
            else begin
                state <= StateRunning;
                it_count <= hex_in;
                factorial_out <= 1;
            end
        end else begin
            case (state)
                StateIdle: begin
                    done <= 0;
                    error <= 0;
                end
                StateError: begin
                    done <= 0;
                    error <= 1;
                end
                StateDone: begin
                    done <= 1;
                    error <= 0;
                end
                StateRunning: begin
                    done <= 0;
                    error <= 0;
                    if (it_count < 2) state <= StateDone;
                    else begin
                        factorial_out <= it_count * factorial_out;
                        it_count <= it_count - 1;
                    end
                end
                default: state <= StateIdle;
            endcase
        end
    end
endmodule
