module branch_precalc (
    input  logic [31:2] src1,     
    input  logic [15:0] src2,     
 
    output logic [31:2] q         
);
 
    logic signed [29:0] imm_sext;
    assign imm_sext = {{14{src2[15]}}, src2[15:0]};
 
    assign q = $signed(src1) + imm_sext;
 
endmodule