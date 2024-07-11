module tb_hello_world;

  // Signals
  logic clk;
  jtag_master jtag();
  
  // Clock generation
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end
  
  // Instantiate the module under test
  rvlab_tests uut (
    .jtag(jtag),
    .clk_i(clk)
  );

  // Testbench
  always begin
    $display("Hello, World!");

    // Run the test
    uut.test_idcode();

    $finish;
  end

endmodule

