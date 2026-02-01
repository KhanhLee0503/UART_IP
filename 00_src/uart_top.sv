module uart_top(
    input wire clk,
    input wire rst_n,
    input wire bclk_mode,   //0: x16 speed | 1: x13 speed
    
    input wire [1:0] tlen,  // 00: 5bit | 01: 6bit | 10: 7bit | 11: 8bit
    input wire parity_en,
    input wire parity_type, //0-even, 1-odd
    
    input wire wr_en,       // Write 1 to this signal to start Transmission
        
    input wire [7:0] wdata,
    input wire RXD,
    
    output wire TXD,
    output reg [7:0] rdata,
    output wire parity_err,
    output wire frame_err
);

//***Baudrate Signals***
wire btick;
wire btick_16;

//***Full and Empty signals of FIFOs***
wire full_thr;
wire empty_thr;

wire full_rbr;
wire empty_rbr;

//***Write and Read Enable signals of RBR***
wire wr_en_rbr;
reg rd_en_rbr;
reg rdata_en;
wire [7:0] wdata_rbr;
wire [7:0] rdata_pre;

//***Write and Read Enable signals of THR***
wire rd_en_thr;
wire wr_en_thr;
wire [7:0] rdata_thr;


//-------------------------------Sub modules Connections---------------------------

baudtick_gen baudgen ( 
    .clk(clk),
    .rst_n(rst_n),
    .bclk_mode(bclk_mode),
    .btick(btick),
    .btick_16(btick_16)
);

RSR_reg Receiver_Shift_Reg (  
    .clk(clk),
    .rst_n(rst_n),
    .btick_16(btick_16),
    .btick(btick),
    
    .tlen(tlen),
    .parity_en(parity_en),
    .parity_type(parity_type), //0-even, 1-odd
    .sample_type(bclk_mode),
    
    .rx_in(RXD),
    .fifo_nfull(full_rbr),

    .wr_en(wr_en_rbr),
    .rdata(wdata_rbr),
    
    .frame_err(frame_err),
    .parity_err(parity_err)
);

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rd_en_rbr <= 0;
    else
        rd_en_rbr <= wr_en_rbr;    
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rdata_en <= 0;
    else
        rdata_en <= rd_en_rbr;    
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rdata <= 8'b0;
    else if (rdata_en)
        rdata <= rdata_pre;
end

fifo_sync RBR (
    .clk(clk),
    .rst_n(rst_n),
    
    .wr_en(wr_en_rbr),
    .rd_en(rd_en_rbr),
    
    .wdata(wdata_rbr),

    .rdata(rdata_pre),
    
    .full(full_rbr),
    .empty(empty_rbr) 
);


TSR_reg Transmitter_Shift_Reg (
    .clk(clk),
    .rst_n(rst_n),
    .btick(btick),
    
    .tlen(tlen),
    .parity_en(parity_en),
    .parity_type(parity_type), //0-even, 1-odd
    .fifo_nempty(empty_thr),
    
    .rd_en(rd_en_thr),
    .tdata(rdata_thr),

    .tx_out(TXD)
);

fifo_sync THR (
    .clk(clk),
    .rst_n(rst_n),

    .wr_en(wr_en),
    .rd_en(rd_en_thr),

    .wdata(wdata),

    .rdata(rdata_thr),

    .full(full_thr),
    .empty(empty_thr) 
);  

endmodule