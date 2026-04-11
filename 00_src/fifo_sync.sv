module FIFO_SYNC #(
    parameter PARA_FIFO_DEPTH = 16,
    parameter PARA_DATA_WIDTH = 8                
)
(
    input I_CLK,
    input I_RESET_N,
    input I_WR_EN,
    input I_RD_EN,
    input [PARA_DATA_WIDTH-1:0] I_FIFO_WDATA,

    output logic [PARA_DATA_WIDTH-1:0] O_FIFO_RDATA,
    output logic O_FIFO_FULL,
    output logic O_FIFO_EMPTY 
); 

localparam PARA_ADDR_WIDTH = $clog2(PARA_FIFO_DEPTH);

//==============================================
//----------------Logic Declaration-------------
//==============================================
logic [PARA_DATA_WIDTH-1:0] mem [0:PARA_FIFO_DEPTH-1];
logic [PARA_ADDR_WIDTH:0] wpointer_reg;
logic [PARA_ADDR_WIDTH:0] rpointer_reg;

//======================================
//----------------MEM Array-------------
//======================================
always_ff@(posedge I_CLK) begin
    if(I_WR_EN && !O_FIFO_FULL)
      // mem[wpointer_reg[PARA_ADDR_WIDTH-1:0]] <= I_FIFO_WDATA;
		//====================================
	   // This line is for FPGA test only
	   // You should use the line above
	   //====================================
		 mem[0] <= I_FIFO_WDATA;
end

//==========================================
//----------------Write Pointer-------------
//==========================================
always_ff@(posedge I_CLK or negedge I_RESET_N) begin
    if(!I_RESET_N)
        wpointer_reg <= '0;       
    else if(!O_FIFO_FULL && I_WR_EN)
        wpointer_reg <= wpointer_reg + 'h1;
end

//===========================================
//-----------------Read Pointer--------------
//===========================================
always_ff@(posedge I_CLK or negedge I_RESET_N) begin
    if(!I_RESET_N)
        rpointer_reg <= '0;        
    else if(!O_FIFO_EMPTY && I_RD_EN)
        rpointer_reg <= rpointer_reg + 'h1;
end

//===========================================
//-----------------Status Logic--------------
//===========================================
always_comb begin
    O_FIFO_EMPTY = ~(wpointer_reg[PARA_ADDR_WIDTH] ^ rpointer_reg[PARA_ADDR_WIDTH]) & (wpointer_reg[PARA_ADDR_WIDTH-1:0] == rpointer_reg[PARA_ADDR_WIDTH-1:0]);
    O_FIFO_FULL = (wpointer_reg[PARA_ADDR_WIDTH] ^ rpointer_reg[PARA_ADDR_WIDTH]) & (wpointer_reg[PARA_ADDR_WIDTH-1:0] == rpointer_reg[PARA_ADDR_WIDTH-1:0]);
    //O_FIFO_RDATA = mem[rpointer_reg[PARA_ADDR_WIDTH-1:0]];
	 
	 //====================================
	 // This line is for FPGA test only
	 // You should use the line above
	 //====================================
	 O_FIFO_RDATA = mem[0];
end

endmodule: FIFO_SYNC