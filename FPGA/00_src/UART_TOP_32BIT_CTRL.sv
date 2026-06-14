module UART_TOP_32BIT_CTRL(
    input                I_CLK,
    input                I_RESET_N,

    //Config UART Parameters
    input [3:0]          I_BAUD_RATE,
    input                I_BCLK_MODE,  
    input                I_CNT_EN,   
    input                I_CNT_LOAD,   

    //Interface for Transmitter
    input                I_WR_EN,       
    input [31:0]         I_WDATA,

    //Interface of UART
    input                I_RX_IN,
    output logic         O_TX_OUT,

    output logic         O_VALID_32,      // Báo hiệu (pulse) đã gom đủ 32-bit hợp lệ
    output logic [31:0]  O_RDATA
);

logic [7:0] rdata_out;
logic       bclk;
logic       rsr_fifo_nfull;
logic       rsr_write;
logic [7:0] rsr_data;
logic       tsr_fifo_nempty;
logic       tsr_read;
logic [7:0] tsr_data;

//===========================
// 32bit data control
//===========================
logic       fifo_rsr_empty;
logic       fifo_pop;
logic [7:0] uart_data;
logic       uart_tx_en;

BAUD_GEN baud_gen(
    .I_CLK(I_CLK),
    .I_RESET_N(I_RESET_N),
    .I_BAUD_RATE(I_BAUD_RATE),
    .I_BCLK_MODE(I_BCLK_MODE),
    .I_CNT_EN(I_CNT_EN),
    .I_CNT_LOAD(I_CNT_LOAD),
    .O_BCLK(bclk)
);

RECEIVER_SHIFT_REG receiver_shift_reg(
    .I_CLK(I_CLK),
    .I_RESET_N(I_RESET_N),
    .I_BCLK(bclk),
    .I_FIFO_NFULL(~rsr_fifo_nfull),
    .I_RX_IN(I_RX_IN),
    .O_FIFO_WRITE(rsr_write),
    .O_RDATA(rsr_data)
);

FIFO_SYNC fifo_sync_rsr(
    .I_CLK(I_CLK),
    .I_RESET_N(I_RESET_N),
    .I_WR_EN(rsr_write),
    .I_RD_EN(fifo_pop),
    .I_FIFO_WDATA(rsr_data),

    .O_FIFO_RDATA(rdata_out),
    .O_FIFO_FULL(rsr_fifo_nfull),
    .O_FIFO_EMPTY(fifo_rsr_empty)
);

TRANS_SHIFT_REG trans_shift_reg(
    .I_CLK(I_CLK),
    .I_BCLK(bclk),
    .I_RESET_N(I_RESET_N),
    .I_TDATA(tsr_data),
    .I_FIFO_NEMPTY(~tsr_fifo_nempty),
    .O_FIFO_READ(tsr_read),
    .O_TX_OUT(O_TX_OUT)
);

FIFO_SYNC fifo_sync_tsr(
    .I_CLK(I_CLK),
    .I_RESET_N(I_RESET_N),
    .I_WR_EN(uart_tx_en),
    .I_RD_EN(tsr_read),
    .I_FIFO_WDATA(uart_data),

    .O_FIFO_RDATA(tsr_data),
    .O_FIFO_FULL(),
    .O_FIFO_EMPTY(tsr_fifo_nempty)
);

UART_TX_32BIT_CTRL Transmitt_Control(
    .I_CLK(I_CLK),
    .I_RESET_N(I_RESET_N),
    
    // Giao tiếp với Master (CPU hoặc Sensor)
    .I_START_32(I_WR_EN),
    .I_DATA_32(I_WDATA),
    .O_DONE_32(),
    
    // Giao tiếp với UART_TOP
    .O_UART_WDATA(uart_data),
    .O_UART_WREN(uart_tx_en)
);

UART_RX_32BIT_CTRL Receiver_Control(
    .I_CLK(I_CLK),
    .I_RESET_N(I_RESET_N),
    
    // Giao tiếp với UART_TOP
    .I_UART_RX_EMPTY(fifo_rsr_empty), // FIFO có trống không?
    .I_UART_RDATA(rdata_out),         // Dữ liệu 8-bit từ FWFT FIFO
    .O_UART_RDEN(fifo_pop),           // Cờ báo "Pop" dữ liệu
    
    // Giao tiếp với System (CPU hoặc Mạch xử lý phía sau)
    .O_DATA_32(O_RDATA),
    .O_VALID_32(O_VALID_32)
);

endmodule: UART_TOP_32BIT_CTRL