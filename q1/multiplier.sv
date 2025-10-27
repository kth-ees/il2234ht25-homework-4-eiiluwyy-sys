module multiplier
( input  logic [15:0] multiplier_input_a, 
  input  logic [15:0] multiplier_input_b, 
  input  logic select_output,
  output logic [15:0] multiplier_output
);
 
  logic [31:0] multi_outcomes_32;

always_comb begin 
    multi_outcomes_32= multiplier_input_a * multiplier_input_b;
    if (select_output==1)
    multiplier_output = multi_outcomes_32[31:16];
    else
    multiplier_output = multi_outcomes_32[23:8];
end

endmodule