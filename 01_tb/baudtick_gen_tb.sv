`timescale 1ns/1ns
module baudtick_gen_tb();
reg clk;
reg rst_n;
reg bclk_mode;
wire btick;
wire btick_16;

baudtick_gen DUT(.*);

initial begin
    clk = 0;
    forever begin
        #18.5 clk = ~clk;
    end
end

initial begin
    bclk_mode = 0;
    rst_n = 0;
    #50
    rst_n = 1;

    #1000_000
    $finish;
end
endmodule
