`timescale 1ns/1ps

//=====================================================================================
//Divisor Formula: Divisor = (PARA_CLK_FREQ * 1_000_000) / (Baudrate * Baudrate_Speed
//=====================================================================================

module BAUD_GEN #(
    parameter PARA_CLK_FREQ  = 50   // Unit: MHz
)
(
    input       I_CLK,
    input       I_RESET_N,
    input [3:0] I_BAUD_RATE,
    input       I_BCLK_MODE,     // 0: x16 baudrate speed | 1: x13 baudrate speed
    input       I_CNT_EN,
    input       I_CNT_LOAD,

    output logic O_BCLK     // Baudrate 
);

localparam PARA_BD_9600   = 4'h0;
localparam PARA_BD_19200  = 4'h1;
localparam PARA_BD_38400  = 4'h2;
localparam PARA_BD_115200 = 4'h3;

localparam PARA_CLK_HZ = PARA_CLK_FREQ * 1000000;    // Unit: Hz

localparam PARA_DIV_9600_X16 = PARA_CLK_HZ / (9600 * 16) -1;
localparam PARA_DIV_19200_X16 = PARA_CLK_HZ / (19200 * 16) -1;
localparam PARA_DIV_38400_X16 = PARA_CLK_HZ / (38400 * 16) -1;
localparam PARA_DIV_115200_X16 = PARA_CLK_HZ / (115200 * 16) -1;

localparam PARA_DIV_9600_X13 = PARA_CLK_HZ / (9600 * 13) -1;
localparam PARA_DIV_19200_X13 = PARA_CLK_HZ / (19200 * 13) -1;
localparam PARA_DIV_38400_X13 = PARA_CLK_HZ / (38400 * 13) -1;
localparam PARA_DIV_115200_X13 = PARA_CLK_HZ / (115200 * 13) -1;

//===========================================
//-----------Logic Declarations--------------
//===========================================
logic [8:0] divisor_x16;
logic [8:0] divisor_x13;
logic [8:0] divisor;
logic [8:0] cnt_reg;

//========================================
//-----------Divisor LUT x16--------------
//========================================
always_comb begin
    casez(I_BAUD_RATE)
        PARA_BD_9600: divisor_x16   = PARA_DIV_9600_X16;
        PARA_BD_19200: divisor_x16  = PARA_DIV_19200_X16;
        PARA_BD_38400: divisor_x16  = PARA_DIV_38400_X16;
        PARA_BD_115200: divisor_x16 = PARA_DIV_115200_X16;
        default: divisor_x16   = 9'dx;
    endcase
end

//========================================
//-----------Divisor LUT x13--------------
//========================================
always_comb begin
    casez(I_BAUD_RATE)
        PARA_BD_9600: divisor_x13   = PARA_DIV_9600_X13;
        PARA_BD_19200: divisor_x13  = PARA_DIV_19200_X13;
        PARA_BD_38400: divisor_x13  = PARA_DIV_38400_X13;
        PARA_BD_115200: divisor_x13 = PARA_DIV_115200_X13;
        default: divisor_x13   = 9'dx;
    endcase
end

//==========================================
//-----------Decrement Counter--------------
//==========================================
always_ff@(posedge I_CLK or negedge I_RESET_N) begin
    if(!I_RESET_N)
       cnt_reg <= '0; 
    else if((I_CNT_LOAD || ~|cnt_reg) && I_CNT_EN)
        cnt_reg <= divisor;
    else if(I_CNT_EN) 
        cnt_reg <= cnt_reg -'d1;
end

assign divisor = (I_BCLK_MODE) ? divisor_x13 : divisor_x16;
assign O_BCLK  = ~|cnt_reg & I_CNT_EN; 

endmodule: BAUD_GEN