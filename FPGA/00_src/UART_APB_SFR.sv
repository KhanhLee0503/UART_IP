`timescale 1ns/1ps

// =====================================================================================
// Module: UART_APB_SFR
// Description: APB Slave Function Registers for UART configuration and FIFO control.
// =====================================================================================
module UART_APB_SFR
(
    // APB Bus Interface
    input        I_PCLK,       // APB Clock
    input        I_PRESET_N,   // Async Reset (Active Low)
    input        I_PENABLE,    // APB Enable Phase
    input        I_PSEL,       // APB Slave Select
    input        I_PWRITE,     // APB Direction (1: Write, 0: Read)
    input [3:0]  I_PSTRB,      // APB Write Strobes
    input [11:0] I_PADDR,      // APB Address Bus
    input [31:0] I_PWDATA,     // APB Write Data Bus

    // Async Status/Data from UART Core
    input        I_PARITY_ERR, // Parity Error flag
    input        I_RX_FULL,    // RX FIFO Full flag
    input        I_TX_EMPTY,   // TX FIFO Empty flag
    input [7:0]  I_RX_DATA,    // Direct data from RX FIFO (FWFT mode)

    // Controls to UART Core & Baud Rate Generator
    output logic        O_UART_EN,   // UART Enable
    output logic        O_UART_LOAD, // Configuration Load signal
    output logic        O_BCLK_MODE, // Baud Clock Mode (0: x16, 1: x13)
    output logic [3:0]  O_BAUD_RATE, // Baud Rate Selector
    output logic [7:0]  O_TX_DATA,   // Data to TX FIFO
    output logic        O_RD_EN,     // RX FIFO Read Pulse (Active for 1 cycle)
    output logic        O_WR_EN,     // TX FIFO Write Pulse (Active for 1 cycle)

    // APB Slave Outputs
    output logic [31:0] O_PRDATA,    // APB Read Data Bus
    output logic        O_PREADY,    // APB Ready signal
    output logic        O_PSLVERR    // APB Transfer Error
);

    // Register Map Offsets
    localparam ADDR_CTRL_REG    = 12'h000;
    localparam ADDR_TX_DATA_REG = 12'h004;
    localparam ADDR_RX_DATA_REG = 12'h008;
    localparam ADDR_STATUS_REG  = 12'h00C;

    // Internal Registers
    logic [6:0] r_ctrl_reg;    
    logic [7:0] r_tx_data_reg; 
    logic [2:0] r_status_reg;  

    // APB Protocol Controls
    logic access_en;           
    logic access_write;        
    logic access_read;         

    // Address Decoding Signals
    logic control_reg_en;      
    logic tx_data_reg_en;      
    logic rx_data_reg_en;      
    logic status_reg_en;       
    logic addr_valid;          

    // Clock Domain Crossing (CDC) Synchronized Signals
    logic parity_err_sync;
    logic rx_full_sync;
    logic tx_empty_sync;

    // 2-FF CDC Synchronizers
    SYNC_NFF parity_err_sync_nff(
        .I_CLK(I_PCLK), .I_RESET_N(I_PRESET_N), .I_ASYNC_IN(I_PARITY_ERR), .O_SYNC_OUT(parity_err_sync)
    );
    SYNC_NFF rx_full_sync_nff(
        .I_CLK(I_PCLK), .I_RESET_N(I_PRESET_N), .I_ASYNC_IN(I_RX_FULL), .O_SYNC_OUT(rx_full_sync)
    );
    SYNC_NFF tx_empty_sync_nff(
        .I_CLK(I_PCLK), .I_RESET_N(I_PRESET_N), .I_ASYNC_IN(I_TX_EMPTY), .O_SYNC_OUT(tx_empty_sync)
    );

    // Address Decoder Logic
    always_comb begin
        control_reg_en = 1'b0;
        tx_data_reg_en = 1'b0;
        rx_data_reg_en = 1'b0;
        status_reg_en  = 1'b0;
        
        casez(I_PADDR)
            ADDR_CTRL_REG:    control_reg_en = 1'b1;
            ADDR_TX_DATA_REG: tx_data_reg_en = 1'b1;
            ADDR_RX_DATA_REG: rx_data_reg_en = 1'b1;
            ADDR_STATUS_REG:  status_reg_en  = 1'b1;
            default: begin
                control_reg_en = 1'b0;
                tx_data_reg_en = 1'b0;
                rx_data_reg_en = 1'b0;
                status_reg_en  = 1'b0;
            end
        endcase
    end

    // Register Write Logic
    always_ff @(posedge I_PCLK or negedge I_PRESET_N) begin
        if (!I_PRESET_N) begin
            r_ctrl_reg    <= 1'b0;
            r_tx_data_reg <= 1'b0;
            r_status_reg  <= 1'b0;
        end else begin
            // Update status bits from CDC outputs
            r_status_reg[0] <= parity_err_sync;
            r_status_reg[1] <= rx_full_sync;
            r_status_reg[2] <= tx_empty_sync;

            // Write to Control Register
            if (control_reg_en && access_write && I_PSTRB[0]) begin
                r_ctrl_reg <= I_PWDATA[6:0];
            end
            
            // Write to TX Data Register
            if (tx_data_reg_en && access_write && I_PSTRB[0]) begin
                r_tx_data_reg <= I_PWDATA[7:0];
            end
        end
    end

    // Register Read Multiplexer (Direct bypass for FWFT RX FIFO)
    always_comb begin
        if(access_read) begin
            casez(I_PADDR)
                ADDR_RX_DATA_REG: O_PRDATA = {24'b0, I_RX_DATA}; 
                ADDR_STATUS_REG:  O_PRDATA = {29'b0, r_status_reg};
                ADDR_TX_DATA_REG: O_PRDATA = {24'b0, r_tx_data_reg};
                ADDR_CTRL_REG:    O_PRDATA = {25'b0, r_ctrl_reg};
                default:          O_PRDATA = 32'b0;
            endcase
        end
        else 
            O_PRDATA = 32'b0;
    end

    // APB Control and Error Logic
    assign addr_valid   = (control_reg_en | tx_data_reg_en | rx_data_reg_en | status_reg_en);
    assign access_en    = I_PSEL & I_PENABLE; 
    assign access_write = access_en & I_PWRITE;  
    assign access_read  = access_en & ~I_PWRITE; 

    // PSLVERR: Triggered on illegal write to RO registers or invalid address
    assign O_PSLVERR = (access_write & (rx_data_reg_en | status_reg_en)) | 
                       (access_en & ~addr_valid);     

    // Zero-Wait-State operation
    assign O_PREADY = access_en;

    // Output Field Mapping
    assign O_UART_EN   = r_ctrl_reg[6];   
    assign O_UART_LOAD = r_ctrl_reg[5];   
    assign O_BCLK_MODE = r_ctrl_reg[4];   
    assign O_BAUD_RATE = r_ctrl_reg[3:0]; 
    assign O_TX_DATA   = r_tx_data_reg;   

    // FIFO Handshake Pulse Generation (Valid only during APB Access Phase)
    assign O_RD_EN = rx_data_reg_en & access_read; 
    assign O_WR_EN = tx_data_reg_en & access_write; 

endmodule: UART_APB_SFR


// =====================================================================================
// Module: SYNC_NFF
// Description: Standard 2-Flip-Flop Synchronizer for Clock Domain Crossing (CDC).
// =====================================================================================
module SYNC_NFF (
    input  logic I_CLK,       // Destination domain clock
    input  logic I_RESET_N,   // Asynchronous reset
    input  logic I_ASYNC_IN,  // Asynchronous input signal
    output logic O_SYNC_OUT   // Synchronized output signal
);
    logic [1:0] sync_reg;

    always_ff@(posedge I_CLK or negedge I_RESET_N) begin
        if(!I_RESET_N)
            sync_reg <= 2'b00;
        else
            sync_reg <= {sync_reg[0], I_ASYNC_IN}; // Shift data into 2-FF pipeline
    end

    assign O_SYNC_OUT = sync_reg[1];

endmodule: SYNC_NFF