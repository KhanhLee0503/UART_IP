# UART_IP
This is a personal project designing an UART Module and implementing it on DE-10 Lite FPGA

# Overview of the Design
## Signal Description
| Name         | Direction | Width | Description                                                  |
| ----------   | --------- | ----- | ------------------------------------------------------------ |
| I_CLK        | Input     |   1   |  UART's Clock source                                         |
| I_RESET_N    | Input     |   1   |  Reset signal                                                |
| I_BAUDRATE   | Input     |   4   |  Choose baudrate: 0 = 9600, 1 = 19200, 2 = 38400, 3 = 115200 |
| I_BCLK_MODE  | Input     |   1   |  Choose sampling mode: 0 = x16, 1 = x13                      |
| I_CNT_EN     | Input     |   1   |  Enable UART operation                                       |
| I_CNT_LOAD   | Input     |   1   |  Load divisor                                                |
| I_WR_EN      | Input     |   1   |  Write to FIFO enable                                        |
| I_RD_EN      | Input     |   1   |  Read from FIFO enable                                       |
| I_WDATA      | Input     |   8   |  Write data                                                  |
| I_RX_IN      | Input     |   1   |  Reception RX                                                |
| O_TX_OUT     | Output    |   1   |  Transmission TX                                             |
| O_PRDATA     | Output    |   16  |  Read data from FIFO                                         |

## Overview
- This UART design has 4 baudrate selection and 2 sampling modes, which can be configured by the input **I_BAUD_RATE** and **I_BCLK_MODE**.
- To start the UART's operation, set **I_CNT_EN** to 1.
- To start transmission, place the data you want to transmitt on the input **I_WDATA** and the set **I_WR_EN** to 1, this will save the data to the transmitting FIFO.
- The reception can happen at any time while **I_CNT_EN** = 1. The received data will be stored in receiving FIFO (FWFT).

## Special function
- There are two special modules will help this UART transmitt or receive 32-bit data instead of 8-bit data, which will reduce the workload of the user.
  
# Block Diagram
## TRANS_SHIFT_REG Logic
<img width="9000" height="7000" alt="image" src="https://github.com/user-attachments/assets/c4899efe-dd23-40ea-8b83-91c9ffe17b24" />
<img width="12000" height="7000" alt="image" src="https://github.com/user-attachments/assets/9a11620b-abff-4e81-a7dc-50497f4434ec" />

## RECEIVER_SHIFT_REG Logic
<img width="9000" height="7000" alt="image" src="https://github.com/user-attachments/assets/0dbbf0e8-af64-4c42-ab3e-1b17a223bfbd" />
<img width="12000" height="7000" alt="image" src="https://github.com/user-attachments/assets/ed482961-060b-4133-91ff-73d4db95eefd" />

## Synchronous FIFO Diagram
<img width="9000" height="7000" alt="image" src="https://github.com/user-attachments/assets/3adba8b9-d281-4e1e-ba44-8b1df0d4cf36" />


## BAUD_GEN Diagram
<img width="9000" height="7000" alt="image" src="https://github.com/user-attachments/assets/7a9b3bc6-4f2b-4161-abc9-2aae4b23d69a" />

## Implement on FPGA (DE-10 Lite)
https://github.com/user-attachments/assets/f104c2a9-9b0e-42f0-8d22-30870cb2cfda

