// Copyright Tobias Kaiser
// Originally for PTC1.

module rvlab_tests (
          jtag_master jtag,
    input logic       clk_i
);



  // Test IDCODE
  // -----------

  task test_idcode();
    bit [31:0] idcode_read;
    int errcnt;

    errcnt = 0;

    jtag.reset();
    jtag.cycle_dr_32(.data_o(idcode_read), .data_i('0));

    if (idcode_read != 0) begin
      $error("IDCODE incorrect!");
      errcnt++;
    end

  endtask

endmodule
