module RSR_reg(
    input wire clk,
    input wire rst_n,
    input wire btick_16,
    input wire btick,
    
    input wire [1:0] tlen,
    input wire fifo_nfull,
    input wire parity_en,
    input wire parity_type, //0-even, 1-odd
    input wire sample_type,
    
    input wire rx_in,

    output reg wr_en,
    output reg [7:0] rdata,
    
    output reg frame_err,
    output reg parity_err
);
parameter IDLE       = 0;
parameter START      = 1;
parameter DATA       = 2;
parameter PARITY     = 3;
parameter STOP       = 4;
parameter WRITE_FIFO = 5;

//--------------------Internal Signals--------------------
//***Sampling Counter Signals***
reg [3:0] sample_cnt;
reg sample_en;  
reg sample_clr;
wire sample_start;
wire sample_data;


//***Parity Logic***
reg received_parity_bit;
reg transmit_parity_bit;

//***Data Shift Register***
reg [7:0] rdata_reg;

//***State Machine***
reg [2:0] state;
reg [2:0] next_state;
reg err_flag;

//***Bit Counter Signals***
reg [3:0] bit_cnt;
reg [3:0] comp_val;
reg count_en;
reg count_clr;
wire count_done;

//-------------------Data Shift Register Logic-------------------
always@(posedge btick_16 or negedge rst_n) begin
    if (!rst_n) begin
        rdata_reg <= 0;
    end else if (sample_data && state == DATA) begin
        rdata_reg <= {rx_in, rdata_reg[7:1]};
    end
end

always@(posedge btick_16 or negedge rst_n) begin
    if (!rst_n) begin
        rdata <= 0;
    end else if (state == STOP) begin
        rdata <= rdata_reg >> (8 - comp_val);
    end
end

//-------------------Sampling Counter Logic-------------------

always@(posedge btick_16 or negedge rst_n) begin
    if(!rst_n) begin
        sample_cnt <= 4'b0;
    end
    else if(sample_clr) begin
        sample_cnt <= 4'b0;
    end 
    else if(sample_en) begin
        sample_cnt <= sample_cnt + 1;
   end
end

assign sample_start  = (sample_type) ? (sample_cnt == 4'd5) : (sample_cnt == 4'd7);
assign sample_data   = (sample_type) ? (sample_cnt == 4'd12) : (sample_cnt == 4'd15);
assign sample_clr    = (sample_start && state == START) || sample_data;


//---------Parity Logic--------------------
always@(posedge btick_16 or negedge rst_n) begin    
    if(!rst_n) begin
        transmit_parity_bit <= 0;
    end else if (sample_data && state == PARITY) begin
        transmit_parity_bit <= rx_in;
    end
end


//------------------Counter Enable Logic-----------------
always@(*) begin
    case(tlen)
        2'b00: comp_val = 4'd5;
        2'b01: comp_val = 4'd6;
        2'b10: comp_val = 4'd7;
        2'b11: comp_val = 4'd8;
        default: comp_val = 4'd8;
    endcase
end

always@(posedge sample_data or negedge rst_n) begin
    if (!rst_n) begin
        bit_cnt <= 0;
    end
    else if(count_clr) begin
        bit_cnt <= 0;
    end
    else if(count_en)   begin
        bit_cnt <= bit_cnt + 1;
    end
end

assign count_done = (bit_cnt == comp_val);

//---------------------State Machine--------------------


always @(posedge btick_16 or negedge rst_n) begin
    if (!rst_n) begin
        frame_err <= 1'b0;
    end else if(err_flag) begin
        frame_err <= 1'b1;
    end
end

always@(*) begin
        case(state)
            IDLE: begin
                if(fifo_nfull)
                    next_state = state;
                else if (rx_in == 1'b0)
                    next_state = START;
                else
                    next_state = state;                
            end
            START: begin
                if(sample_start && rx_in == 1'b0) begin
                  next_state    = DATA;
                end
                else if (sample_start && rx_in == 1'b1) begin
                  next_state    = IDLE;
                end
                else begin
                  next_state    = state;
                end
            end
            DATA: begin
                if (count_done && sample_data && parity_en)
                    next_state = PARITY;
                else if (count_done && sample_data && ~parity_en)
                    next_state = STOP;
                else
                    next_state = state;
            end
            PARITY: begin
                if(sample_data)
                    next_state = STOP;
                else
                    next_state = state;
            end
            STOP: begin
                if(sample_data && rx_in == 1'b1) begin
                    next_state  = WRITE_FIFO;
                end
                else if (sample_data && rx_in == 1'b0) begin
                    next_state  = IDLE;
                end  
                else 
                    next_state  = state;
            end
            WRITE_FIFO: begin
                next_state = IDLE;
					 end
            default: begin
                    next_state   = IDLE;
            end
        endcase
    end

always@(posedge btick_16 or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end 
    else begin
        state <= next_state;
    end
end

reg state_written;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wr_en <= 0;
        state_written <= 0;
    end
    else begin
        state_written <= (state == WRITE_FIFO);

	    if ((state == WRITE_FIFO) && !state_written)
            wr_en <= 1;
		else
            wr_en <= 0;
	 end
end

always@(*) begin         
        sample_en   = 1'b0;
        count_en    = 1'b0;
        count_clr   = 1'b1;
        parity_err  = 1'b0;
		received_parity_bit = 0;
		err_flag    = 1'b0;
    case(state)
        
        IDLE:       begin
            sample_en   = 1'b0;
            count_en    = 1'b0;
            count_clr   = 1'b1;
			parity_err  = 1'b0;
			received_parity_bit = 0;
			err_flag    = 1'b0;
        end

        START:      begin
            sample_en   = 1'b1;
            count_en    = 1'b0;
            count_clr   = 1'b0;
			parity_err  = 1'b0;
            received_parity_bit = 0;
				
			if (sample_start && rx_in == 1'b1)
				err_flag = 1'b1;
			else	
				err_flag = 1'b0;
		  end

        DATA:       begin
            sample_en   = 1'b1;
            count_en    = 1'b1;
            count_clr   = 1'b0;
			parity_err  = 1'b0;
			received_parity_bit = 0;
			err_flag    = 1'b0;
        end

        PARITY:     begin
            sample_en   = 1'b1;
            count_en    = 1'b0;
            count_clr   = 1'b1;
			parity_err  = 1'b0;
            if(parity_en) begin
                if(parity_type)
                    //odd parity
                    received_parity_bit = ~(^rdata_reg >> (8 - comp_val));
                else 
                    //even parity
                    received_parity_bit = ^(rdata_reg >> (8 - comp_val));
            end
				else
					received_parity_bit = 0;
        end
        
		WRITE_FIFO: begin
			sample_en   = 1'b1;
            count_en    = 1'b0;
            count_clr   = 1'b1;
			parity_err  = 1'b0;
			received_parity_bit = 0;
			err_flag    = 1'b0;
		  end
		  
        STOP:       begin
            sample_en   = 1'b1;
            count_en    = 1'b0;
            count_clr   = 1'b1;
			received_parity_bit = 0;
            parity_err  = received_parity_bit ^ transmit_parity_bit;
		
        	if (sample_data && rx_in == 1'b0)
				err_flag = 1'b1;
			else 
				err_flag = 1'b0;
        end
		  
        default:    begin
			received_parity_bit = 0;
            sample_en   = 1'b0;
            count_en    = 1'b0;
            count_clr   = 1'b1;
            parity_err  = 1'b0;
			err_flag    = 1'b0;
        end
    endcase
end
endmodule