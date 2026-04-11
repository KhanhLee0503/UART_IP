module UART_TOP_tb;
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

//============================
// Clock Generation
//===========================
initial begin
  I_CLK = 0;
  forever begin
    #10 I_CLK = ~I_CLK;
  end
end

initial begin
  I_RX_IN   = 1'b1; // Idle state for UART
  I_WDATA    = 8'h00;
  I_BCLK_MODE = 1'b0;
  I_BAUD_RATE = 4'h0; // Example baud rate value
  I_CNT_EN    = 1'b0;
  I_CNT_LOAD  = 1'b0;
  I_WR_EN     = 1'b0;
  I_RD_EN     = 1'b0;
  I_RESET_N = 1'b0;
  #20; 
  I_RESET_N = 1'b1;

  load_baud_rate(1'b0, 4'h0); // Load baud rate for 9600
  //#100;
  //load_data(8'hA5); // Load data to be transmitte
  #100;
  send_byte(8'hA5); // Simulate receiving a byte
end

task automatic load_baud_rate(input mode, input [3:0] baud_rate);
  begin
    I_BAUD_RATE = baud_rate; // Set baud rate
    I_BCLK_MODE = mode;
    I_CNT_EN = 1'b1;
    #20; // Wait for one clock cycle
    I_CNT_LOAD = 1'b1;
    #20;
    I_CNT_LOAD = 1'b0;
  end
endtask

task automatic load_data(input [7:0] data);
  begin
    I_WDATA = data;
    I_WR_EN = 1'b1;
    #20; // Wait for one clock cycle
    I_WR_EN = 1'b0;
  end
endtask

task automatic send_byte(input [7:0] data);
  begin
    // Start bit
    I_RX_IN = 1'b0;
    #104167; // Wait for one bit duration (assuming 9600 baud rate)

    // Data bits (LSB first)
    for (int i = 0; i < 8; i++) begin
      I_RX_IN = data[i];
      #104167; // Wait for one bit duration
    end

    // Stop bit
    I_RX_IN = 1'b1;
    #104167; // Wait for one bit duration
  end
endtask

endmodule: UART_TOP_tb