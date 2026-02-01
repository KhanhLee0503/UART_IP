module fifo_sync #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8                
                   )
(
    input wire clk,
    input wire rst_n,
    input wire wr_en,
    input wire rd_en,
    input wire [DATA_WIDTH-1:0] wdata,

    output reg [DATA_WIDTH-1:0] rdata,
    output reg full,
    output reg empty 
); 
wire wr_en_sync;
reg [DATA_WIDTH-1:0] data_reg [0:15];
reg fifo_full;
reg fifo_empty;
reg [ADDR_WIDTH:0] wpointer_reg;
reg [ADDR_WIDTH:0] rpointer_reg;

//----------------Write Pointer-----------

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        wpointer_reg <= {ADDR_WIDTH{1'b0}};        
    else if(~fifo_full & wr_en)
        wpointer_reg <= wpointer_reg + 1;
end

//-----------------Read Pointer---------------

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rpointer_reg <= {ADDR_WIDTH{1'b0}};        
    else if(~fifo_empty & rd_en)
        rpointer_reg <= rpointer_reg + 1;
end

always@(*) begin
    fifo_empty = (wpointer_reg == rpointer_reg);
end

always@(*) begin
    fifo_full = ({~wpointer_reg[ADDR_WIDTH], wpointer_reg[ADDR_WIDTH-1:0]} == rpointer_reg[ADDR_WIDTH:0]);
end

always@(*) begin
    full = fifo_full;
    empty = fifo_empty;
end

//----------------FIFO Memory----------------
assign wr_en_sync = (~fifo_full & wr_en);// | (fifo_full & rd_en & wr_en);
//Write Data Logic
always @(posedge clk) begin
  /* if(!rst_n) begin
    for(integer i = 0; i < 16; i=i+1) begin
        data_reg[i] <= {DATA_WIDTH{1'b0}};
    end
   end
   */
	if(wr_en_sync) begin
        data_reg[wpointer_reg[ADDR_WIDTH-1:0]] <= wdata; 
   end
end

//Read Data Logic 
always@(posedge clk) begin
    if(rd_en & ~fifo_empty)
        rdata <= data_reg[rpointer_reg[ADDR_WIDTH-1:0]];
    else
        rdata <= 32'd0;
end

endmodule