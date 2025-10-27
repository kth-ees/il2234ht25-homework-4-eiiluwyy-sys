module mux (
    input  logic [15:0] in_a,
    input  logic [15:0] in_b,
    input  logic        select_mux,
    output logic [15:0] out
);
    always_comb begin
        case (select_mux)
            1'b0: out = in_a;
            1'b1: out = in_b;
            default: out = in_a; // Default case
        endcase
    end
endmodule