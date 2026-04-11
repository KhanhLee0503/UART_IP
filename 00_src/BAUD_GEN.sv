module BAUD_GEN #(
    parameter PARA_CLK_FREQ  = 50   // Unit: MHz
)
(
    input I_CLK,
    input I_RESET_N,
    input [3:0] I_BAUD_RATE,
    input I_BCLK_MODE,     // 0: x16 baudrate speed | 1: x13 baudrate speed
    input I_CNT_EN,
    input I_CNT_LOAD,

    output logic O_BCLK     // Baudrate 
);

localparam BD_9600   = 4'h0;
localparam BD_19200  = 4'h1;
localparam BD_38400  = 4'h2;
localparam BD_115200 = 4'h3;

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
        BD_9600: divisor_x16   = 9'd325;
        BD_19200: divisor_x16  = 9'd162;
        BD_38400: divisor_x16  = 9'd80;
        BD_115200: divisor_x16 = 9'd26;
        default: divisor_x16   = 9'dx;
    endcase
end

//========================================
//-----------Divisor LUT x13--------------
//========================================
always_comb begin
    casez(I_BAUD_RATE)
        BD_9600: divisor_x13   = 9'd400;
        BD_19200: divisor_x13  = 9'd199;
        BD_38400: divisor_x13  = 9'd99;
        BD_115200: divisor_x13 = 9'd32;
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
assign O_BCLK = ~|cnt_reg; 

endmodule: BAUD_GEN