module comparator

( input  logic [15:0] comparator_input_a,  comparator_input_b, 
  output logic S, E, G
);
 
always_comb begin 
   {S, E, G} =3'b000;
   if      (comparator_input_a<comparator_input_b)    S=1'b1;
   else if (comparator_input_a>comparator_input_b)    G=1'b1;
   else if (comparator_input_a == comparator_input_b) E=1'b1;
end

endmodule