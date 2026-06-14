`timescale 1ns/1ps

module UART_TOP(
    input                I_CLK,
    input                I_RESET_N,

    input [3:0]          I_BAUD_RATE,
    input                I_BCLK_MODE,  
    input                I_CNT_EN,   
    input                I_CNT_LOAD,   
    input                I_PARITY_TYPE, 
    input                I_PARITY_EN,

    input                I_WR_EN,       
    input                I_RD_EN,       
    input [7:0]          I_WDATA,
    input                I_RX_IN,
    
    output logic        O_TX_OUT,
    output logic        O_RX_FULL,
    output logic        O_TX_EMPTY,
    output logic [15:0] O_RDATA,
    output logic        O_PARITY_ERR
);
/*
// For FPGA Test Only
    output logic [9:0] O_LED
);
*/

    logic [7:0] rdata_out;
    logic       bclk;
    logic       rsr_fifo_nfull;
    logic       rsr_write;
    logic [7:0] rsr_data;
    logic       tsr_fifo_nempty;
    logic       tsr_read;
    logic [7:0] tsr_data;
    logic       parity_error;

/*
//===================================================================
//	        				FPGA Test Only
//===================================================================

assign O_LED = {I_RD_EN, I_WR_EN, I_WDATA};

    logic  wr_en_sync;
    logic  rd_en_sync;

negedge_detector wr_en(
   .clk       ( I_CLK),       // Clock hệ thống
   .rst_n     ( I_RESET_N),     // Reset tích cực mức thấp (Asynchronous)
   .signal_in ( I_WR_EN), // Tín hiệu đầu vào cần bắt cạnh
   .edge_det  ( wr_en_sync)   // Tín hiệu đầu ra (cao trong 1 chu kỳ clk khi có cạnh lên)
);

negedge_detector rd_en(
   .clk       ( I_CLK),       // Clock hệ thống
   .rst_n     ( I_RESET_N),     // Reset tích cực mức thấp (Asynchronous)
   .signal_in ( I_RD_EN), // Tín hiệu đầu vào cần bắt cạnh
   .edge_det  ( rd_en_sync)   // Tín hiệu đầu ra (cao trong 1 chu kỳ clk khi có cạnh lên)
);

//===================================================================
*/

BAUD_GEN baud_gen(
    .I_CLK       ( I_CLK),
    .I_RESET_N   ( I_RESET_N),
    .I_BAUD_RATE ( I_BAUD_RATE),
    .I_BCLK_MODE ( I_BCLK_MODE),
    .I_CNT_EN    ( I_CNT_EN),
    .I_CNT_LOAD  ( I_CNT_LOAD),
    .O_BCLK      ( bclk)
);

RECEIVER_SHIFT_REG receiver_shift_reg(
    .I_CLK         ( I_CLK),
    .I_RESET_N     ( I_RESET_N),
    .I_BCLK        ( bclk),
    .I_FIFO_NFULL  ( ~rsr_fifo_nfull),
    .I_RX_IN       ( I_RX_IN),
    .I_PARITY_EN   ( I_PARITY_EN),
    .I_PARITY_TYPE ( I_PARITY_TYPE),
    .O_PARITY_ERR  ( parity_error),
    .O_FIFO_WRITE  ( rsr_write),
    .O_RDATA       ( rsr_data)
);

FIFO_SYNC fifo_sync_rsr(
    .I_CLK        ( I_CLK),
    .I_RESET_N    ( I_RESET_N),
    .I_WR_EN      ( rsr_write),
    .I_RD_EN      ( I_RD_EN),
    .I_FIFO_WDATA ( rsr_data),
    .O_FIFO_RDATA ( rdata_out),
    .O_FIFO_FULL  ( rsr_fifo_nfull),
    .O_FIFO_EMPTY ( )
);

TRANS_SHIFT_REG trans_shift_reg(
    .I_CLK         ( I_CLK),
    .I_BCLK        ( bclk),
    .I_RESET_N     ( I_RESET_N),
    .I_TDATA       ( tsr_data),
    .I_FIFO_NEMPTY ( ~tsr_fifo_nempty),
    .I_PARITY_EN   ( I_PARITY_EN),
    .I_PARITY_TYPE ( I_PARITY_TYPE),
    .O_FIFO_READ   ( tsr_read),
    .O_TX_OUT      ( O_TX_OUT)
);

FIFO_SYNC fifo_sync_tsr(
    .I_CLK        ( I_CLK),
    .I_RESET_N    ( I_RESET_N),
    .I_WR_EN      ( I_WR_EN),
    .I_RD_EN      ( tsr_read),
    .I_FIFO_WDATA ( I_WDATA),
    .O_FIFO_RDATA ( tsr_data),
    .O_FIFO_FULL  ( ),
    .O_FIFO_EMPTY ( tsr_fifo_nempty)
);

HEX_7_SEG hex_7_seg_0(
    .I_HEX_IN  ( rdata_out[3:0]),
    .O_SEG_OUT ( O_RDATA[7:0]) // For testbench observation
);

HEX_7_SEG hex_7_seg_1(
    .I_HEX_IN  ( rdata_out[7:4]),
    .O_SEG_OUT ( O_RDATA[15:8]) // For testbench observation
);

assign O_TX_EMPTY   = tsr_fifo_nempty;
assign O_RX_FULL    = rsr_fifo_nfull;
assign O_PARITY_ERR = parity_error;

endmodule: UART_TOP

/*
//========================================================================

module negedge_detector (
    input  logic clk,       // Clock hệ thống
    input  logic rst_n,     // Reset tích cực mức thấp (Asynchronous)
    input  logic signal_in, // Tín hiệu đầu vào cần bắt cạnh xuống
    output logic  edge_det   // Tín hiệu đầu ra (cao trong 1 chu kỳ clk khi có cạnh xuống)
);

    // Thanh ghi để dịch và lưu trữ các trạng thái trước đó của tín hiệu
    logic [2:0] r_sig;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_sig <= 3'b000;
        end else begin
            // Dịch tín hiệu vào qua từng tầng flip-flop để đồng bộ chống metastability
            r_sig <= {r_sig[1:0], signal_in};
        end
    end

    // Điều kiện bắt cạnh xuống:
    // r_sig[1] là trạng thái hiện tại bằng '0'
    // r_sig[2] là trạng thái ngay trước đó bằng '1'
    assign edge_det = (r_sig[1] == 1'b0) && (r_sig[2] == 1'b1);

endmodule
*/