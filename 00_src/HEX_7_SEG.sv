module HEX_7_SEG(
    input [3:0] I_HEX_IN,
    output logic [7:0] SEG_OUT 
);

always@(*) begin
    case(I_HEX_IN)
        // Cấu trúc SEG_OUT: {dp, 6, 5, 4, 3, 2, 1, 0}
        // 0: Sáng, 1: Tắt (Common Anode)
        4'h0: SEG_OUT = 8'b1100_0000; // 0
        4'h1: SEG_OUT = 8'b1111_1001; // 1
        4'h2: SEG_OUT = 8'b1010_0100; // 2
        4'h3: SEG_OUT = 8'b1011_0000; // 3
        4'h4: SEG_OUT = 8'b1001_1001; // 4
        4'h5: SEG_OUT = 8'b1001_0010; // 5
        4'h6: SEG_OUT = 8'b1000_0010; // 6
        4'h7: SEG_OUT = 8'b1111_1000; // 7
        4'h8: SEG_OUT = 8'b1000_0000; // 8
        4'h9: SEG_OUT = 8'b1001_0000; // 9
        4'hA: SEG_OUT = 8'b1000_1000; // A
        4'hB: SEG_OUT = 8'b1000_0011; // B
        4'hC: SEG_OUT = 8'b1100_0110; // C
        4'hD: SEG_OUT = 8'b1010_0001; // D
        4'hE: SEG_OUT = 8'b1000_0110; // E
        4'hF: SEG_OUT = 8'b1000_1110; // F
        default: SEG_OUT = 8'b1111_1111;
    endcase
end

endmodule