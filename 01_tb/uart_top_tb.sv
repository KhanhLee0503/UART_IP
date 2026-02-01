`timescale 1ns/1ns
module uart_top_tb();
reg clk;
reg rst_n;
reg wr_en;
reg [1:0] tlen;  // 00: 5bit | 01: 6bit | 10: 7bit | 11: 8bit
reg parity_en;
reg parity_type; //0-even, 1-odd
reg bclk_mode;   //0: x16 speed | 1: x13 speed
reg [7:0] wdata;
reg RXD;
wire [7:0] rdata;
wire TXD;
wire parity_err;
wire frame_err;


uart_top DUT(.*);

reg [9:0] trans_data;

always@(*) begin
    RXD = TXD;
end

initial begin
    clk = 0;
    forever begin
        #18.5 clk = ~clk;
    end
end

always @(posedge TXD or negedge TXD) begin
    trans_data <= {trans_data[8:0], TXD};
end


initial begin
    trans_data = 0;
    wr_en = 0;
    tlen = 2'b00;
    parity_en = 0;
    parity_type = 0;
    bclk_mode = 0;
    wdata = 8'd0;
    rst_n = 1'b0;
    #30;
    rst_n = 1'b1;
    RXD = 1;
    @(posedge clk);
    #1



    $display(" ");
    $display("-------------------ITEM1:Transfering and Receiving a random character from itself !! (8bit, no parity) ------------------");
    tlen = 2'b11;   //8bit
    bclk_mode = 0;  //x16
    wdata = 8'heb;
    wr_en = 1;
    $display("Transmitting Byte: %h", wdata);
    $display("Transmitting Start");
    @(posedge clk);
    #1;
    @(rdata);
    if(rdata == wdata)
        $display("PASSED: Transmission Completed: %h", rdata);   
    else
        $display("==> FAILED | Data Mismatch! Received Data: %h, Expected Data: %h", rdata, wdata);


    $display(" ");
    $display("-------------------ITEM2: Transfering and Receiving a random character from itself !! (7bit, no parity) ------------------");
    tlen = 2'b10;   //7bit
    bclk_mode = 0;  //x16
    wdata = 8'heb;
    wr_en = 1;
    $display("Transmitting Byte: %h", wdata);
    $display("Transmitting Start");
    @(posedge clk);
    #1;
    @(rdata);
    if(rdata == {1'b0,wdata[6:0]})
        $display("PASSED: Transmission Completed: %h", rdata);   
    else
        $display("==> FAILED | Data Mismatch! Received Data: %h, Expected Data: %h", rdata, {1'b0,wdata[6:0]});


    $display(" ");
    $display("-------------------ITEM3: Transfering and Receiving a random character from itself !! (6bit, no parity) ------------------");
    tlen = 2'b01;   //6bit
    bclk_mode = 0;  //x16
    wdata = 8'heb;
    wr_en = 1;
    $display("Transmitting Byte: %h", wdata);
    $display("Transmitting Start");
    @(posedge clk);
    #1;
    @(rdata);
    if(rdata == {2'b0,wdata[5:0]})
        $display("PASSED: Transmission Completed: %h", rdata);   
    else
        $display("==> FAILED | Data Mismatch! Received Data: %h, Expected Data: %h", rdata, {2'b0,wdata[5:0]});
  
  
    $display(" ");
    $display("-------------------ITEM4: Transfering and Receiving a random character from itself !! (5bit, no parity) ------------------");
    tlen = 2'b00;   //5bit
    bclk_mode = 0;  //x16
    wdata = 8'heb;
    wr_en = 1;
    $display("Transmitting Byte: %h", wdata);
    $display("Transmitting Start");
    @(posedge clk);
    #1;
    @(rdata);
    if(rdata == {3'b0,wdata[4:0]})
        $display("PASSED: Transmission Completed: %h", rdata);   
    else
        $display("==> FAILED | Data Mismatch! Received Data: %h, Expected Data: %h", rdata, {3'b0,wdata[4:0]});


    $display(" ");
    $display("-------------------ITEM6:Transfering and Receiving a random character from itself !! (8bit, with parity) ------------------");
    rst_n = 1'b0;
    #30;
    rst_n = 1'b1;
    tlen = 2'b11;   //8bit
    bclk_mode = 0;  //x16
    
    wdata = 8'hea;
    wr_en = 1;

    parity_en = 1;
    parity_type = 0;

    $display("Transmitting Byte: %h", wdata);
    $display("Transmitting Start");
    @(negedge TXD) wr_en = 0;
    @(posedge clk);
    #1;
    @(rdata);
    if(rdata == wdata)
        $display("PASSED: Transmission Completed: %h", rdata);   
    else
        $display("==> FAILED | Data Mismatch! Received Data: %h, Expected Data: %h", rdata, wdata);


/*
    $display(" ");
    $display("-------------------ITEM5:Transfering and Receiving a random character from itself !! (8bit, no parity, x13) ------------------");
    rst_n = 1'b0;
    #30;
    rst_n = 1'b1;
    @(posedge clk)

    tlen = 2'b11;   //8bit
    bclk_mode = 1;  //x13
    wdata = 8'haa;
    wr_en = 1;
    $display("Transmitting Byte: %h", wdata);
    $display("Transmitting Start");
    @(negedge TXD) wr_en = 0;
    @(posedge clk);
    #1;
    @(rdata);
    if(rdata == wdata)
        $display("PASSED: Transmission Completed: %h", rdata);   
    else
        $display("==> FAILED | Data Mismatch! Received Data: %h, Expected Data: %h", rdata, wdata);
*/

end
endmodule