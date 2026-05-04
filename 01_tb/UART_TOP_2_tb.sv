module UART_TOP_2_tb;
  logic I_CLK;
  logic I_RESET_N;
  logic I_BCLK_MODE;
  logic [3:0] I_BAUD_RATE;
  logic I_CNT_EN;
  logic I_CNT_LOAD;
  logic I_WR_EN;
  logic I_RD_EN;
  logic [7:0] I_WDATA;
  logic I_RX_IN;
  logic O_TX_OUT;
  logic [15:0] O_RDATA;

  UART_TOP DUT(.*);

  // ==========================================
  // Parameters & Scoreboard Queues
  // ==========================================
  real BIT_PERIOD = 104167; // Equivalent to 9600 baud
  
  logic [7:0] scb_tx_expected[$]; // Queue to store expected TX data
  logic [7:0] scb_rx_expected[$]; // Queue to store expected RX data
  
  int err_count = 0; // Error counter

  // ==========================================
  // Clock Generation
  // ==========================================
  initial begin
    I_CLK = 0;
    forever #10 I_CLK = ~I_CLK;
  end

  // ==========================================
  // Main Test Sequence
  // ==========================================
  initial begin
    // Initialization
    initialize();
    reset_dut();
    load_baud_rate(1'b0, 4'h0); 
    
    // Start background monitors
    fork
      tx_monitor();
    join_none // Non-blocking, allows the main thread to continue

    // --- TC_SANITY_TX: Test Transmission ---
    $display("\n--- Starting TC_SANITY_TX ---");
    test_tx_byte(8'hA5);
    test_tx_byte(8'h33);
    # (BIT_PERIOD * 12); // Wait for TX to complete
    
    // --- TC_SANITY_RX: Test Reception ---
    $display("\n--- Starting TC_SANITY_RX ---");
    test_rx_byte(8'h22);
    test_rx_byte(8'h66);


    // --- TC_FULL_DUPLEX: Test Simultaneous TX and RX ---
    $display("\n--- Starting TC_FULL_DUPLEX ---"); 
    // Use fork...join to run TX and RX tasks in parallel
    fork
      // Thread 1: DUT transmits data out
      begin
        test_tx_byte(8'hCC);
      end
      
      // Thread 2: DUT receives data in
      begin
        #5 test_rx_byte(8'hAA);
      end
    join
    # (BIT_PERIOD * 2); // Small buffer to ensure everything settles

    // --- Report Results ---
    $display("\n==================================");
    if (err_count == 0)
      $display("PASSED: Simulation completed with zero errors!");
    else
      $display("FAILED: Simulation finished with %0d error(s)!", err_count);
    $display("==================================\n");
 
    //$finish;
  end

  // ==========================================
  // Tasks (Drivers)
  // ==========================================
  task automatic initialize();
    I_RX_IN     = 1'b1;
    I_WDATA     = 8'h00;
    I_BCLK_MODE = 1'b0;
    I_BAUD_RATE = 4'h0;
    I_CNT_EN    = 1'b0;
    I_CNT_LOAD  = 1'b0;
    I_WR_EN     = 1'b0;
    I_RD_EN     = 1'b0;
  endtask

  task automatic reset_dut();
    I_RESET_N = 1'b0;
    repeat (5) @(posedge I_CLK);
    I_RESET_N = 1'b1;
  endtask

  task automatic load_baud_rate(input mode, input [3:0] baud_rate);
    I_BAUD_RATE = baud_rate;
    I_BCLK_MODE = mode;
    I_CNT_EN = 1'b1;
    #20;
    I_CNT_LOAD = 1'b1;
    #20;
    I_CNT_LOAD = 1'b0;
  endtask

  // Task to drive data into DUT for transmission and notify the Scoreboard
  task automatic test_tx_byte(input [7:0] data);
    scb_tx_expected.push_back(data); // Push to expected queue
    I_WDATA = data;
    #5;
    I_WR_EN = 1'b1;
    #20;
    I_WR_EN = 1'b0;
  endtask

  // Task to inject serial data into RX pin and verify output RDATA
  task automatic test_rx_byte(input [7:0] data);
    $display("[Driver] Injecting RX Byte: 0x%h into I_RX_IN", data);
    
    // Inject Start bit
    I_RX_IN = 1'b0;
    #(BIT_PERIOD);
    
    // Inject Data bits (LSB first)
    for (int i = 0; i < 8; i++) begin
      I_RX_IN = data[i];
      #(BIT_PERIOD);
    end
    
    // Inject Stop bit
    I_RX_IN = 1'b1;
    #(BIT_PERIOD);
    
   // Call checker immediately after reception
    check_rx_scoreboard(data);

    @(posedge I_CLK);
    I_RD_EN = 1'b1; // Trigger read after frame is sent
    @(posedge I_CLK);
    I_RD_EN = 1'b0; // Disable read after frame is sent

  endtask

  // ==========================================
  // Monitors & Scoreboard Checkers
  // ==========================================
  
  // TX Monitor: Observes O_TX_OUT to assemble bits
  task automatic tx_monitor();
    logic [7:0] sampled_data;
    forever begin
      @(negedge O_TX_OUT); // Wait for Start bit (pulled to 0)
      #(BIT_PERIOD / 2.0); // Shift to the middle of the bit period for accurate sampling
      
      if (O_TX_OUT !== 1'b0) begin
        $error("[TX Monitor] Invalid Start Bit!");
        err_count++;
      end
      
      // Sample 8 data bits
      for (int i = 0; i < 8; i++) begin
        #(BIT_PERIOD);
        sampled_data[i] = O_TX_OUT;
      end
      
      #(BIT_PERIOD); // Jump to Stop bit
      if (O_TX_OUT !== 1'b1) begin
        $error("[TX Monitor] Missing Stop Bit!");
        err_count++;
      end
      
      // Send assembled data to Checker
      check_tx_scoreboard(sampled_data);
    end
  endtask

  // TX Comparison Function
  function automatic void check_tx_scoreboard(input [7:0] actual_data);
    logic [7:0] expected_data;
    if (scb_tx_expected.size() == 0) begin
      $error("[Scoreboard TX] Received data 0x%h but expected queue is empty!", actual_data);
      err_count++;
    end else begin
      expected_data = scb_tx_expected.pop_front(); // Pop data from queue
      if (actual_data === expected_data) begin
        $display("[Scoreboard TX] PASSED - Received correct data: 0x%h", actual_data);
      end else begin
        $error("[Scoreboard TX] FAILED - Expected: 0x%h | Actual: 0x%h", expected_data, actual_data);
        err_count++;
      end
    end
  endfunction

  // RX Comparison Function
  function automatic void check_rx_scoreboard(input [7:0] expected_data);
    // In a standard environment, we would wait for an O_RX_VALID flag. 
    // Since the DUT lacks it, we check O_RDATA directly after injecting the frame.
    logic [7:0] actual_data = O_RDATA[7:0]; 
    if (actual_data === expected_data) begin
      $display("[Scoreboard RX] PASSED - Read correct O_RDATA: 0x%h", actual_data);
    end else begin
      $error("[Scoreboard RX] FAILED - Expected: 0x%h | Actual: 0x%h", expected_data, actual_data);
      err_count++;
    end
  endfunction

endmodule: UART_TOP_2_tb