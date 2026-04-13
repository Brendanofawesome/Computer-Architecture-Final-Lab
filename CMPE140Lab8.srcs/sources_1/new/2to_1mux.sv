module mux2to1 #(
    parameter WIDTH = 1  //flexibility for width
)(
    input  logic [WIDTH-1:0] a,    // in 1
    input  logic [WIDTH-1:0] b,    // in 2
    input  logic             sel,  // sel signal
    output logic [WIDTH-1:0] y     // output
);

    assign y = sel ? b : a;

endmodule