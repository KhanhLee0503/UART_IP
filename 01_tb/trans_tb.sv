`timescale  1ns/1ns
module trans_tb(); 
reg clk;
reg rst_n;
reg bclk_mode;
reg [1:0] tlen;
reg [7:0] wdata;
reg wr_en;
wire tx_out;

trans DUT(.*);

initial begin
    clk = 0;
    forever begin
        #5 clk = ~clk;
    end
end

initial begin
    bclk_mode   = 0;
    tlen        = 2'b11;
    wdata       = 8'b0;
    wr_en       = 0;

    //-----Reset------
    rst_n = 0;
    #20
    rst_n = 1;

    //-----------------Write Data to FIFO----------------
    @(posedge clk);
    #1;
    wdata = 8'h38;
    wr_en  = 1;
    @(posedge clk);
    #1;

    wr_en = 0;

    @(posedge clk);
    #1;
    wdata = 8'h55;
    wr_en  = 1;
    @(posedge clk);
    #1;

    wr_en = 0;
    //---------------Read Transmission-------------------
    #1;


end


endmodule 