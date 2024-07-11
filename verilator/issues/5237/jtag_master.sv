// Copyright Tobias Kaiser
// Originally for PTC1.

interface jtag_master;

  logic tck;
  logic tms;
  logic tdi;
  logic tdo;
  logic trst_n;

  localparam verbose = '0;

  // 50 MHz TCK
  // -----------

  always begin
    tck = 1'b0;
    #10000;
    tck = 1'b1;
    #10000;
  end

  // JTAG tasks
  // ----------

  // All signals going to the DUT are written on falling edge and read by the
  // DUT on the rising edge; all signals from the DUT are written on the
  // falling edge by the DUT and read by this jtag_master on the rising edge.

  logic [4:0] ir_stored;
  logic ir_stored_valid;

  initial begin
    ir_stored_valid <= '0;
    ir_stored       <= '0;
  end

  task set_ir(input logic [4:0] ir_val);
    if (!ir_stored_valid || (ir_stored != ir_val)) begin
      set_ir_force(ir_val);
    end
  endtask

  task set_ir_force(input logic [4:0] ir_val);
    @(negedge tck);
    tms <= 1'b1;  // Select-DR-Scan
    @(negedge tck);
    tms <= 1'b1;  // Select-IR-Scan
    @(negedge tck);
    tms <= 1'b0;  // Capture-IR

    @(negedge tck);
    tms <= 1'b0;  // Shift-IR
    @(negedge tck);
    tms <= 1'b0;  // Shift-IR
    tdi <= ir_val[0];
    @(negedge tck);
    tms <= 1'b0;  // Shift-IR
    tdi <= ir_val[1];
    @(negedge tck);
    tms <= 1'b0;  // Shift-IR
    tdi <= ir_val[2];
    @(negedge tck);
    tms <= 1'b0;  // Shift-IR
    tdi <= ir_val[3];
    @(negedge tck);
    tms <= 1'b1;  // Exit1-IR
    tdi <= ir_val[4];
    @(negedge tck);
    tms <= 1'b1;
    tdi <= 1'b0;  // Update-IR
    @(negedge tck);
    tms <= 1'b0;  // Run-Test/Idle
    @(negedge tck);
    if (verbose) $display("[jtag] set_ir %x", ir_val);

    ir_stored_valid <= '1;
    ir_stored       <= ir_val;
  endtask

  task cycle_dr_32(output logic [31:0] data_o, input logic [31:0] data_i);
    int i;

    @(negedge tck);
    tms <= 1'b1;  // Select-DR-Scan
    @(negedge tck);
    tms <= 1'b0;  // Capture-DR

    @(negedge tck);
    tms <= 1'b0;  // Shift-DR
    @(negedge tck);
    tms <= 1'b0;  // Shift-DR
    tdi <= data_i[0];
    for (i = 1; i < $size(data_i) - 1; i++) begin
      @(posedge tck);
      data_o[i-1] <= tdo;
      @(negedge tck);
      tms <= 1'b0;  // Shift-DR
      tdi <= data_i[i];
    end
    @(posedge tck);
    data_o[$size(data_i)-2] <= tdo;
    @(negedge tck);
    tms <= 1'b1;  // Exit1-DR
    tdi <= data_i[$size(data_i)-1];
    @(posedge tck) data_o[$size(data_i)-1] <= tdo;
    @(negedge tck);
    tms <= 1'b1;  // Update-DR
    tdi <= '0;
    @(negedge tck);
    tms <= 1'b0;  // Run-Test/Idle
    @(negedge tck);

    if (verbose) begin
      $display("[jtag] cycle_dr_32 wr: 0x%08x; rd: 0x%08x", data_i, data_o);
    end
  endtask


  task cycle_dr_dmi(output dm::dmi_t data_o, input dm::dmi_t data_i);
    int i;

    @(negedge tck);
    tms <= 1'b1;  // Select-DR-Scan
    @(negedge tck);
    tms <= 1'b0;  // Capture-DR

    @(negedge tck);
    tms <= 1'b0;  // Shift-DR
    @(negedge tck);
    tms <= 1'b0;  // Shift-DR
    tdi <= data_i[0];
    for (i = 1; i < $size(data_i) - 1; i++) begin
      @(posedge tck);
      data_o[i-1] <= tdo;
      @(negedge tck);
      tms <= 1'b0;  // Shift-DR
      tdi <= data_i[i];
    end
    @(posedge tck);
    data_o[$size(data_i)-2] <= tdo;
    @(negedge tck);
    tms <= 1'b1;  // Exit1-DR
    tdi <= data_i[$size(data_i)-1];
    @(posedge tck) data_o[$size(data_i)-1] <= tdo;
    @(negedge tck);
    tms <= 1'b1;  // Update-DR
    @(negedge tck);
    tms <= 1'b0;  // Run-Test/Idle
    @(negedge tck);

    if (verbose) begin
      $display(
          "[jtag] cycle_dr_dmi wr: {addr: 0x%02x, data: 0x%08x, op: %d}; rd: {addr: 0x%02x, data: 0x%08x, op: %d}",
          data_i.address, data_i.data, data_i.op, data_o.address, data_o.data, data_o.op);
    end
  endtask

  task reset();
    tdi             <= 1'b0;
    trst_n          <= 1'b0;
    tms             <= 1'b0;

    ir_stored_valid <= '0;
    ir_stored       <= '0;

    @(negedge tck);
    @(negedge tck);
    @(negedge tck);
    trst_n <= 1'b1;  // Test-Logic-Reset
    @(negedge tck);
    @(negedge tck);
    tms <= 1'b0;  // Run-Test/Idle
    @(negedge tck);
    if (verbose) $display("[jtag] reset");
  endtask

  task cycle_idle();
    @(negedge tck);
  endtask

endinterface
