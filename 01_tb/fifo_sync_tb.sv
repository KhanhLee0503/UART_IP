`timescale 1ns/1ns
//`include "../00_src/fifo_sync.sv"

module fifo_sync_tb;
reg clk;
reg rst_n;
reg wr_en; 
reg rd_en;
reg [7:0] wdata;
wire [7:0] rdata;
wire full;
wire empty;

fifo_sync dut (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .wdata(wrdata),
    .rdata(rdata),
    .full(full),
    .empty(empty)
);

initial begin
    $dumpfile("fifo_sync_tb.vcd");
    $dumpvars(0, fifo_sync_tb);
end

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    wr_en = 1'b0;
    rd_en = 1'b0;
    wdata = 8'd0;
    rst_n = 1'b0;   
    #20;
    rst_n = 1'b1;

    $display(" "); 
    $display("ITEM1: Checking Reset Value of The FIFO");
    rd_en = 1;
    for(integer i = 0; i < 16; i = i + 1) begin
       @(posedge clk);
       #1; 
            $display("Value of FIFO at address %d is %h", i, rdata);
        end

    @(posedge clk);
    #1;

    $display(" ");    
    $display("ITEM2: Writing and Reading Data to FIFO");
    rd_en = 0;
    wr_en = 0;    
    rst_n = 1'b0;   
    #20;
    rst_n = 1'b1;
    wr_en = 1;    
    for(integer i = 0; i < 16; i = i + 1) begin
        wdata = i + 8'hA0;
        @(posedge clk);
        #1; 
            $display("Writing %h to FIFO", wdata);
        end
    rd_en = 1;
    wr_en = 0;
     for(integer i = 0; i < 16; i = i + 1) begin
        @(posedge clk);
        #1; 
            $display("Value of FIFO at address %d is %h", i, rdata);
        end
 
 
    $display(" ");    
    $display("ITEM3: Checking FIFO Full Condition");
    rd_en = 0;
    wr_en = 0;    
    rst_n = 1'b0;   
    #20;
    rst_n = 1'b1;
    wr_en = 1;    
    for(integer i = 0; i < 16; i = i + 1) begin
        wdata = i + 8'he0;
        @(posedge clk);
        #1; 
            $display("Writing %h to FIFO", wdata);
        end
    if(full)
        $display("FIFO is full");
    else
        $display("FIFO is not full");
    
     
    $display(" ");    
    $display("ITEM4: Checking FIFO Empty Condition");
    rd_en = 0;
    wr_en = 0;    
    rd_en = 1;
    for(integer i = 0; i < 16; i = i + 1) begin       
        wdata = i + 8'he0;
        @(posedge clk);
        #1; 
            $display("Value of FIFO at address %d is %h", i, rdata);
        end
    if(empty)
        $display("FIFO is empty");
    else
        $display("FIFO is not empty");

    
    $display(" ");    
    $display("ITEM5: Writing and Reading Data Consecutively");
    rd_en = 0;
    wr_en = 0;    
    rst_n = 1'b0;   
    #20;
    rst_n = 1'b1;
    for(integer i = 0; i < 16; i = i + 1) begin
        wr_en = 1;    
        rd_en = 0;
        wdata = i + 8'he0;
        @(posedge clk);
        #1; 
            $display("Writing %h to FIFO", wdata);
        rd_en = 1;
        wr_en = 0;
        @(posedge clk);
        #1;
            $display("Value of FIFO at address %d is %h", i, rdata);
        end
   
    #100; 
    $finish;
end
endmodule