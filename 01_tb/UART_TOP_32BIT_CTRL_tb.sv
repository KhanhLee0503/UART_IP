`timescale 1ns/1ps

module tb_UART_TOP_32BIT_CTRL();

    // ==========================================
    // 1. Khai báo Parameters & Signals
    // ==========================================
    localparam CLK_PERIOD = 20;      // 50MHz Clock -> Chu kỳ 20ns
    localparam BIT_PERIOD = 104167;  // Thời gian 1 bit ở Baudrate ~9600 (1/9615 Hz)

    logic        I_CLK;
    logic        I_RESET_N;
    logic [3:0]  I_BAUD_RATE;
    logic        I_BCLK_MODE;
    logic        I_CNT_EN;
    logic        I_CNT_LOAD;
    
    logic        I_WR_EN;
    logic [31:0] I_WDATA;
    logic        I_RX_IN;
    
    logic        O_TX_OUT;
    logic        O_VALID_32;
    logic [31:0] O_RDATA;

    // ==========================================
    // 2. Kết nối DUT (Device Under Test)
    // ==========================================
    UART_TOP_32BIT_CTRL dut (
        .I_CLK(I_CLK),
        .I_RESET_N(I_RESET_N),
        .I_BAUD_RATE(I_BAUD_RATE),
        .I_BCLK_MODE(I_BCLK_MODE),
        .I_CNT_EN(I_CNT_EN),
        .I_CNT_LOAD(I_CNT_LOAD),
        .I_WR_EN(I_WR_EN),
        .I_WDATA(I_WDATA),
        .I_RX_IN(I_RX_IN),
        .O_TX_OUT(O_TX_OUT),
        .O_VALID_32(O_VALID_32),
        .O_RDATA(O_RDATA)
    );

    // ==========================================
    // 3. Tạo xung Clock & Task Reset
    // ==========================================
    initial begin
        I_CLK = 0;
        forever #(CLK_PERIOD/2) I_CLK = ~I_CLK;
    end

    task automatic reset_system();
        I_RESET_N   = 0;
        I_WR_EN     = 0;
        I_WDATA     = 0;
        I_RX_IN     = 1; // Idle state của UART luôn là 1
        
        // Cấu hình Baud 9600
        I_BAUD_RATE = 4'h0; 
        I_BCLK_MODE = 0;    // Dùng hệ số x16
        I_CNT_EN    = 1;
        I_CNT_LOAD  = 0;
        
        #(CLK_PERIOD * 10);
        I_RESET_N = 1;
        #(CLK_PERIOD * 10);
    endtask

    // ==========================================
    // 4. Các Task Hỗ trợ (Driver & Monitor)
    // ==========================================
    
    // Task: Đóng giả thiết bị bên ngoài bơm tín hiệu Serial vào mạch (Test RX)
    task automatic send_serial_32bit(input [31:0] data);
        logic [7:0] byte_data;
        $display("[%0t] [TESTBENCH -> DUT] Sending serial data: 0x%08h", $time, data);
        
        // Truyền 4 byte (Little-Endian: Byte thấp truyền trước)
        for (int i = 0; i < 4; i++) begin
            byte_data = (data >> (i * 8)) & 8'hFF;
            
            I_RX_IN = 0; #(BIT_PERIOD); // Start bit
            
            // 8 Data bits (LSB first)
            for (int j = 0; j < 8; j++) begin
                I_RX_IN = byte_data[j];
                #(BIT_PERIOD);
            end
            
            I_RX_IN = 1; #(BIT_PERIOD); // Stop bit
        end
    endtask

    // Task: Đóng giả Máy đo Oscilloscope đọc tín hiệu từ chân O_TX_OUT (Test TX)
    task automatic receive_serial_32bit(output [31:0] data);
        logic [7:0] byte_data;
        data = 0;
        $display("[%0t] [DUT -> TESTBENCH] Waiting for signal on O_TX_OUT...", $time);
        
        // Chờ thu 4 byte
        for (int i = 0; i < 4; i++) begin
            wait(O_TX_OUT == 0); // Đợi sườn xuống của Start bit
            #(BIT_PERIOD / 2.0); // Dịch điểm lấy mẫu vào giữa bit để tránh nhiễu
            if (O_TX_OUT !== 0) $error("Capture wrong Start bit!");
            
            #(BIT_PERIOD);
            
            // Đọc 8 bit dữ liệu
            for (int j = 0; j < 8; j++) begin
                byte_data[j] = O_TX_OUT;
                #(BIT_PERIOD);
            end
            
            // Đọc Stop bit
            if (O_TX_OUT !== 1) $error("Capture wrong Stop bit!");
            
            // Ghép byte vừa thu được vào kết quả 32-bit
            data = data | (byte_data << (i * 8));
        end
    endtask

    // ==========================================
    // 5. Kịch bản Test Chính (Main Test)
    // ==========================================
    initial begin
        logic [31:0] captured_tx_data;

        $display("\n=======================================");
        $display("--- STARTING UART 32-BIT SIMULATION ---");
        $display("=======================================");

        reset_system();

        // ----------------------------------------------------
        // TESTCASE 1: Kiểm tra mạch PHÁT (TX Sanity)
        // ----------------------------------------------------
        $display("\n[TESTCASE 1] CHECKING 32-BIT TRANSMISSION");
        fork
            // Luồng 1 (CPU): Ghi dữ liệu 32-bit vào DUT
            begin
                @(posedge I_CLK);
                I_WDATA = 32'hDEADBEEF;
                I_WR_EN = 1;
                @(posedge I_CLK);
                I_WR_EN = 0;
            end
            
            // Luồng 2 (Máy đo): Chờ ở ngõ ra O_TX_OUT và gom bit
            begin
                receive_serial_32bit(captured_tx_data);
                if (captured_tx_data == 32'hDEADBEEF)
                    $display("   => TC1 PASSED! Correctly transmitted 0xDEADBEEF");
                else
                    $error("   => TC1 FAILED! Incorrect data received: %08h", captured_tx_data);
            end
        join

        #(BIT_PERIOD * 5); // Đợi một chút cho mạch xả hơi

        // ----------------------------------------------------
        // TESTCASE 2: Kiểm tra mạch NHẬN (RX Sanity)
        // ----------------------------------------------------
        $display("\n[TESTCASE 2] CHECKING 32-BIT RECEPTION");
        fork
            // Luồng 1 (Cảm biến): Bơm tín hiệu vật lý vào I_RX_IN
            begin
                send_serial_32bit(32'h12345678);
            end
            
            // Luồng 2 (CPU): Canh cờ O_VALID_32 của FSM báo hiệu
            begin
                wait(O_VALID_32 == 1);
                @(posedge I_CLK); // Bắt data ở sườn clock tiếp theo
                
                if (O_RDATA == 32'h12345678)
                    $display("   => TC2 PASSED! Correctly received 0x12345678 at O_RDATA");
                else
                    $error("   => TC2 FAILED! Incorrect data received: %08h", O_RDATA);
            end
        join

        $display("\n=======================================");
        $display("--- END OF SIMULATION ---");
        $display("=======================================");
        $finish;
    end

endmodule