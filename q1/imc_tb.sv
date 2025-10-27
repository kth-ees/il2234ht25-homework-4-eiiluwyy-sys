`timescale 1ns/1ps

module imc_tb;

  logic clk;
  logic rst_n;
  logic start;
  logic [15:0] aIn, bIn, cIn, dIn;
  logic ready;
  logic [15:0] aOut, bOut, cOut, dOut;
  logic aOut_sign, bOut_sign, cOut_sign, dOut_sign;


  always #5 clk = ~clk;

  imc dut (
    .clk        (clk),
    .rst_n      (rst_n),
    .start      (start),
    .aIn        (aIn),
    .bIn        (bIn),
    .cIn        (cIn),
    .dIn        (dIn),
    .ready      (ready),
    .aOut       (aOut),
    .bOut       (bOut),
    .cOut       (cOut),
    .dOut       (dOut),
    .aOut_sign  (aOut_sign),
    .bOut_sign  (bOut_sign),
    .cOut_sign  (cOut_sign),
    .dOut_sign  (dOut_sign)
  );


  initial begin
    clk = 0;
    rst_n = 0;
    start = 0;
    aIn = 0;
    bIn = 0;
    cIn = 0;
    dIn = 0;


    repeat (2) @(posedge clk);
    rst_n = 1;
    @(posedge clk);


    wait (ready == 1);
    @(posedge clk);


    // test£ºmatrix [[1, 1], [1, 2]]
    // det = 1 ¡ú inv = [[2, -1], [-1, 1]]

    aIn = 16'h0100; // 1.0 (Q8.8)
    bIn = 16'h0100;
    cIn = 16'h0100;
    dIn = 16'h0200; // 2.0
    start = 1; 
    @(posedge clk); 
    start = 0;

    wait (ready == 0); // 
    wait (ready == 1); //
    @(posedge clk);

    $display("\n CASE 1 ");
    $display("aOut = %h (sign=%b)", aOut, aOut_sign);
    $display("bOut = %h (sign=%b)", bOut, bOut_sign);
    $display("cOut = %h (sign=%b)", cOut, cOut_sign);
    $display("dOut = %h (sign=%b)", dOut, dOut_sign);



    wait (ready == 1);
    aIn = 16'h0200; // 2
    bIn = 16'h0000;
    cIn = 16'h0000;
    dIn = 16'h0300; // 3
    start = 1; @(posedge clk); start = 0;

    wait (ready == 0);
    wait (ready == 1);
    @(posedge clk);

    $display("\n=== CASE 2 ===");
    $display("aOut = %h (sign=%b)", aOut, aOut_sign);
    $display("bOut = %h (sign=%b)", bOut, bOut_sign);
    $display("cOut = %h (sign=%b)", cOut, cOut_sign);
    $display("dOut = %h (sign=%b)", dOut, dOut_sign);


    wait (ready == 1);
    aIn = 16'h0200; // 2
    bIn = 16'h0500;
    cIn = 16'h0400;
    dIn = 16'h0300; // 3
    start = 1; @(posedge clk); start = 0;

    wait (ready == 0);
    wait (ready == 1);
    @(posedge clk);

    $display("\n=== CASE 3 ===");
    $display("aOut = %h (sign=%b)", aOut, aOut_sign);
    $display("bOut = %h (sign=%b)", bOut, bOut_sign);
    $display("cOut = %h (sign=%b)", cOut, cOut_sign);
    $display("dOut = %h (sign=%b)", dOut, dOut_sign);

    $display("\nAll tests done.");
    $finish;
  end

endmodule
