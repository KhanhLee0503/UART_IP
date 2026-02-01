`timescale 1ns/1ns

module TSR_tb();
reg clk;
reg btick;
reg rst_n;
reg [7:0] tdata;
reg [1:0] tlen;
reg fifo_nempty;
reg parity_en;
reg parity_type; //0-even, 1-odd
wire rd_en;
wire tx_out;

TSR_reg dut (
    .clk(clk),
    .btick(btick),
    .rst_n(rst_n),
    .tdata(tdata),
    .tlen(tlen),
    .fifo_nempty(fifo_nempty),
    .parity_en(parity_en),
    .parity_type(parity_type),
    .rd_en(rd_en),
    .tx_out(tx_out)
);

reg [7:0] rdata;
reg expected_parity_bit;

initial begin
    $dumpfile("TSR_tb.vcd");
    $dumpvars(0, TSR_tb);
end


initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    expected_parity_bit = 0;
    rdata = 8'h00;
    tdata = 8'h00;
    tlen = 2'b11; //8 bits  
    fifo_nempty = 1'b0;
    parity_en = 1'b0;
    parity_type = 1'b0; //even parity
    rst_n = 1'b0;   
    #20;        
    rst_n = 1'b1;

    $display(" ");
    $display("ITEM1: Checking Reset Condition");
    rdata = 8'h00;
    rst_n = 1'b0;   
    #20;        
    rst_n = 1'b1;
    parity_en = 1'b0; //disable parity
    parity_type = 1'b0; //even parity
    tdata = 8'heb;
    tlen = 2'b11; //8 bits
    fifo_nempty = 1'b1;
    
    
    $display(" ");
    $display("ITEM2: Checking Transmission without Parity (8 data bits)");
    rdata = 8'h00;
    rst_n = 1'b0;   
    #20;        
    rst_n = 1'b1;
    parity_en = 1'b0; //disable parity
    parity_type = 1'b0; //even parity
    tdata = 8'heb;
    tlen = 2'b11; //8 bits
    fifo_nempty = 1'b0; //data available in FIFO
    @(posedge btick);
    @(posedge btick);
       for(integer i = 0; i < 8; i = i + 1) begin
        @(posedge btick);
            rdata[i] = tx_out;
        #1;
        end
    fifo_nempty = 1'b1; //data available in FIFO
    @(posedge btick);
    #1;
        $display("Transmission data: %h", rdata);  
   
    
    
    $display(" ");
    $display("ITEM3: Checking Transmission without Parity (7 data bits)");
    rdata = 8'h00;
    rst_n = 1'b0;   
    #20;        
    rst_n = 1'b1;
    parity_en = 1'b0; //disable parity
    parity_type = 1'b0; //even parity
    tdata = 8'heb;
    tlen = 2'b10; //7 bits
    fifo_nempty = 1'b0; //data available in FIFO
    @(posedge btick);
    @(posedge btick);
       for(integer i = 0; i < 7; i = i + 1) begin
        @(posedge btick);
            rdata[i] = tx_out;
        #1;
        end
    fifo_nempty = 1'b1; //data available in FIFO
    @(posedge btick);
    #1;
        $display("Transmission data: %h", rdata);  

     
    $display(" ");
    $display("ITEM4: Checking Transmission without Parity (6 data bits)");
    rdata = 8'h00;
    rst_n = 1'b0;   
    #20;        
    rst_n = 1'b1;
    parity_en = 1'b0; //disable parity
    parity_type = 1'b0; //even parity
    tdata = 8'hf5;
    tlen = 2'b01; //6 bits
    fifo_nempty = 1'b0; //data available in FIFO
    @(posedge btick);
    @(posedge btick);
       for(integer i = 0; i < 6; i = i + 1) begin
        @(posedge btick);
            rdata[i] = tx_out;
        #1;
        end
    fifo_nempty = 1'b1; //data available in FIFO
    @(posedge btick);
    #1;
        $display("Transmission data: %h", rdata);  

      
    $display(" ");
    $display("ITEM5: Checking Transmission without Parity (5 data bits)");
    rdata = 8'h00;
    rst_n = 1'b0;   
    #20;        
    rst_n = 1'b1;
    parity_en = 1'b0; //disable parity
    parity_type = 1'b0; //even parity
    tdata = 8'hda;
    tlen = 2'b01; //6 bits
    fifo_nempty = 1'b0; //data available in FIFO
    @(posedge btick);
    @(posedge btick);
       for(integer i = 0; i < 5; i = i + 1) begin
        @(posedge btick);
            rdata[i] = tx_out;
        #1;
        end
    fifo_nempty = 1'b1; //data available in FIFO
    @(posedge btick);
    #1;
        $display("Transmission data: %h", rdata);  

 
    $display(" ");
    $display("ITEM6: Checking Transmission with Parity bit (8 data bits)");
    rdata = 8'h00;
    rst_n = 1'b0;   
    #20;        
    rst_n = 1'b1;
    parity_en = 1'b1; //disable parity
    parity_type = 1'b1; //even parity
    tdata = 8'ha5;
    expected_parity_bit = ~(^tdata); //even parity
    tlen = 2'b11; //8 bits
    fifo_nempty = 1'b0; //data available in FIFO
    @(posedge btick);
    @(posedge btick);
       for(integer i = 0; i < 8; i = i + 1) begin
        @(posedge btick);
            rdata[i] = tx_out;
        #1;
        end
   // fifo_nempty = 1'b1; //data available in FIFO
   // @(posedge btick);
    @(posedge btick);
    #1;
        if(expected_parity_bit == tx_out)
            $display("Parity Bit matched: %b", tx_out);  
        else
            $display("Parity Bit Mismatched: Expected %b, Got %b", expected_parity_bit, tx_out);    

        $display("Transmission data: %h", rdata);  

    $display(" ");
    $display("ITEM7: Checking Transmission without Parity and then FIFO empty = 1 (8 data bits)");
    rdata = 8'h00;
    rst_n = 1'b0;   
    #20;        
    rst_n = 1'b1;
    parity_en = 1'b0; //disable parity
    parity_type = 1'b0; //even parity
    tdata = 8'heb;
    tlen = 2'b11; //8 bits
    fifo_nempty = 1'b0; //data available in FIFO
    @(posedge btick);
    @(posedge btick);
       for(integer i = 0; i < 8; i = i + 1) begin
        @(posedge btick);
            rdata[i] = tx_out;
            fifo_nempty = 1'b1; //data available in FIFO
        #1;
        end
    @(posedge btick);
    #1;
        $display("Transmission data: %h", rdata);  

#1000;
$finish; 
end
endmodule