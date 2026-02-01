module TSR_reg(
    input wire clk,
    input wire btick,
    input wire rst_n,
    input wire [7:0] tdata, //read data from THR
    input wire [1:0] tlen,                      
    input wire fifo_nempty,
    input wire parity_en,   // 00: 5bit | 01: 6bit | 10: 7bit | 11: 8bit
    input wire parity_type, //0-even, 1-odd
    
    output reg rd_en,       //enable read data from THR
    output reg tx_out

);
parameter IDLE       = 0;
parameter READ_FIFO1 = 1;
parameter READ_FIFO2 = 2;
parameter START      = 3;
parameter DATA       = 4;
parameter PARITY     = 5;
parameter STOP       = 6;

//--------------------Internal Signals--------------------
//***Parity Logic***
reg [7:0]parity_data;
reg parity_bit;

//***Data Shift Register***
reg [7:0] tdata_reg;
reg shift_en;

//***Counter Logic***
reg count_en;
reg count_clr;
reg [3:0] bit_cnt;
reg [3:0] comp_val;

//***State Machine Logic***
reg [2:0] state;
reg [2:0] next_state;

//--------------------Data Shift Register Logic--------------------
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tdata_reg <= 0;
    end else if(shift_en && btick) begin
        tdata_reg <= tdata_reg >> 1;
    end else if (state == READ_FIFO2) begin
        tdata_reg <= tdata;
   end
end


//--------------------Parity Logic--------------------
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        parity_data <= 0;
    end else if (state == READ_FIFO2) begin
        parity_data <= tdata;
    end
end

always@(*) begin
    if(parity_en) begin
        if(parity_type)
            //odd parity
            parity_bit  = ~(^parity_data);
        else 
            //even parity
            parity_bit = ^parity_data;
    end
    else begin
        parity_bit = 1'b0;
    end
end

//--------------------Counter Logic--------------------
always@(*) begin
    case(tlen)
        2'b00: comp_val = 4'd5;
        2'b01: comp_val = 4'd6;
        2'b10: comp_val = 4'd7;
        2'b11: comp_val = 4'd8;
        default: comp_val = 4'd8;
    endcase
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bit_cnt <= 0;
    end
    else if(count_clr && btick) begin
        bit_cnt <= 0;
    end
    else if(count_en && btick)   begin
        bit_cnt <= bit_cnt + 1;
    end
end

//---------------------State Machine--------------------


always@(*) begin
        case(state)
            IDLE: begin
                if(~fifo_nempty)
                   next_state = READ_FIFO1;
                else
                   next_state = state;                
            end
            READ_FIFO1: begin 
                   next_state = READ_FIFO2;
            end
            READ_FIFO2: begin 
                   next_state = START;
            end
            START: begin
                next_state = DATA;
            end
            DATA: begin
                if ((bit_cnt == (comp_val-1)) && parity_en)
                    next_state = PARITY;
                else if (bit_cnt == (comp_val-1) && ~parity_en)
                    next_state = STOP;
                else
                    next_state = state;
            end
            PARITY: begin
                next_state = STOP;
            end
            STOP: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;  
    end 
    else if(state == READ_FIFO1 || state == READ_FIFO2)
        state <= next_state;
    else if(btick) begin
        state <= next_state;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rd_en <= 1'b0;
    else if (state==IDLE && ~fifo_nempty && btick)
        rd_en <= 1'b1;
    else
        rd_en <= 1'b0;
end


always@(*)begin
    case(state)
        IDLE:       begin
            tx_out      = 1'b1;
            shift_en    = 1'b0;
            count_en    = 1'b0;
            count_clr   = 1'b0;
        end
        READ_FIFO1: begin
            tx_out      = 1'b1;
            shift_en    = 1'b0;
            count_en    = 1'b0;
            count_clr   = 1'b0;
        end        
        READ_FIFO2: begin
            tx_out      = 1'b1;
            shift_en    = 1'b0;
            count_en    = 1'b0;
            count_clr   = 1'b0;
 
        end
        START:      begin
            tx_out      = 1'b0;
            shift_en    = 1'b0;
            count_en    = 1'b0;
            count_clr   = 1'b0;
        end
        DATA:       begin
            tx_out      = tdata_reg[0];
            shift_en    = 1'b1;
            count_en    = 1'b1;
            count_clr   = 1'b0;
        end
        PARITY:     begin
            tx_out      = parity_bit;
            shift_en    = 1'b0;
            count_en    = 1'b0;
            count_clr   = 1'b0;   
        end
        STOP:       begin
            tx_out      = 1'b1;
            shift_en    = 1'b0;
            count_en    = 1'b0;
            count_clr   = 1'b1;
        end
        default:    begin
            tx_out      = 1'b1;
            shift_en    = 1'b0;
            count_en    = 1'b0;
            count_clr   = 1'b0;
        end
    endcase
    end
endmodule