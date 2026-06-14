`timescale 1ns/1ps

module tb_uart_top;

    // =========================================================================
    // 1. KHAI BÁO TÍN HIỆU KẾT NỐI DUT
    // =========================================================================
    logic        clk;
    logic        rst_n;
    logic [3:0]  baud_rate;
    logic        bclk_mode;  
    logic        cnt_en;
    logic        cnt_load;   
    logic        wr_en;
    logic        rd_en;       
    logic [7:0]  wdata;
    logic        rx_in;
    logic        tx_out;
    logic [15:0] rdata_7seg; 

    // Các biến đếm và hàng đợi cho Scoreboard
    bit [7:0] expected_queue[$];
    int match_count = 0;
    int mismatch_count = 0;

    // =========================================================================
    // 2. TẠO XUNG NHỊP & KẾT NỐI LOOPBACK
    // =========================================================================
    always #10 clk = ~clk; // 50MHz Clock

    // DIGITAL LOOPBACK: Đầu ra nối thẳng đầu vào
    assign rx_in = tx_out;

    // Khởi tạo DUT
    UART_TOP dut (
        .I_CLK(clk),                 
        .I_RESET_N(rst_n),           
        .I_BAUD_RATE(baud_rate),    
        .I_BCLK_MODE(bclk_mode),    
        .I_CNT_EN(cnt_en),           
        .I_CNT_LOAD(cnt_load),      
        .I_WR_EN(wr_en),             
        .I_RD_EN(rd_en),             
        .I_WDATA(wdata),             
        .I_RX_IN(rx_in),            
        .O_TX_OUT(tx_out),           
        .O_RDATA(rdata_7seg)         
    );

    // Task nạp dữ liệu vào TX FIFO
    task write_tx_fifo(input bit [7:0] data);
        @(posedge clk);
        #1; // THÊM TẠI ĐÂY: Delay 1ns sau posedge clk để drive wr_en an toàn
        wr_en = 1;
        wdata = data;
        expected_queue.push_back(data); 
        @(posedge clk);
        #1; // THÊM TẠI ĐÂY: Delay 1ns sau posedge clk để hạ wr_en an toàn
        wr_en = 0;
    endtask

    // =========================================================================
    // 3. KHỐI ĐIỀU KHIỂN CHÍNH
    // =========================================================================
    initial begin
        // Khởi tạo trạng thái ban đầu
        clk       = 0;
        rst_n     = 0;
        baud_rate = 4'd0; 
        bclk_mode = 0;
        cnt_en    = 1;
        cnt_load  = 1;
        wr_en     = 0;
        rd_en     = 0;
        wdata     = 8'h00;

        // Giải phóng Reset
        #40 rst_n = 1;
        repeat(5) @(posedge clk);
        #1; // THÊM TẠI ĐÂY: Hoãn 1ns trước khi thay đổi trạng thái cnt_load
        cnt_load = 0;
        @(posedge clk);
        #1; // THÊM TẠI ĐÂY

        $display("\n=== BAT DAU MO PHONG 100 TESTCASES (FORK-JOIN MODE) ===");

        fork
            // LUỒNG CHÍNH 1: Chứa cả TX và RX chạy song song với nhau
            begin
                fork
                    // [THREAD 1.1]: PHÁT DỮ LIỆU (TX)
                    begin
                        for (int i = 0; i < 100; i++) begin
                            bit [7:0] rand_data;
                            rand_data = $urandom_range(0, 255);
                            
                            write_tx_fifo(rand_data);
                            
                            repeat(52500) @(posedge clk);
                        end
                        $display("[Status] Luong TX da phat xong toan bo 100 byte.");
                    end

                    // [THREAD 1.2]: THU DỮ LIỆU & CHECKER (RX)
                    begin
                        for (int i = 0; i < 100; i++) begin
                            // Thám thính tín hiệu write nội bộ của khối Receiver
                            @(posedge dut.rsr_write);
                            @(posedge clk); 
                            #1; // THÊM TẠI ĐÂY: Chờ dữ liệu ra từ FIFO ổn định hoàn toàn rồi mới chấm điểm
                           
                            // Tiến hành so sánh kết quả trực tiếp (Immediate Assertion)
                            assert_data_match: assert (dut.rdata_out === expected_queue[0]) begin
                                match_count++;
                                $display("[PASS] Testcase %0d: Khop du lieu! Got 0x%02h", (match_count + mismatch_count), dut.rdata_out);
                            end else begin
                                mismatch_count++;
                                $error("[FAIL] Testcase %0d: Sai du lieu! Expected 0x%02h, Got 0x%02h", 
                                       (match_count + mismatch_count), expected_queue[0], dut.rdata_out);
                            end
                            
                            void'(expected_queue.pop_front());
                            @(posedge clk);
                            #1; // THÊM TẠI ĐÂY: Hoãn 1ns trước khi bật lệnh đọc
                            rd_en = 1;
                            @(posedge clk);
                            #1; // THÊM TẠI ĐÂY: Hoãn 1ns trước khi tắt lệnh đọc
                            rd_en = 0;
                        end
                        $display("[Status] Luong RX da thu va kiem tra xong toan bo 100 byte.");
                    end
                join 
            end

            // LUỒNG CHÍNH 2: WATCHDOG TIMEOUT
            begin
                #200ms;
                assert_watchdog_fail: assert (0) else $fatal("[FATAL TIMEOUT] Mo phong bi treo!");
            end
        join_any 

        // =========================================================================
        // 4. IN BÁO CÁO KẾT QUẢ CUỐI CÙNG
        // =========================================================================
        $display("\n==================================================");
        $display("             VERIFICATION REPORT                  ");
        $display("==================================================");
        $display(" Total Testcases Executed : %0d", (match_count + mismatch_count));
        $display(" Matches (Passed)         : %0d", match_count);
        $display(" Mismatches (Failed)      : %0d", mismatch_count);
        $display("--------------------------------------------------");
        if(mismatch_count == 0 && match_count == 100)
            $display(" Final Status             : SUCCESS (ALL PASSED)");
        else
            $display(" Final Status             : FAILED");
        $display("==================================================\n");

        $finish;
    end

    // =========================================================================
    // 5. CÁC CONCURRENT ASSERTIONS (KIỂM TRA PROTOCOL NGOẠI VI)
    // =========================================================================
    property p_tx_idle_on_reset;
        @(posedge clk) (!rst_n) |-> (tx_out == 1'b1);
    endproperty
    assert_tx_idle_on_reset: assert property (p_tx_idle_on_reset) else $error("[SVA] O_TX_OUT khong bang 1 trong luc Reset!");

    property p_no_rw_on_reset;
        @(posedge clk) (!rst_n) |-> (!wr_en && !rd_en);
    endproperty
    assert_no_rw_on_reset: assert property (p_no_rw_on_reset) else $error("[SVA] Phat hien WR_EN/RD_EN trong luc Reset!");

endmodule: tb_uart_top