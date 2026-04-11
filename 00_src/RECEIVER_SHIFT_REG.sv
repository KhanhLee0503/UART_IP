module RECEIVER_SHIFT_REG(
    input  I_CLK,
    input  I_RESET_N,
    input  I_BCLK,
    input  I_FIFO_NFULL,
    input  I_RX_IN,

    output logic O_FIFO_WRITE,
    output logic [7:0] O_RDATA
);

parameter IDLE_STATE       = 0;
parameter START_STATE      = 1;
parameter DATA_STATE       = 2;
parameter STOP_STATE       = 3;
parameter WRITE_STATE      = 4;

//===========================================
//-----------Logic Declarations--------------
//===========================================
logic falling_edge;
logic falling_edge_reg;
logic [1:0] rx_in_sync;

logic [7:0] shift_reg;
logic shift_clr;
logic shift_en;

logic [3:0] baud_cnt_reg;
logic baud_cnt_clr;

logic [2:0] bit_cnt_reg;
logic bit_cnt_clr;

logic [2:0] current_state;
logic [2:0] next_state;

//========================================
//-----------  n-FF Synchronizer  --------
//========================================
always_ff@(posedge I_CLK or negedge I_RESET_N) begin
    if(!I_RESET_N)
        rx_in_sync <= 2'b11;
    else
        rx_in_sync <= {rx_in_sync[0], I_RX_IN};
end

//================================-=========
//----------- Falling Edge Detector --------
//=========================================
always_ff @(posedge I_CLK or negedge I_RESET_N ) begin 
   if(!I_RESET_N)
        falling_edge_reg <= 1'b1;
    else
        falling_edge_reg <= rx_in_sync[1];
end

//===========================================
//-----------Shift Register Logic------------
//===========================================
always_ff@(posedge I_CLK or negedge I_RESET_N) begin
    if(!I_RESET_N)
        shift_reg <= '0;
    else if(shift_clr || ((current_state == START_STATE) && I_BCLK && ~rx_in_sync[1]))
        shift_reg <= '0;
   else if(shift_en && (baud_cnt_reg == 4'd15) && I_BCLK)
        shift_reg <= {rx_in_sync[1], shift_reg[7:1]};
end

//=========================================
//----------- baudtick counter ------------
//=========================================
always_ff@(posedge I_CLK or negedge I_RESET_N) begin
    if(!I_RESET_N)
        baud_cnt_reg <= '0;
    else if(baud_cnt_clr)
        baud_cnt_reg <= '0;
    else if(I_BCLK)
        baud_cnt_reg <= baud_cnt_reg + 1'b1;
end

//====================================
//----------- bit counter ------------
//====================================
always_ff@(posedge I_CLK or negedge I_RESET_N) begin
    if(!I_RESET_N)
        bit_cnt_reg <= '0;
    else if(bit_cnt_clr)
        bit_cnt_reg <= '0;
    else if(I_BCLK && (baud_cnt_reg == 4'd15))
        bit_cnt_reg <= bit_cnt_reg + 1'b1;
end

//=============================================
//----------- FINITE STATE MACHINE ------------
//=============================================
// Current State Logic
always_ff@(posedge I_CLK or negedge I_RESET_N) begin
    if(!I_RESET_N)
        current_state <= IDLE_STATE;
    else
        current_state <= next_state;
end

// Next State Logic
always_comb begin
    casez(current_state)
        IDLE_STATE:  next_state = (falling_edge && I_FIFO_NFULL) ? START_STATE : current_state;

        START_STATE: begin
            if((baud_cnt_reg == 4'd7) && I_BCLK) begin
                if(~rx_in_sync[1]) // Check if the start bit is still low at the middle of the start bit duration
                    next_state = DATA_STATE;
                else
                    next_state = IDLE_STATE;  
            end  
            else
                next_state = current_state;
        end 

        DATA_STATE:  next_state = ((bit_cnt_reg == 7) && (baud_cnt_reg == 4'd15) && I_BCLK) ? STOP_STATE : current_state; 

        STOP_STATE: begin
            if((baud_cnt_reg == 4'd15) && I_BCLK) begin
                if(rx_in_sync[1])
                    next_state = WRITE_STATE;
                else
                    next_state = IDLE_STATE;  
            end  
            else
                next_state = current_state;
        end 

        WRITE_STATE: next_state = IDLE_STATE;

        default: next_state = 3'bxx;
    endcase
end

// Output Logic
always_comb begin
    casez(current_state)
        IDLE_STATE: begin
            shift_en        = 1'b0;
            bit_cnt_clr     = 1'b1; 
            baud_cnt_clr    = 1'b1; 
            shift_clr       = 1'b1;
            O_FIFO_WRITE    = 1'b0;
        end 
        START_STATE: begin         
            shift_en        = 1'b0;
            bit_cnt_clr     = 1'b1; 
            baud_cnt_clr    = 1'b0; 
            shift_clr       = 1'b0;
            O_FIFO_WRITE    = 1'b0;
        end
        DATA_STATE: begin
            shift_en        = 1'b1;
            bit_cnt_clr     = 1'b0; 
            baud_cnt_clr    = 1'b0; 
            shift_clr       = 1'b0;
            O_FIFO_WRITE    = 1'b0;
        end
        STOP_STATE: begin
            shift_en        = 1'b0;
            bit_cnt_clr     = 1'b1; 
            baud_cnt_clr    = 1'b0; 
            shift_clr       = 1'b0;
            O_FIFO_WRITE    = 1'b0;
        end
        WRITE_STATE: begin
            shift_en        = 1'b0;
            bit_cnt_clr     = 1'b1; 
            baud_cnt_clr    = 1'b1; 
            shift_clr       = 1'b0;
            O_FIFO_WRITE    = 1'b1;
        end

        default: begin
            shift_en        = 1'bx;
            bit_cnt_clr     = 1'bx; 
            baud_cnt_clr    = 1'bx; 
            shift_clr       = 1'bx;
            O_FIFO_WRITE    = 1'bx;
        end
    endcase
end

assign falling_edge = ~rx_in_sync[1] & falling_edge_reg;
assign O_RDATA = shift_reg;

endmodule: RECEIVER_SHIFT_REG