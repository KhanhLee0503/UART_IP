module baudtick_gen(
    input wire clk,
    input wire rst_n,
    input wire bclk_mode, // 0: x16 baudrate speed | 1: x13 baudrate speed
    output reg btick,     // Baudrate 
    output reg btick_16   // Baudrate x16
);

parameter SYS_CLK = 27_000_000;
parameter BAUDRATE = 9600;
parameter MODE = 16;

parameter DIVISOR = SYS_CLK/(BAUDRATE*MODE);

//--------------------Internal Signals--------------------
//***Counter Signals***
wire [11:0] count_value;
wire [7:0] count_value_16;
wire equal;
wire equal_16;

counter #(.COUNT_WIDTH(12)) counter (
    .clk(clk),
    .rst_n(rst_n),
    .count_clr(equal),
    .count_value(count_value)
);

assign equal = (count_value == (DIVISOR*MODE)-1);

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        btick <= 1'b0;
    else if(equal)
        btick <= 1;
    else
        btick <= 0;
end


counter counter_x16 (
    .clk(clk),
    .rst_n(rst_n),
    .count_clr(equal_16),
    .count_value(count_value_16)
);

assign equal_16 = (count_value_16 == DIVISOR-1);

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        btick_16 <= 1'b0;
    else if(equal_16)
        btick_16 <= 1;
    else
        btick_16 <= 0;
end



endmodule


module counter #(parameter COUNT_WIDTH = 8)
(
    input wire clk,
    input wire rst_n,
    input wire count_clr,

    output [COUNT_WIDTH-1:0] count_value
);
reg [COUNT_WIDTH-1:0] count_reg;
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_reg <= {COUNT_WIDTH{1'd0}};
    end
    else if(count_clr) begin
        count_reg <= {COUNT_WIDTH{1'd0}};
    end
    else begin
       count_reg <= count_reg + 1'd1; 
    end
end
assign count_value = count_reg;
endmodule
