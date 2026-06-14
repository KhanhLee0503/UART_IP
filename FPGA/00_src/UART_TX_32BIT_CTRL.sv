module UART_TX_32BIT_CTRL (
    input  logic        I_CLK,
    input  logic        I_RESET_N,
    
    // Giao tiếp với Master (CPU hoặc Sensor)
    input  logic        I_START_32,
    input  logic [31:0] I_DATA_32,
    output logic        O_DONE_32,
    
    // Giao tiếp với UART_TOP
    output logic [7:0]  O_UART_WDATA,
    output logic        O_UART_WREN
);

localparam IDLE_STATE       = 2'b00;
localparam WRITE_BYTE_STATE = 2'b01;
localparam SHIFT_NEXT_STATE = 2'b10;

//===========================================
//-----------Logic Declarations--------------
//===========================================
logic [31:0] shift_reg;
logic        shift_en;
logic        shift_load;

logic [2:0]  byte_cnt_reg;
logic        byte_cnt_clr;
logic        byte_cnt_en;

logic [1:0]  current_state;
logic [1:0]  next_state;

//===========================================
//-----------Shift Register Logic------------
//===========================================
always_ff@(posedge I_CLK or negedge I_RESET_N) begin
    if(!I_RESET_N)
        shift_reg <= '0;
    else if(shift_load)
        shift_reg <= I_DATA_32;
    else if(shift_en)
        shift_reg <= shift_reg >> 8;
end

//====================================
//----------- byte counter -----------
//====================================
always_ff@(posedge I_CLK or negedge I_RESET_N) begin
    if(!I_RESET_N)
        byte_cnt_reg <= '0;
    else if(byte_cnt_clr)
        byte_cnt_reg <= '0;
    else if(byte_cnt_en)
        byte_cnt_reg <= byte_cnt_reg + 3'd1;
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
        IDLE_STATE:       next_state = I_START_32 ? WRITE_BYTE_STATE : current_state;
        WRITE_BYTE_STATE: next_state = SHIFT_NEXT_STATE;
        SHIFT_NEXT_STATE: next_state = (byte_cnt_reg == 3'd3) ? IDLE_STATE : WRITE_BYTE_STATE;
        default:          next_state = 2'bxx;
    endcase
end

// Output Logic
always_comb begin
    casez(current_state)
        IDLE_STATE: begin
            shift_en        = 1'b0;
            shift_load      = I_START_32; // Tự động load data khi có lệnh I_START_32
            byte_cnt_clr    = I_START_32; // Xóa bộ đếm khi bắt đầu
            byte_cnt_en     = 1'b0;
            O_UART_WREN     = 1'b0;
            O_DONE_32       = 1'b0;
        end 
        WRITE_BYTE_STATE: begin         
            shift_en        = 1'b0;
            shift_load      = 1'b0;
            byte_cnt_clr    = 1'b0;
            byte_cnt_en     = 1'b0;
            O_UART_WREN     = 1'b1;
            O_DONE_32       = 1'b0;
        end
        SHIFT_NEXT_STATE: begin
            shift_en        = 1'b1;
            shift_load      = 1'b0;
            byte_cnt_clr    = 1'b0;
            byte_cnt_en     = 1'b1;
            O_UART_WREN     = 1'b0;
            O_DONE_32       = (byte_cnt_reg == 3'd3); // Bật cờ DONE khi đếm đủ 4 byte
        end
        default: begin
            shift_en        = 1'bx;
            shift_load      = 1'bx;
            byte_cnt_clr    = 1'bx;
            byte_cnt_en     = 1'bx;
            O_UART_WREN     = 1'bx;
            O_DONE_32       = 1'bx;
        end
    endcase
end

assign O_UART_WDATA = shift_reg[7:0];

endmodule: UART_TX_32BIT_CTRL