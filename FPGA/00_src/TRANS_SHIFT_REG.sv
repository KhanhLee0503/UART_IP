`timescale 1ns/1ps

module TRANS_SHIFT_REG(
    input        I_CLK,
    input        I_BCLK,
    input        I_RESET_N,
    input [7:0]  I_TDATA, //read data from THR
    input        I_FIFO_NEMPTY,

    input        I_PARITY_TYPE, //0: even parity, 1: odd parity
    input        I_PARITY_EN,

    output logic O_FIFO_READ,       //enable read data from THR
    output logic O_TX_OUT
);

localparam IDLE_STATE    = 3'b000;
localparam LOAD_STATE    = 3'b001;
localparam START_STATE   = 3'b010;
localparam DATA_STATE    = 3'b011;
localparam PARITY_STATE  = 3'b100;
localparam STOP_STATE    = 3'b101;

//===========================================
//-----------Logic Declarations--------------
//===========================================
logic [7:0] shift_reg;
logic       shift_clr;
logic       shift_en;
logic       shift_load;

logic [3:0] baud_cnt_reg;
logic       baud_cnt_clr;

logic [2:0] bit_cnt_reg;
logic       bit_cnt_clr;

logic [2:0] current_state;
logic [2:0] next_state;

logic       parity_bit;
logic [7:0] parity_data;

//===========================================
//-----------Shift Register Logic------------
//===========================================
always_ff@(posedge I_CLK or negedge I_RESET_N) begin
    if(!I_RESET_N)
        shift_reg <= '0;
    else if(shift_clr)
        shift_reg <= '0;
    else if(shift_load)
        shift_reg <= I_TDATA;
    else if(shift_en && (baud_cnt_reg == 4'd15) && I_BCLK)
        shift_reg <= {1'b1, shift_reg[7:1]};
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
//--------------Parity Bit Logic---------------
//=============================================
always_ff@(posedge I_CLK or negedge I_RESET_N) begin
    if(!I_RESET_N)
        parity_data <= '0;
    else if(shift_load)
        parity_data <= I_TDATA;
end

always_comb begin
    if(I_PARITY_EN) begin
        if(I_PARITY_TYPE) //odd parity
            parity_bit = ~(^parity_data);
        else //even parity
            parity_bit = ^parity_data;
    end
    else
        parity_bit = 1'b1; //if parity disable, set parity bit to 1 (stop bit)
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
        IDLE_STATE:  next_state = I_FIFO_NEMPTY ? LOAD_STATE : current_state;
        LOAD_STATE:  next_state = START_STATE;
        START_STATE: next_state = (I_BCLK && (baud_cnt_reg == 4'd15)) ? DATA_STATE : current_state;
        DATA_STATE:  begin 
                        if (I_BCLK && (baud_cnt_reg == 4'd15) && (bit_cnt_reg == 3'd7))
                            next_state = I_PARITY_EN ? PARITY_STATE : STOP_STATE;
                        else
                            next_state = current_state;
                     end
        PARITY_STATE: next_state = (I_BCLK && (baud_cnt_reg == 4'd15)) ? STOP_STATE : current_state;
        STOP_STATE:   next_state = (I_BCLK && (baud_cnt_reg == 4'd15)) ? IDLE_STATE : current_state;
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
            shift_load      = 1'b0; 
            shift_clr       = 1'b1;
            O_FIFO_READ     = 1'b0;
            O_TX_OUT        = 1'b1; 
        end 
        LOAD_STATE: begin         
            shift_en        = 1'b0;
            bit_cnt_clr     = 1'b1; 
            baud_cnt_clr    = 1'b0; 
            shift_load      = 1'b1; 
            shift_clr       = 1'b0;
            O_FIFO_READ     = 1'b1;
            O_TX_OUT        = 1'b1;
        end
        START_STATE: begin         
            shift_en        = 1'b0;
            bit_cnt_clr     = 1'b1; 
            baud_cnt_clr    = 1'b0; 
            shift_load      = 1'b0; 
            shift_clr       = 1'b0;
            O_FIFO_READ     = 1'b0;
            O_TX_OUT        = 1'b0;
        end
        DATA_STATE: begin
            shift_en        = 1'b1;
            bit_cnt_clr     = 1'b0; 
            baud_cnt_clr    = 1'b0; 
            shift_load      = 1'b0; 
            shift_clr       = 1'b0;
            O_FIFO_READ     = 1'b0;
            O_TX_OUT        = shift_reg[0];
        end
        PARITY_STATE: begin
            shift_en        = 1'b0;
            bit_cnt_clr     = 1'b0; 
            baud_cnt_clr    = 1'b0; 
            shift_load      = 1'b0; 
            shift_clr       = 1'b0;
            O_FIFO_READ     = 1'b0;
            O_TX_OUT        = parity_bit;
        end
        STOP_STATE: begin
            shift_en        = 1'b0;
            bit_cnt_clr     = 1'b1; 
            baud_cnt_clr    = 1'b0; 
            shift_load      = 1'b0;
            shift_clr       = 1'b0;
            O_FIFO_READ     = 1'b0;
            O_TX_OUT        = 1'b1; 
        end
        default: begin
            shift_en        = 1'bx;
            bit_cnt_clr     = 1'bx; 
            baud_cnt_clr    = 1'bx; 
            shift_load      = 1'bx; 
            shift_clr       = 1'bx;
            O_FIFO_READ     = 1'bx;
            O_TX_OUT        = 1'bx;
        end
    endcase
end

endmodule: TRANS_SHIFT_REG