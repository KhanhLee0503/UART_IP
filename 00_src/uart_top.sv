module UART_TOP(
    input I_CLK,
    input I_RESET_N,

    //input [3:0] I_BAUD_RATE,
    //input I_BCLK_MODE,  
    input I_CNT_EN,   
    input I_CNT_LOAD,   

    input I_WR_EN,       
    //input I_RD_EN,       
    input [7:0] I_WDATA,
    //input I_RX_IN,
    
    //output logic O_TX_OUT,
    output logic [15:0] O_RDATA
);

logic [7:0] rdata_out;
logic bclk;
logic rsr_fifo_nfull;
logic rsr_write;
logic [7:0] rsr_data;

logic tsr_fifo_nempty;
logic tsr_read;
logic [7:0] tsr_data;

//=================================================================
// This declaration and logic are for baudrate generation test only
//=================================================================
//logic [15:0] counter;
logic rx_in;
/*
always_ff@(posedge I_CLK or negedge I_RESET_N) begin
	if(!I_RESET_N)
		counter <= '0;
	else
		counter <= counter + 1;
end

always_ff@(posedge I_CLK or negedge I_RESET_N) begin
	if(!I_RESET_N)
		rdata_out <= '0;
	else if (bclk && (&counter))
		rdata_out <= rdata_out + 1;
end
*/

BAUD_GEN baud_gen(
    .I_CLK(I_CLK),
    .I_RESET_N(1'b1),
    .I_BAUD_RATE(4'b0000),
    .I_BCLK_MODE(1'b0),
    .I_CNT_EN(I_CNT_EN),
    .I_CNT_LOAD(I_CNT_LOAD),
    .O_BCLK(bclk)
);

RECEIVER_SHIFT_REG receiver_shift_reg(
    .I_CLK(I_CLK),
    .I_RESET_N(I_RESET_N),
    .I_BCLK(bclk),
    .I_FIFO_NFULL(~rsr_fifo_nfull),
    .I_RX_IN(/*I_RX_IN*/ rx_in),
    .O_FIFO_WRITE(rsr_write),
    .O_RDATA(rsr_data)
);

FIFO_SYNC fifo_sync_rsr(
    .I_CLK(I_CLK),
    .I_RESET_N(I_RESET_N),
    .I_WR_EN(rsr_write),
    .I_RD_EN(/*I_RD_EN*/ 1'b0),
    .I_FIFO_WDATA(rsr_data),

    .O_FIFO_RDATA(rdata_out),
    .O_FIFO_FULL(rsr_fifo_nfull),
    .O_FIFO_EMPTY()
);

TRANS_SHIFT_REG trans_shift_reg(
    .I_CLK(I_CLK),
    .I_BCLK(bclk),
    .I_RESET_N(I_RESET_N),
    .I_TDATA(tsr_data),
    .I_FIFO_NEMPTY(~tsr_fifo_nempty),
    .O_FIFO_READ(tsr_read),
    .O_TX_OUT(/*O_TX_OUT*/rx_in)
);

FIFO_SYNC fifo_sync_tsr(
    .I_CLK(I_CLK),
    .I_RESET_N(I_RESET_N),
    .I_WR_EN(~I_WR_EN),
    .I_RD_EN(tsr_read),
    .I_FIFO_WDATA(I_WDATA),

    .O_FIFO_RDATA(tsr_data),
    .O_FIFO_FULL(),
    .O_FIFO_EMPTY(tsr_fifo_nempty)
);

HEX_7_SEG MSB(
    .I_HEX_IN(rdata_out[7:4]),
    .SEG_OUT(O_RDATA[15:8])
);

HEX_7_SEG LSB(
    .I_HEX_IN(rdata_out[3:0]),
    .SEG_OUT(O_RDATA[7:0])
);

endmodule: UART_TOP