`timescale 1ns/1ns
module RSR_tb();
reg btick_16;
reg btick;
reg rst_n;
reg [1:0] tlen;
reg fifo_nfull;
reg parity_en;
reg parity_type; //0-even, 1-odd
reg sample_type;
reg rx_in;

wire parity_err;
wire wr_en;
wire frame_err;
wire [7:0] rdata;

RSR_reg DUT(
    .btick_16(btick_16),
    .btick(btick),
    .rst_n(rst_n),
    .tlen(tlen),
    .fifo_nfull(fifo_nfull),
    .parity_en(parity_en),
    .parity_type(parity_type),
    .sample_type(sample_type),
    .rx_in(rx_in),
    .wr_en(wr_en),
    .frame_err(frame_err),
    .rdata(rdata),
    .parity_err(parity_err)
);

reg [7:0] test_data;
reg expected_parity_bit;
reg received_parity_bit;


initial begin
    btick_16 = 0;
    forever #5 btick_16 = ~btick_16;
end

initial begin
    reg [3:0] count;
    count = 0;
    btick = 0;
    forever #5 begin
        @(posedge btick_16);
        count = count + 1;
        if(sample_type) begin
             if(count == 4'd6) begin 
                btick = ~btick;
                count = 0;
            end
        end

        else begin
            if (count == 4'd8) begin 
                btick = ~btick;
                count = 0;
            end
        end
    end
end


initial begin
    received_parity_bit = 0;
    expected_parity_bit =  0;
    test_data   = 8'h00;
    tlen        = 0;
    fifo_nfull  = 1;
    parity_en   = 0;
    parity_type = 0; //0-even, 1-odd
    rx_in       = 1;
    sample_type = 0; //0-7x, 1-16x
    rst_n       = 0;
    #20;    
    rst_n       = 1'b1;

@(posedge btick);
$display(" ");
$display("ITEM1: Checking Reset Condition");
$display("RXD reset value : %h", rdata);    


$display(" ");
$display("ITEM2: Transmitting Data with No Parity, 16x Sampling (8bit data)");
tlen       = 2'b11; //8 bits
sample_type = 1'b0; //16x sampling
fifo_nfull = 1'b0; //data available in FIFO
@(posedge btick);
test_data = 8'heb;
$display("Transmitting Byte: %h", test_data);
$display("Transmitting Start");
@(posedge btick);
#1;
    rx_in = 0; //start bit

for(integer i=0; i < 8; i = i + 1) begin
    @(posedge btick);
    #1;
    rx_in = test_data[i]; //data bits
end
@(posedge btick);
#1;
rx_in = 1; //stop bit

@(posedge btick);
#1;
if(rdata == test_data)
    $display("PASSED: Received Data: %h", rdata);   
else
    $display("==> FAILED | Data Mismatch! Received Data: %h, Expected Data: %h", rdata, test_data);


$display(" ");
$display("ITEM3: Transmitting Data with No Parity, 13x Sampling (8bit data)");
tlen        = 2'b11; //8 bits
sample_type = 1'b1; //13x sampling
fifo_nfull  = 1'b0; //data available in FIFO
@(posedge btick);
test_data = 8'hfa;
$display("Transmitting Byte: %h", test_data);
$display("Transmitting Start");
@(posedge btick);
#1;
    rx_in = 0; //start bit

for(integer i=0; i < 8; i = i + 1) begin
    @(posedge btick);
    #1;
    rx_in = test_data[i]; //data bits
end
@(posedge btick);
#1;
rx_in = 1; //stop bit

@(posedge btick);
#1;
if(rdata == test_data)
    $display("PASSED: Received Data: %h", rdata);   
else
    $display("==> FAILED | Data Mismatch! Received Data: %h, Expected Data: %h", rdata, test_data);



$display(" ");
$display("ITEM4: Transmitting Data with Parity, 16x Sampling (8bit data)");
tlen        = 2'b11; //8 bits
sample_type = 1'b0; //13x sampling
fifo_nfull  = 1'b0; //data available in FIFO
@(posedge btick);
test_data = 8'h22;
if(parity_en) begin
    if(parity_type)
        expected_parity_bit = ^test_data; //odd parity
    else 
        expected_parity_bit = ~(^test_data); //even parity   
end
$display("Transmitting Byte: %h", test_data);
$display("Transmitting Start");
@(posedge btick);
#1;
    rx_in = 0; //start bit

for(integer i=0; i < 8; i = i + 1) begin
    @(posedge btick);
    #1;
    rx_in = test_data[i]; //data bits
end
@(posedge btick);
#1    
received_parity_bit = rx_in;

@(posedge btick);
#1 
rx_in = 1; //stop bit

@(posedge btick);
#1;
if((received_parity_bit == expected_parity_bit) && (parity_err == 0))
    $display("PASSED: No parity error | Received Parity Bit: %b, Expected Parity Bit: %b", received_parity_bit, expected_parity_bit);
else if ((received_parity_bit != expected_parity_bit) && (parity_err == 1))
    $display("PASSED: Parity Error Found | Received Parity Bit: %b, Expected Parity Bit: %b", received_parity_bit, expected_parity_bit);
else if ((received_parity_bit != expected_parity_bit) && (parity_err == 0))
    $display("==> FAILED | Parity Error Not Asserted! Received Parity Bit: %b, Expected Parity Bit: %b", received_parity_bit, expected_parity_bit);
else if((received_parity_bit == expected_parity_bit) && (parity_err == 1))
    $display("==> FAILED | Parity Error Asserted Unexpectedly | Received Parity Bit: %b, Expected Parity Bit: %b", received_parity_bit, expected_parity_bit);


#1000;
$finish;
end


endmodule