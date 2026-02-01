module trans(
    input wire clk,
    input wire rst_n,
    input wire bclk_mode,

    input wire [1:0] tlen,
    input wire [7:0] wdata,
    input wire wr_en,

    output wire tx_out
);


wire btick;
wire [7:0] tdata;
wire rd_en_THR;
wire empty_THR;

baudtick_gen baudgen(
    .clk(clk),
    .rst_n(rst_n),
    .bclk_mode(bclk_mode),
    .btick(btick)
   
);

TSR_reg TSR(
    .clk(clk),
    .btick(btick),
    .rst_n(rst_n),
    .tdata(tdata), //read data from THR
    .tlen(tlen),                      
    .fifo_nempty(empty_THR),
    .parity_en(1'b0),   // 00: 5bit | 01: 6bit | 10: 7bit | 11: 8bit
    .parity_type(1'b0), //0-even, 1-odd
   
    .rd_en(rd_en_THR),       //enable read data from THR
    .tx_out(tx_out)
);

fifo_sync THR(
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .rd_en(rd_en_THR),
    .wdata(wdata),

    .rdata(tdata),

    .empty(empty_THR) 
); 
endmodule