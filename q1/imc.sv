module imc
  #(parameter INPUT_W = 16,
    parameter OUTPUT_W = 16)
(
    input  logic                   clk,
    input  logic                   rst_n,     
    input  logic                   start,
    input  logic [INPUT_W-1:0]     aIn,
    input  logic [INPUT_W-1:0]     bIn,
    input  logic [INPUT_W-1:0]     cIn,
    input  logic [INPUT_W-1:0]     dIn,
    output logic                   ready,
    output logic [OUTPUT_W-1:0]    aOut,
    output logic [OUTPUT_W-1:0]    bOut,
    output logic [OUTPUT_W-1:0]    cOut,
    output logic [OUTPUT_W-1:0]    dOut,
    output logic                   aOut_sign,
    output logic                   bOut_sign,
    output logic                   cOut_sign,
    output logic                   dOut_sign
    
);

  //  State encoding 
  typedef enum logic [2:0] {
    S_IDLE,
    S_LOAD,
    S_DET,
    S_RECIP,
    S_OUT_0,   // compute aOut,bOut
    S_OUT_1,   // compute cOut,dOut
    S_DONE
  } state_t;

  state_t state, state_n;

  // Internal registers 
  logic [15:0] a_r, b_r, c_r, d_r;

  // determinant components
 /*logic [15:0] ad_int, bc_int;
  logic signed [16:0] det_signed;*/

  logic [16:0] det_mag_wide;
  logic [15:0] det_abs;
  logic        det_sign;

  // reciprocal (Q1.8)
  logic [8:0]  recip_q1_8;
  logic [15:0] recip_q1_8_expand_16bits;

  // numerators
  logic [15:0] numA_abs, numB_abs, numC_abs, numD_abs;
  logic        numA_sign, numB_sign, numC_sign, numD_sign;

  // outputs
  logic [15:0] aOut_r, bOut_r, cOut_r, dOut_r;
  logic        aSign_r, bSign_r, cSign_r, dSign_r;

  // ====== Multiplier resources ======
  logic [15:0] mul1_in_a, mul1_in_b;
  logic [15:0] mul2_in_a, mul2_in_b;
  logic        mul_sel_det; // 1=[31:16], 0=[23:8]
  logic [15:0] mul1_out, mul2_out;

  logic [16:0] det_mag_comb;
  logic        det_sign_comb;

  multiplier u_mul1(
    .multiplier_input_a(mul1_in_a),
    .multiplier_input_b(mul1_in_b),
    .select_output     (mul_sel_det),
    .multiplier_output (mul1_out)
  );

  multiplier u_mul2(
    .multiplier_input_a(mul2_in_a),
    .multiplier_input_b(mul2_in_b),
    .select_output     (mul_sel_det),
    .multiplier_output (mul2_out)
  );

  // ====== Combinational next-state and datapath control ======

  always_comb begin
    det_sign_comb = (($signed({1'b0, mul1_out}) - $signed({1'b0, mul2_out})) < 0);
    det_mag_comb  = (mul1_out >= mul2_out) ? ({1'b0, mul1_out} - {1'b0, mul2_out}) : ({1'b0, mul2_out} - {1'b0, mul1_out});
  end

  always_comb begin
    // defaults
    state_n     = state;
    ready       = 1'b0;
    mul1_in_a   = 16'd0;
    mul1_in_b   = 16'd0;
    mul2_in_a   = 16'd0;
    mul2_in_b   = 16'd0;
    mul_sel_det = 1'b1; // default: [31:16]

    case (state)
      S_IDLE: begin
        ready = 1'b1;
        if (start) state_n = S_LOAD;
      end

      S_LOAD: begin
        state_n = S_DET;
      end

      // ===== Determinant stage =====
      S_DET: begin
        // inputs are Q8.8£¬directly multiply and select [31:16] to get integer ad, bc
        mul1_in_a   = a_r;
        mul1_in_b   = d_r;
        mul2_in_a   = b_r;
        mul2_in_b   = c_r;
        mul_sel_det = 1'b1; // integer product
        state_n     = S_RECIP;
      
      end

      // ===== Reciprocal prepare stage =====
      S_RECIP: begin
        state_n = S_OUT_0;
      end

      // ===== Outputs part 1 =====
      S_OUT_0: begin
        // when mul_sel_det = 0, select [23:8] so the multiplier output (|numA|*expand 16bit y) / (256)  and get the true claculate outcomes
        mul_sel_det = 1'b0;
        mul1_in_a   = numA_abs << 8;        
        
         /* make |d| 16bits lowest 8bits integer Q16.0  hxxxx -> h00xx = |numA|/256
        to Q8.8 form by left shift  h00xx -> hxx00       */

        mul1_in_b   = recip_q1_8_expand_16bits;  // Q8.8 h0x xx
        mul2_in_a   = numB_abs << 8;         // |b|
        mul2_in_b   = recip_q1_8_expand_16bits;
        state_n     = S_OUT_1;
      end

      // ===== Outputs part 2 =====
      S_OUT_1: begin
        mul_sel_det = 1'b0;
        mul1_in_a   = numC_abs <<8 ; // |c|
        mul1_in_b   = recip_q1_8_expand_16bits; //|b|
        mul2_in_a   = numD_abs <<8 ; // |a|
        mul2_in_b   = recip_q1_8_expand_16bits; //|d|
        state_n     = S_DONE;
      end

      // ===== Done =====
      S_DONE: begin
        ready = 1'b1;
        if (start) state_n = S_LOAD;
      end

      default: state_n = S_IDLE;
    endcase
  end

  // ====== Sequential logic ======
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= S_IDLE;
      a_r <= '0; b_r <= '0; c_r <= '0; d_r <= '0;
      /*det_abs <= '0;
      det_sign <= 1'b0;*/

      /* ad_int <= '0; bc_int <= '0; */

      aOut_r <= '0; bOut_r <= '0; cOut_r <= '0; dOut_r <= '0;
      aSign_r <= 1'b0; bSign_r <= 1'b0; cSign_r <= 1'b0; dSign_r <= 1'b0;

      det_mag_wide <= 17'h0;
      det_abs <= 16'h0;
      end 
      else begin
      state <= state_n;

      case (state)
        // ---------- Load inputs ----------
        S_LOAD: begin
          a_r <= aIn;
          b_r <= bIn;
          c_r <= cIn;
          d_r <= dIn;
        end

        // ---------- Determinant ----------
        S_DET: begin
         /* ad_int <= mul1_out;
          bc_int <= mul2_out;
          det_signed <= $signed({1'b0, mul1_out}) - $signed({1'b0, mul2_out});*/

        /*det_sign   <= ($signed({1'b0, mul1_out}) - $signed({1'b0, mul2_out})) < 0;

          det_mag_wide <= (mul1_out >= mul2_out) ?
                           ({1'b0, mul1_out} - {1'b0, mul2_out}) :({1'b0, mul2_out} - {1'b0, mul1_out});*/

          det_sign <= det_sign_comb;
          det_mag_wide <= det_mag_comb;
          det_abs <= det_mag_comb[15:0];
        end

        // ---------- Reciprocal ----------
        S_RECIP: begin
          // prepare numerators (restore to integer range by >>8)
          numA_abs  <= (d_r[15] ? ((~d_r + 16'd1) >> 8) : (d_r >> 8)); // |d| 16bits fix point without fractional part convert to 16bits interger wich only lowest 8bits valid 
          numA_sign <= d_r[15];                                        // sign now keep the same with origianl d

          numB_abs  <= (b_r[15] ? ((~b_r + 16'd1) >> 8) : (b_r >> 8)); // |b|
          numB_sign <= (b_r == 16'd0) ? 1'b0 : 1'b1;                   // sign now revese from the orignal b

          numC_abs  <= (c_r[15] ? ((~c_r + 16'd1) >> 8) : (c_r >> 8)); // |c|
          numC_sign <= (c_r == 16'd0) ? 1'b0 : 1'b1;                   // reverse

          numD_abs  <= (a_r[15] ? ((~a_r + 16'd1) >> 8) : (a_r >> 8)); // |a|
          numD_sign <= a_r[15];                                        // keep same
        end

        // ---------- Output group 1 ----------
        S_OUT_0: begin
          aOut_r <= mul1_out; // Q8.8  |d|*(1/|det|)
          bOut_r <= mul2_out; // Q8.8  |b|*(1/|det|)
          aSign_r <= (numA_sign ^ det_sign); // d's sign XOR det(A)'s sign to get the final sign
          bSign_r <= (numB_sign ^ det_sign); // 
        end

        // ---------- Output group 2 ----------
        S_OUT_1: begin
          cOut_r <= mul1_out;
          dOut_r <= mul2_out;
          cSign_r <= (numC_sign ^ det_sign);
          dSign_r <= (numD_sign ^ det_sign);
        end

        default: ;
      endcase
    end
  end

  // Reciprocal (combinational) 
  reciprocal u_recip(
    .x(det_abs),
    .y(recip_q1_8)
  );

  assign recip_q1_8_expand_16bits = {7'b0, recip_q1_8};

  //  Outputs 
  assign aOut = aOut_r;
  assign bOut = bOut_r;
  assign cOut = cOut_r;
  assign dOut = dOut_r;
  assign aOut_sign = aSign_r;
  assign bOut_sign = bSign_r;
  assign cOut_sign = cSign_r;
  assign dOut_sign = dSign_r;

endmodule
