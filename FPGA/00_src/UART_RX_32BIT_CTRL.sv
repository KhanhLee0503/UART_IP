module UART_RX_32BIT_CTRL (
    input  logic        I_CLK,
    input  logic        I_RESET_N,
    
    // Giao tiếp với UART_TOP
    input  logic        I_UART_RX_EMPTY, // FIFO có trống không?
    input  logic [7:0]  I_UART_RDATA,    // Dữ liệu 8-bit từ FWFT FIFO
    output logic        O_UART_RDEN,     // Cờ báo "Pop" dữ liệu
    
    // Giao tiếp với System (CPU hoặc Mạch xử lý phía sau)
    output logic [31:0] O_DATA_32,
    output logic        O_VALID_32      // Báo hiệu (pulse) đã gom đủ 32-bit hợp lệ
 
);

localparam IDLE_STATE       = 2'b00;
localparam PULL_FWFT_STATE  = 2'b01;
localparam CHECK_DONE_STATE = 2'b10;

//===========================================
//-----------Logic Declarations--------------
//===========================================
logic [31:0] shift_reg;
logic        shift_en;

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
    else if(shift_en)
        // Little-Endian: Nhét byte mới vào MSB [31:24], đẩy dần data cũ xuống LSB
        shift_reg <= {I_UART_RDATA, shift_reg[31:8]}; 
end

//====================================
//----------- Byte Counter -----------
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
        // Đứng chờ cho đến khi FWFT FIFO báo có data (!EMPTY)
        IDLE_STATE:       next_state = (!I_UART_RX_EMPTY) ? PULL_FWFT_STATE : current_state;
        
        // Trạng thái này chỉ tồn tại đúng 1 nhịp clock để rút data
        PULL_FWFT_STATE:  next_state = CHECK_DONE_STATE;
        
        // Luôn quay về IDLE để cho phép FWFT FIFO có 1 nhịp clock cập nhật lại cờ EMPTY
        CHECK_DONE_STATE: next_state = IDLE_STATE; 
        
        default:          next_state = 2'bxx;
    endcase
end

// Output Logic
always_comb begin
    casez(current_state)
        IDLE_STATE: begin
            shift_en        = 1'b0;
            byte_cnt_clr    = 1'b0;
            byte_cnt_en     = 1'b0;
            O_UART_RDEN     = 1'b0; // Tuyệt đối không bật RD_EN khi đang rảnh
            O_VALID_32      = 1'b0;
        end 
        
        PULL_FWFT_STATE: begin         
            shift_en        = 1'b1; // 1. Lệnh chốt (latch) dữ liệu đang có sẵn trên I_UART_RDATA
            byte_cnt_clr    = 1'b0;
            byte_cnt_en     = 1'b1; // Tăng bộ đếm byte
            O_UART_RDEN     = 1'b1; // 2. Kéo RD_EN = 1 để ra lệnh FWFT FIFO vứt byte này đi
            O_VALID_32      = 1'b0;
        end
        
        CHECK_DONE_STATE: begin
            shift_en        = 1'b0;
            byte_cnt_clr    = (byte_cnt_reg == 3'd4); // Xóa bộ đếm nếu đã thu đủ 4 byte
            byte_cnt_en     = 1'b0;
            O_UART_RDEN     = 1'b0; // Phải tắt RD_EN đi ngay lập tức
            O_VALID_32      = (byte_cnt_reg == 3'd4); // Bắn xung VALID báo cho hệ thống
        end
        
        default: begin
            shift_en        = 1'bx;
            byte_cnt_clr    = 1'bx;
            byte_cnt_en     = 1'bx;
            O_UART_RDEN     = 1'bx;
            O_VALID_32      = 1'bx;
        end
    endcase
end

// Ngõ ra O_DATA_32 luôn được nối cứng với shift_reg
assign O_DATA_32 = shift_reg;

endmodule: UART_RX_32BIT_CTRL